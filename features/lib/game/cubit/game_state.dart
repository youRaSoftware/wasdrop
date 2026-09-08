part of 'game_cubit.dart';

enum GameStatus { playing, paused, gameOver }

class GameState extends Equatable {
  final int score;
  final int bestScore;
  final GameStatus status;
  final BallTier current;
  final BallTier next;
  final bool isNewRecord;

  /// Слияний за текущую партию.
  final int merges;

  /// Самый крупный фрукт, полученный за партию (null — ещё не было).
  final BallTier? bestTier;

  const GameState({
    required this.score,
    required this.bestScore,
    required this.status,
    required this.current,
    required this.next,
    this.isNewRecord = false,
    this.merges = 0,
    this.bestTier,
  });

  /// [bestTier] сбрасывается в null, только если передать `bestTier: null`
  /// явно через [resetBestTier].
  GameState copyWith({
    int? score,
    int? bestScore,
    GameStatus? status,
    BallTier? current,
    BallTier? next,
    bool? isNewRecord,
    int? merges,
    BallTier? bestTier,
    bool resetBestTier = false,
  }) {
    return GameState(
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      status: status ?? this.status,
      current: current ?? this.current,
      next: next ?? this.next,
      isNewRecord: isNewRecord ?? this.isNewRecord,
      merges: merges ?? this.merges,
      bestTier: resetBestTier ? null : (bestTier ?? this.bestTier),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        score,
        bestScore,
        status,
        current,
        next,
        isNewRecord,
        merges,
        bestTier,
      ];
}
