import 'package:equatable/equatable.dart';

import '../enums/ball_tier.dart';

/// Статистика игрока за всё время (Hive-бокс `statsBox`).
class GameStatsModel extends Equatable {
  final int bestScore;
  final int gamesPlayed;

  /// Всего слияний за всё время.
  final int totalMerges;

  /// Самый крупный фрукт, полученный слиянием (null — ещё не было).
  final BallTier? bestTier;

  const GameStatsModel({
    required this.bestScore,
    required this.gamesPlayed,
    this.totalMerges = 0,
    this.bestTier,
  });

  const GameStatsModel.empty() : this(bestScore: 0, gamesPlayed: 0);

  GameStatsModel copyWith({
    int? bestScore,
    int? gamesPlayed,
    int? totalMerges,
    BallTier? bestTier,
  }) {
    return GameStatsModel(
      bestScore: bestScore ?? this.bestScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalMerges: totalMerges ?? this.totalMerges,
      bestTier: bestTier ?? this.bestTier,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[bestScore, gamesPlayed, totalMerges, bestTier];
}
