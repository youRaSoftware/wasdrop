import 'package:domain/domain.dart';

import '../providers/local/stats_hive_provider.dart';

class StatsRepositoryImpl implements StatsRepository {
  final StatsHiveProvider _provider;

  StatsRepositoryImpl(this._provider);

  @override
  Future<GameStatsModel> getStats() async {
    return GameStatsModel(
      bestScore: _provider.bestScore,
      gamesPlayed: _provider.gamesPlayed,
      totalMerges: _provider.totalMerges,
      bestTier: BallTier.fromNumber(_provider.bestTierNumber),
    );
  }

  @override
  Future<void> saveStats(GameStatsModel stats) {
    return _provider.save(
      bestScore: stats.bestScore,
      gamesPlayed: stats.gamesPlayed,
      totalMerges: stats.totalMerges,
      bestTierNumber: stats.bestTier?.number ?? 0,
    );
  }
}
