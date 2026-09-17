import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final StatsRepository statsRepository;
  final GameRepository gameRepository;
  final AudioService audio;
  final PremiumService premium;
  final AdsService ads;
  final ProgressRepository progressRepository;
  final GameCenterService gameCenter;

  /// Режим партии; у daily очередь и заказы идут из seed по дате.
  final GameMode mode;
  final int _dailySeed;
  final Random _random;

  /// Таймер режима «На время»: тикает раз в секунду, только пока партия
  /// идёт; ноль — проигрыш «время вышло».
  Timer? _clock;

  /// Заказы: генератор (с seed — для ежедневного вызова), трекер
  /// прогресса, следующий id и уровень игрока (заказов выполнено всего).
  final MissionGenerator _missions;
  final MissionTracker _tracker = MissionTracker();
  int _nextMissionId = 1;
  int _missionLevel = 0;
  ProgressModel _progress = const ProgressModel.empty();

  /// Первый бросаемый тир (пул — он и следующие [dropWeights.length] - 1).
  static const BallTier firstDropTier = BallTier.t1;

  /// Веса выпадения тиров начиная с [firstDropTier] (взвешено к младшим).
  static const List<int> dropWeights = <int>[5, 4, 3, 2, 1];

  /// Статистика текущей партии уже записана в репозиторий.
  bool _runSaved = false;

  /// Партия продолжена после проигрыша: следующий проигрыш не считает
  /// игру второй раз, а слияния пишутся дельтой от [_savedMerges].
  bool _continued = false;
  int _savedMerges = 0;

  /// Рекорд до начала партии — с ним сравнивается счёт для «НОВЫЙ РЕКОРД»
  /// (сам `bestScore` в состоянии растёт вместе со счётом по ходу партии).
  int _startBest = 0;

  /// [resumeFrom] — сохранённая партия: счёт и очередь берутся из неё, игра
  /// открывается в паузе, шары восстанавливает движок.
  GameCubit({
    required this.statsRepository,
    required this.gameRepository,
    required this.audio,
    required this.premium,
    required this.ads,
    required this.progressRepository,
    required this.gameCenter,
    this.mode = GameMode.classic,
    GameSnapshot? resumeFrom,
    Random? missionRandom,
    DateTime? now,
  })  : _dailySeed = dailySeed(now),
        _random = mode == GameMode.daily ? Random(dailySeed(now)) : Random(),
        _missions = MissionGenerator(
          missionRandom ??
              (mode == GameMode.daily
                  ? Random(dailySeed(now) * 31 + 7)
                  : Random()),
        ),
        super(
          resumeFrom == null
              ? GameState(
                  score: 0,
                  bestScore: 0,
                  status: GameStatus.playing,
                  current: firstDropTier,
                  next: firstDropTier,
                  mode: mode,
                  secondsLeft:
                      mode == GameMode.timed ? GameRules.timedSeconds : null,
                )
              : GameState(
                  score: resumeFrom.score,
                  bestScore: resumeFrom.score,
                  status: GameStatus.paused,
                  current: resumeFrom.current,
                  next: resumeFrom.next,
                  merges: resumeFrom.merges,
                  bestTier: resumeFrom.bestTier,
                  shakes: resumeFrom.shakes,
                  bombs: resumeFrom.bombs,
                  upgrades: resumeFrom.upgrades,
                  continues: resumeFrom.continues,
                  shakeRefills: resumeFrom.shakeRefills,
                  bombRefills: resumeFrom.bombRefills,
                  upgradeRefills: resumeFrom.upgradeRefills,
                  missions: resumeFrom.missions,
                ),
        ) {
    if (resumeFrom != null && resumeFrom.missions.isNotEmpty) {
      _nextMissionId =
          resumeFrom.missions.map((Mission m) => m.id).reduce(max) + 1;
    }
    _init(resume: resumeFrom != null);
    if (mode == GameMode.timed) {
      _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  /// Онбординг закрыт («Играть!» или «Пропустить») — больше не показываем.
  Future<void> finishOnboarding() async {
    if (!state.onboardingOpen) return;
    _safeEmit(state.copyWith(onboardingOpen: false));
    _progress = _progress.copyWith(onboardingDone: true);
    await progressRepository.saveProgress(_progress);
  }

  /// Секунда таймера «На время» (публичный для тестов).
  @visibleForTesting
  void tick() => _tick();

  void _tick() {
    final int? left = state.secondsLeft;
    if (left == null ||
        state.status != GameStatus.playing ||
        state.adBusy ||
        state.onboardingOpen) {
      return;
    }
    if (left <= 1) {
      _safeEmit(state.copyWith(secondsLeft: 0));
      unawaited(gameOver());
      return;
    }
    _safeEmit(state.copyWith(secondsLeft: left - 1));
  }

  /// Рекорд текущего режима в статистике.
  int _bestOf(GameStatsModel stats) => switch (mode) {
        GameMode.classic => stats.bestScore,
        GameMode.timed => stats.bestTimed,
        GameMode.daily => stats.bestDaily,
      };

  GameStatsModel _withBest(GameStatsModel stats, int score) => switch (mode) {
        GameMode.classic =>
          stats.copyWith(bestScore: max(stats.bestScore, score)),
        GameMode.timed =>
          stats.copyWith(bestTimed: max(stats.bestTimed, score)),
        GameMode.daily =>
          stats.copyWith(bestDaily: max(stats.bestDaily, score)),
      };

  Future<void> _init({required bool resume}) async {
    final GameStatsModel stats = await statsRepository.getStats();
    _progress = await progressRepository.getProgress();
    _missionLevel = _progress.missionsDone;
    if (isClosed) return;
    // Новая партия (или снимок без заказов — до 1.1) получает три заказа.
    if (state.missions.isEmpty) {
      _safeEmit(state.copyWith(missions: _dealMissions()));
    }
    // Первый запуск — «как играть» поверх новой партии.
    if (!resume && !_progress.onboardingDone) {
      _safeEmit(state.copyWith(onboardingOpen: true));
    }
    _startBest = _bestOf(stats);
    _safeEmit(state.copyWith(
      bestScore: max(_bestOf(stats), state.score),
      current: resume ? null : _rollTier(),
      next: resume ? null : _rollTier(),
    ));
  }

  void _safeEmit(GameState next) {
    if (isClosed) return;
    emit(next);
  }

  /// Случайный тир из [firstDropTier] и следующих [dropWeights.length] - 1.
  BallTier _rollTier() {
    final int total = dropWeights.fold(0, (int a, int b) => a + b);
    int roll = _random.nextInt(total);
    for (int i = 0; i < dropWeights.length; i++) {
      roll -= dropWeights[i];
      if (roll < 0) return BallTier.values[firstDropTier.index + i];
    }
    return firstDropTier;
  }

  /// Движок сообщает о слиянии двух шаров тира [tier].
  void onMerge(BallTier tier) {
    audio.merge(tier);
    // Джекпот t11+t11 шара не даёт — самым крупным остаётся t11.
    final BallTier produced = tier.next ?? tier;
    final int score = state.score + tier.mergeScore;
    // Рекорд обновляется и сохраняется сразу: HUD и меню показывают его
    // без ожидания конца партии (и он не теряется, если приложение убьют).
    final bool newBest = score > state.bestScore;
    final GameState next = state.copyWith(
      score: score,
      bestScore: newBest ? score : null,
      merges: state.merges + 1,
      bestTier: _maxTier(state.bestTier, produced),
    );
    _safeEmit(_withMissionEvent(
      next,
      MergeEvent(produced: tier.next, score: score),
    ));
    if (newBest) unawaited(_persistBest(score));
    unawaited(gameCenter.unlock(<GameAchievement>[
      ...GameAchievement.forFruit(produced),
      ...GameAchievement.forScore(state.score),
    ]));
  }

  /// Фрукт лёг выше линии проигрыша (движок зовёт при первом касании).
  void onLineTouched() {
    _safeEmit(_withMissionEvent(state, const LineTouchEvent()));
  }

  // --- Заказы ----------------------------------------------------------------

  List<Mission> _dealMissions() {
    final List<Mission> dealt =
        _missions.initial(_missionLevel, firstId: _nextMissionId);
    _nextMissionId += dealt.length;
    return dealt;
  }

  /// Прогоняет событие через трекер: выполненные заказы дают награду
  /// (заряд бонуса, очки, звезда — звёзды и счётчик сразу в прогресс),
  /// выполненные и проваленные заменяются новыми.
  GameState _withMissionEvent(GameState base, MissionEvent event) {
    if (base.missions.isEmpty) return base;
    final MissionStep step = _tracker.apply(base.missions, event);
    if (step.completed.isEmpty && step.failed.isEmpty) {
      return base.copyWith(missions: step.missions);
    }
    int score = base.score;
    int shakes = base.shakes;
    int bombs = base.bombs;
    int upgrades = base.upgrades;
    for (final Mission m in step.completed) {
      score += m.reward.points;
      switch (m.reward.bonus) {
        case Bonus.shake:
          shakes++;
        case Bonus.bomb:
          bombs++;
        case Bonus.upgrade:
          upgrades++;
        case null:
          break;
      }
    }
    final int stars = step.completed.length * MissionReward.stars;
    if (stars > 0) {
      _missionLevel += step.completed.length;
      _progress = _progress.copyWith(
        stars: _progress.stars + stars,
        missionsDone: _progress.missionsDone + step.completed.length,
      );
      unawaited(progressRepository.saveProgress(_progress));
      audio.missionDone();
      unawaited(gameCenter.unlock(
        GameAchievement.forMissions(_progress.missionsDone),
      ));
    }
    final List<Mission> missions = List<Mission>.from(step.missions);
    final int replacements = step.completed.length + step.failed.length;
    for (int i = 0; i < replacements; i++) {
      missions.add(_missions.next(
        _missionLevel,
        existing: missions,
        id: _nextMissionId++,
      ));
    }
    // Очки награды могут поднять рекорд.
    final bool newBest = score > base.bestScore;
    if (newBest) unawaited(_persistBest(score));
    return base.copyWith(
      score: score,
      bestScore: newBest ? score : null,
      shakes: shakes,
      bombs: bombs,
      upgrades: upgrades,
      missions: missions,
      completedMission: step.completed.isEmpty ? null : step.completed.last,
      completedCount: base.completedCount + step.completed.length,
      starsEarned: base.starsEarned + stars,
    );
  }

  Future<void> _persistBest(int score) async {
    final GameStatsModel stats = await statsRepository.getStats();
    if (score > _bestOf(stats)) {
      await statsRepository.saveStats(_withBest(stats, score));
    }
  }

  /// Движок сообщает, что текущий шар брошен.
  void onDropped() {
    audio.drop();
    _safeEmit(_withMissionEvent(
      state.copyWith(current: state.next, next: _rollTier()),
      const DropEvent(),
    ));
  }

  void pause() {
    if (state.adBusy) return;
    _safeEmit(state.copyWith(status: GameStatus.paused, disarm: true));
  }

  void resume() => _safeEmit(
        state.copyWith(status: GameStatus.playing, missionsOpen: false),
      );

  /// Экран заказов: ставит партию на паузу; закрытие возвращает в игру,
  /// а если открыли из паузы — в паузу.
  bool _missionsFromPause = false;

  void showMissions() {
    if (state.adBusy || state.status == GameStatus.gameOver) return;
    _missionsFromPause = state.status == GameStatus.paused;
    _safeEmit(state.copyWith(
      status: GameStatus.paused,
      missionsOpen: true,
      disarm: true,
    ));
  }

  void hideMissions() {
    if (!state.missionsOpen) return;
    _safeEmit(state.copyWith(
      status: _missionsFromPause ? GameStatus.paused : GameStatus.playing,
      missionsOpen: false,
    ));
  }

  /// Звёзды и выполненные заказы за всё время (для экрана заказов и
  /// подсказки «до следующего стакана»).
  int get totalStars => _progress.stars;
  int get totalMissionsDone => _progress.missionsDone;

  // --- Бонусы ----------------------------------------------------------------

  /// Кнопка бонуса: взводит его (показывается подсказка) или, если он уже
  /// взведён, снимает. Взвести можно один бонус за раз.
  void armBonus(Bonus bonus) {
    if (state.armed == bonus) {
      disarmBonus();
      return;
    }
    if (state.status != GameStatus.playing || state.charges(bonus) <= 0) {
      return;
    }
    _safeEmit(state.copyWith(armed: bonus));
  }

  void disarmBonus() {
    if (state.armed != null) _safeEmit(state.copyWith(disarm: true));
  }

  /// Кнопка бонуса без зарядов: пополнить их — премиуму сразу, остальным
  /// за rewarded-ролик. Лимит — [GameRules.refillsPerBonus] на партию.
  Future<void> requestRefill(Bonus bonus) async {
    if (state.adBusy || !state.canRefill(bonus)) return;
    _safeEmit(state.copyWith(adBusy: true, adUnavailable: false, disarm: true));
    final bool granted = await _watchAd(AdPlacement.refill);
    if (isClosed) return;
    if (!granted) {
      _safeEmit(state.copyWith(adBusy: false));
      return;
    }
    audio.merge(BallTier.t3);
    final int full = GameState.fullCharges(bonus);
    _safeEmit(switch (bonus) {
      Bonus.shake => state.copyWith(
          adBusy: false,
          shakes: full,
          shakeRefills: state.shakeRefills - 1,
        ),
      Bonus.bomb => state.copyWith(
          adBusy: false,
          bombs: full,
          bombRefills: state.bombRefills - 1,
        ),
      Bonus.upgrade => state.copyWith(
          adBusy: false,
          upgrades: full,
          upgradeRefills: state.upgradeRefills - 1,
        ),
    });
  }

  /// Без рекламы (премиум или монетизация выключена) — награда сразу;
  /// иначе ролик. `unavailable` поднимает подсказку [GameState.adUnavailable].
  bool get adFree => !AppConfig.monetizationEnabled || premium.isPremium.value;

  Future<bool> _watchAd(AdPlacement placement) async {
    if (adFree) return true;
    final AdResult result = await ads.showRewarded(placement);
    if (result == AdResult.unavailable && !isClosed) {
      _safeEmit(state.copyWith(adUnavailable: true));
    }
    return result == AdResult.earned;
  }

  /// Телефон встряхнули при взведённой встряске: заряд списан. Сами фрукты
  /// подбрасывает движок (`WasDropGame.shake`).
  bool useShake() {
    if (state.armed != Bonus.shake || state.shakes <= 0) return false;
    if (state.status != GameStatus.playing) return false;
    audio.shake();
    _safeEmit(state.copyWith(shakes: state.shakes - 1, disarm: true));
    return true;
  }

  /// Движок взорвал выбранный фрукт [tier]: заряд списан, режим выбора снят.
  void useBomb(BallTier tier) {
    if (state.armed != Bonus.bomb || state.bombs <= 0) return;
    audio.bomb();
    _safeEmit(_withMissionEvent(
      state.copyWith(bombs: state.bombs - 1, disarm: true),
      BombEvent(tier),
    ));
  }

  /// Движок увеличил выбранный фрукт до [produced]: заряд списан, режим
  /// выбора снят; очков не даёт, но крупнейший фрукт партии обновляется.
  void useUpgrade(BallTier produced) {
    if (state.armed != Bonus.upgrade || state.upgrades <= 0) return;
    audio.merge(BallTier.values[produced.index - 1]);
    _safeEmit(state.copyWith(
      upgrades: state.upgrades - 1,
      bestTier: _maxTier(state.bestTier, produced),
      disarm: true,
    ));
    unawaited(gameCenter.unlock(GameAchievement.forFruit(produced)));
  }

  /// Сохраняет партию (счёт, очередь, шары [balls]) для «Продолжить» в
  /// меню. Законченная или пустая партия снимок стирает.
  /// [jarId] — стакан партии (движок знает форму, кубит — нет).
  Future<void> saveSnapshot(List<BallSnapshot> balls, {required String jarId}) {
    if (mode != GameMode.classic ||
        state.status == GameStatus.gameOver ||
        (balls.isEmpty && state.score == 0)) {
      return gameRepository.clear();
    }
    return gameRepository.save(GameSnapshot(
      score: state.score,
      current: state.current,
      next: state.next,
      merges: state.merges,
      bestTier: state.bestTier,
      shakes: state.shakes,
      bombs: state.bombs,
      upgrades: state.upgrades,
      continues: state.continues,
      shakeRefills: state.shakeRefills,
      bombRefills: state.bombRefills,
      upgradeRefills: state.upgradeRefills,
      balls: balls,
      savedAt: DateTime.now(),
      jarId: jarId,
      missions: state.missions,
    ));
  }

  Future<void> gameOver() async {
    final bool isRecord = state.score > _startBest;
    audio.gameOver(isRecord: isRecord);
    unawaited(gameRepository.clear());
    // Партия с продолжением уже посчитана при первом проигрыше.
    final GameStatsModel stats = await _saveRun(state, countGame: !_continued);
    _safeEmit(state.copyWith(
      status: GameStatus.gameOver,
      isNewRecord: isRecord,
      bestScore: _bestOf(stats),
      disarm: true,
      adUnavailable: false,
    ));
  }

  /// Ежедневный вызов: зачёт дня — первая партия (счёт запоминается,
  /// повторная в этот день не даётся). Пишется при проигрыше и при выходе.
  bool _dailyRecorded = false;

  Future<void> _recordDaily() async {
    if (mode != GameMode.daily || _dailyRecorded) return;
    _dailyRecorded = true;
    _progress = _progress.copyWith(
      dailyPlayedSeed: _dailySeed,
      dailyScore: state.score,
    );
    await progressRepository.saveProgress(_progress);
  }

  /// «Продолжить» на экране проигрыша: премиуму сразу, остальным за
  /// rewarded-ролик. Возвращает, выдано ли продолжение; статус партии не
  /// меняет — форма сначала снимает верхний слой в движке, потом зовёт
  /// [resumeAfterContinue].
  Future<bool> requestContinue() async {
    if (state.status != GameStatus.gameOver || state.adBusy) return false;
    if (!state.canContinue) return false;
    _safeEmit(state.copyWith(adBusy: true, adUnavailable: false));
    final bool granted = await _watchAd(AdPlacement.continueGame);
    if (isClosed) return false;
    if (!granted) {
      _safeEmit(state.copyWith(adBusy: false));
      return false;
    }
    _continued = true;
    _savedMerges = state.merges;
    _runSaved = false;
    _safeEmit(state.copyWith(adBusy: false, continues: state.continues - 1));
    return true;
  }

  void resumeAfterContinue() {
    if (state.status != GameStatus.gameOver) return;
    _safeEmit(state.copyWith(status: GameStatus.playing, isNewRecord: false));
  }

  void restart() {
    // Партия, брошенная из паузы, тоже идёт в статистику.
    if (!_runSaved) {
      unawaited(_saveRun(state, countGame: !_continued && state.score > 0));
    }
    unawaited(gameRepository.clear());
    _runSaved = false;
    _continued = false;
    _savedMerges = 0;
    _startBest = state.bestScore;
    _safeEmit(state.copyWith(
      score: 0,
      status: GameStatus.playing,
      isNewRecord: false,
      current: _rollTier(),
      next: _rollTier(),
      merges: 0,
      resetBestTier: true,
      shakes: GameRules.shakesPerGame,
      bombs: GameRules.bombsPerGame,
      upgrades: GameRules.upgradesPerGame,
      disarm: true,
      continues: GameRules.continuesPerGame,
      shakeRefills: GameRules.refillsPerBonus,
      bombRefills: GameRules.refillsPerBonus,
      upgradeRefills: GameRules.refillsPerBonus,
      adUnavailable: false,
      missions: _dealMissions(),
      completedCount: 0,
      starsEarned: 0,
      secondsLeft: mode == GameMode.timed ? GameRules.timedSeconds : null,
    ));
    _tracker.reset();
  }

  @override
  Future<void> close() async {
    _clock?.cancel();
    // Выход в меню посреди партии — статистику всё равно записываем.
    if (!_runSaved && (state.score > 0 || state.merges > 0)) {
      await _saveRun(state, countGame: !_continued && state.score > 0);
    }
    // Пустая партия день не сжигает: вызов можно открыть и передумать.
    if (state.score > 0 || state.merges > 0) await _recordDaily();
    return super.close();
  }

  /// Записывает партию [run] в статистику: рекорд, слияния (после
  /// продолжения — только новые, с [_savedMerges]), самый крупный фрукт и
  /// (если [countGame]) +1 к сыгранным. Возвращает новую статистику.
  Future<GameStatsModel> _saveRun(
    GameState run, {
    required bool countGame,
  }) async {
    _runSaved = true;
    final GameStatsModel stats = await statsRepository.getStats();
    final GameStatsModel updated = _withBest(stats, run.score).copyWith(
      gamesPlayed: stats.gamesPlayed + (countGame ? 1 : 0),
      totalMerges: stats.totalMerges + max(0, run.merges - _savedMerges),
      bestTier: _maxTier(stats.bestTier, run.bestTier),
    );
    _savedMerges = run.merges;
    await statsRepository.saveStats(updated);
    await _recordDaily();
    // Game Center: счёт партии в лидерборд режима, достижения за партии.
    unawaited(gameCenter.submitScore(mode, run.score));
    if (countGame) {
      unawaited(gameCenter.unlock(
        GameAchievement.forGames(updated.gamesPlayed),
      ));
    }
    return updated;
  }

  static BallTier? _maxTier(BallTier? a, BallTier? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.index >= b.index ? a : b;
  }
}
