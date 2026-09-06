import 'dart:math';

import 'package:core/core.dart';
import 'package:domain/domain.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final StatsRepository statsRepository;
  final AudioService audio;
  final Random _random = Random();

  GameCubit({required this.statsRepository, required this.audio})
      : super(const GameState(
          score: 0,
          bestScore: 0,
          status: GameStatus.playing,
          current: BallTier.t1,
          next: BallTier.t2,
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

  /// Тиры 1–5, взвешенно к младшим.
  BallTier _rollTier() {
    const List<int> weights = <int>[5, 4, 3, 2, 1];
    int roll = _random.nextInt(15);
    for (int i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll < 0) return BallTier.values[i];
    }
    return BallTier.t1;
  }

  /// Движок сообщает о слиянии двух шаров тира [tier].
  void onMerge(BallTier tier) {
    audio.merge(tier);
    _safeEmit(state.copyWith(score: state.score + tier.mergeScore));
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
    final GameStatsModel stats = await statsRepository.getStats();
    await statsRepository.saveStats(stats.copyWith(
      bestScore: max(stats.bestScore, state.score),
      gamesPlayed: stats.gamesPlayed + 1,
    ));
    _safeEmit(state.copyWith(
      status: GameStatus.gameOver,
      isNewRecord: isRecord,
      bestScore: max(state.bestScore, state.score),
    ));
  }

  void restart() {
    _safeEmit(state.copyWith(
      score: 0,
      status: GameStatus.playing,
      isNewRecord: false,
      current: _rollTier(),
      next: _rollTier(),
    ));
  }

  /// TODO: rewarded ad, потом снять верхний слой шаров и продолжить.
  void continueAfterAd() {
    _safeEmit(state.copyWith(status: GameStatus.playing));
  }
}
