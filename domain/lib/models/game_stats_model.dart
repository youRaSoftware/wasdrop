import 'package:equatable/equatable.dart';

class GameStatsModel extends Equatable {
  final int bestScore;
  final int gamesPlayed;

  const GameStatsModel({required this.bestScore, required this.gamesPlayed});

  const GameStatsModel.empty() : this(bestScore: 0, gamesPlayed: 0);

  GameStatsModel copyWith({int? bestScore, int? gamesPlayed}) {
    return GameStatsModel(
      bestScore: bestScore ?? this.bestScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    );
  }

  @override
  List<Object?> get props => <Object?>[bestScore, gamesPlayed];
}
