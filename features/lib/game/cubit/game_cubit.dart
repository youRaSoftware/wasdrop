import 'dart:math';

import 'package:core/core.dart';
import 'package:domain/domain.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final StatsRepository statsRepository;
  final Random _random = Random();

  GameCubit({required this.statsRepository})
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
    emit(state.copyWith(
      bestScore: stats.bestScore,
      current: _rollTier(),
      next: _rollTier(),
    ));
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
    emit(state.copyWith(score: state.score + tier.mergeScore));
  }

  /// Движок сообщает, что текущий шар брошен.
  void onDropped() {
    emit(state.copyWith(current: state.next, next: _rollTier()));
  }

  void pause() => emit(state.copyWith(status: GameStatus.paused));

  void resume() => emit(state.copyWith(status: GameStatus.playing));

  Future<void> gameOver() async {
    final bool isRecord = state.score > state.bestScore;
    final GameStatsModel stats = await statsRepository.getStats();
    await statsRepository.saveStats(stats.copyWith(
      bestScore: max(stats.bestScore, state.score),
      gamesPlayed: stats.gamesPlayed + 1,
    ));
    emit(state.copyWith(
      status: GameStatus.gameOver,
      isNewRecord: isRecord,
      bestScore: max(state.bestScore, state.score),
    ));
  }

  void restart() {
    emit(state.copyWith(
      score: 0,
      status: GameStatus.playing,
      isNewRecord: false,
      current: _rollTier(),
      next: _rollTier(),
    ));
  }

  /// TODO: rewarded ad, потом снять верхний слой шаров и продолжить.
  void continueAfterAd() {
    emit(state.copyWith(status: GameStatus.playing));
  }
}
