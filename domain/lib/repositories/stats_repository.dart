import '../models/game_stats_model.dart';

abstract interface class StatsRepository {
  Future<GameStatsModel> getStats();
  Future<void> saveStats(GameStatsModel stats);
}
