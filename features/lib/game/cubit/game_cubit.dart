import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:domain/domain.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final StatsRepository statsRepository;
  final GameRepository gameRepository;
  final AudioService audio;
  final Random _random = Random();

  /// Первый бросаемый тир (пул — он и следующие [dropWeights.length] - 1).
  static const BallTier firstDropTier = BallTier.t1;

  /// Веса выпадения тиров начиная с [firstDropTier] (взвешено к младшим).
  static const List<int> dropWeights = <int>[5, 4, 3, 2, 1];

  /// Статистика текущей партии уже записана в репозиторий.
  bool _runSaved = false;

  /// Рекорд до начала партии — с ним сравнивается счёт для «НОВЫЙ РЕКОРД»
  /// (сам `bestScore` в состоянии растёт вместе со счётом по ходу партии).
  int _startBest = 0;

  /// [resumeFrom] — сохранённая партия: счёт и очередь берутся из неё, игра
  /// открывается в паузе, шары восстанавливает движок.
  GameCubit({
    required this.statsRepository,
    required this.gameRepository,
    required this.audio,
    GameSnapshot? resumeFrom,
  }) : super(
          resumeFrom == null
              ? const GameState(
                  score: 0,
                  bestScore: 0,
                  status: GameStatus.playing,
                  current: firstDropTier,
                  next: firstDropTier,
                )
              : GameState(
                  score: resumeFrom.score,
                  bestScore: resumeFrom.score,
                  status: GameStatus.paused,
                  current: resumeFrom.current,
                  next: resumeFrom.next,
                  merges: resumeFrom.merges,
                  bestTier: resumeFrom.bestTier,
                ),
        ) {
    _init(resume: resumeFrom != null);
  }

  Future<void> _init({required bool resume}) async {
    final GameStatsModel stats = await statsRepository.getStats();
    _startBest = stats.bestScore;
    _safeEmit(state.copyWith(
      bestScore: max(stats.bestScore, state.score),
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
    _safeEmit(state.copyWith(
      score: score,
      bestScore: newBest ? score : null,
      merges: state.merges + 1,
      bestTier: _maxTier(state.bestTier, produced),
    ));
    if (newBest) unawaited(_persistBest(score));
  }

  Future<void> _persistBest(int score) async {
    final GameStatsModel stats = await statsRepository.getStats();
    if (score > stats.bestScore) {
      await statsRepository.saveStats(stats.copyWith(bestScore: score));
    }
  }

  /// Движок сообщает, что текущий шар брошен.
  void onDropped() {
    audio.drop();
    _safeEmit(state.copyWith(current: state.next, next: _rollTier()));
  }

  void pause() => _safeEmit(state.copyWith(status: GameStatus.paused));

  void resume() => _safeEmit(state.copyWith(status: GameStatus.playing));

  /// Сохраняет партию (счёт, очередь, шары [balls]) для «Продолжить» в
  /// меню. Законченная или пустая партия снимок стирает.
  Future<void> saveSnapshot(List<BallSnapshot> balls) {
    if (state.status == GameStatus.gameOver ||
        (balls.isEmpty && state.score == 0)) {
      return gameRepository.clear();
    }
    return gameRepository.save(GameSnapshot(
      score: state.score,
      current: state.current,
      next: state.next,
      merges: state.merges,
      bestTier: state.bestTier,
      balls: balls,
      savedAt: DateTime.now(),
    ));
  }

  Future<void> gameOver() async {
    final bool isRecord = state.score > _startBest;
    audio.gameOver(isRecord: isRecord);
    unawaited(gameRepository.clear());
    final GameStatsModel stats = await _saveRun(state, countGame: true);
    _startBest = stats.bestScore;
    _safeEmit(state.copyWith(
      status: GameStatus.gameOver,
      isNewRecord: isRecord,
      bestScore: stats.bestScore,
    ));
  }

  void restart() {
    // Партия, брошенная из паузы, тоже идёт в статистику.
    if (!_runSaved) {
      unawaited(_saveRun(state, countGame: state.score > 0));
    }
    unawaited(gameRepository.clear());
    _runSaved = false;
    _startBest = state.bestScore;
    _safeEmit(state.copyWith(
      score: 0,
      status: GameStatus.playing,
      isNewRecord: false,
      current: _rollTier(),
      next: _rollTier(),
      merges: 0,
      resetBestTier: true,
    ));
  }

  /// TODO: rewarded ad, потом снять верхний слой шаров и продолжить.
  void continueAfterAd() {
    _safeEmit(state.copyWith(status: GameStatus.playing));
  }

  @override
  Future<void> close() async {
    // Выход в меню посреди партии — статистику всё равно записываем.
    if (!_runSaved && (state.score > 0 || state.merges > 0)) {
      await _saveRun(state, countGame: state.score > 0);
    }
    return super.close();
  }

  /// Записывает партию [run] в статистику: рекорд, слияния, самый крупный
  /// фрукт и (если [countGame]) +1 к сыгранным. Возвращает новую
  /// статистику.
  Future<GameStatsModel> _saveRun(
    GameState run, {
    required bool countGame,
  }) async {
    _runSaved = true;
    final GameStatsModel stats = await statsRepository.getStats();
    final GameStatsModel updated = stats.copyWith(
      bestScore: max(stats.bestScore, run.score),
      gamesPlayed: stats.gamesPlayed + (countGame ? 1 : 0),
      totalMerges: stats.totalMerges + run.merges,
      bestTier: _maxTier(stats.bestTier, run.bestTier),
    );
    await statsRepository.saveStats(updated);
    return updated;
  }

  static BallTier? _maxTier(BallTier? a, BallTier? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.index >= b.index ? a : b;
  }
}
