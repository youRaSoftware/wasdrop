import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:domain/domain.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final StatsRepository statsRepository;
  final AudioService audio;
  final Random _random = Random();

  /// Первый бросаемый тир (пул — он и следующие [dropWeights.length] - 1).
  static const BallTier firstDropTier = BallTier.t1;

  /// Веса выпадения тиров начиная с [firstDropTier] (взвешено к младшим).
  static const List<int> dropWeights = <int>[5, 4, 3, 2, 1];

  /// Статистика текущей партии уже записана в репозиторий.
  bool _runSaved = false;

  GameCubit({required this.statsRepository, required this.audio})
      : super(const GameState(
          score: 0,
          bestScore: 0,
          status: GameStatus.playing,
          current: firstDropTier,
          next: firstDropTier,
        )) {
    _init();
  }

  Future<void> _init() async {
    final GameStatsModel stats = await statsRepository.getStats();
    _safeEmit(state.copyWith(
      bestScore: stats.bestScore,
      current: _rollTier(),
      next: _rollTier(),
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
    _safeEmit(state.copyWith(
      score: state.score + tier.mergeScore,
      merges: state.merges + 1,
      bestTier: _maxTier(state.bestTier, produced),
    ));
  }

  /// Движок сообщает, что текущий шар брошен.
  void onDropped() {
    audio.drop();
    _safeEmit(state.copyWith(current: state.next, next: _rollTier()));
  }

  void pause() => _safeEmit(state.copyWith(status: GameStatus.paused));

  void resume() => _safeEmit(state.copyWith(status: GameStatus.playing));

  Future<void> gameOver() async {
    final bool isRecord = state.score > state.bestScore;
    audio.gameOver(isRecord: isRecord);
    final GameStatsModel stats = await _saveRun(state, countGame: true);
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
    _runSaved = false;
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
