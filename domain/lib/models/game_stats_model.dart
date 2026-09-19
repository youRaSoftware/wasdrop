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

  /// Рекорды режимов «На время» и «Ежедневный вызов» ([bestScore] — классика).
  final int bestTimed;
  final int bestDaily;
  final int bestGarden;

  const GameStatsModel({
    required this.bestScore,
    required this.gamesPlayed,
    this.totalMerges = 0,
    this.bestTier,
    this.bestTimed = 0,
    this.bestDaily = 0,
    this.bestGarden = 0,
  });

  const GameStatsModel.empty() : this(bestScore: 0, gamesPlayed: 0);

  GameStatsModel copyWith({
    int? bestScore,
    int? gamesPlayed,
    int? totalMerges,
    BallTier? bestTier,
    int? bestTimed,
    int? bestDaily,
    int? bestGarden,
  }) {
    return GameStatsModel(
      bestScore: bestScore ?? this.bestScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalMerges: totalMerges ?? this.totalMerges,
      bestTier: bestTier ?? this.bestTier,
      bestTimed: bestTimed ?? this.bestTimed,
      bestDaily: bestDaily ?? this.bestDaily,
      bestGarden: bestGarden ?? this.bestGarden,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        bestScore,
        gamesPlayed,
        totalMerges,
        bestTier,
        bestTimed,
        bestDaily,
        bestGarden,
      ];
}
