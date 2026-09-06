part of 'game_cubit.dart';

enum GameStatus { playing, paused, gameOver }

class GameState extends Equatable {
  final int score;
  final int bestScore;
  final GameStatus status;
  final BallTier current;
  final BallTier next;
  final bool isNewRecord;

  const GameState({
    required this.score,
    required this.bestScore,
    required this.status,
    required this.current,
    required this.next,
    this.isNewRecord = false,
  });

  GameState copyWith({
    int? score,
    int? bestScore,
    GameStatus? status,
    BallTier? current,
    BallTier? next,
    bool? isNewRecord,
  }) {
    return GameState(
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      status: status ?? this.status,
      current: current ?? this.current,
      next: next ?? this.next,
      isNewRecord: isNewRecord ?? this.isNewRecord,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[score, bestScore, status, current, next, isNewRecord];
}
