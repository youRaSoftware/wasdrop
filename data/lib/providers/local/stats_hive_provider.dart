import 'package:hive/hive.dart';

class StatsHiveProvider {
  final Box<dynamic> _box;

  StatsHiveProvider(this._box);

  int get bestScore => (_box.get('bestScore') as int?) ?? 0;
  int get gamesPlayed => (_box.get('gamesPlayed') as int?) ?? 0;
  int get totalMerges => (_box.get('totalMerges') as int?) ?? 0;

  /// Номер самого крупного фрукта (1…11), 0 — ещё не было.
  int get bestTierNumber => (_box.get('bestTier') as int?) ?? 0;

  Future<void> save({
    required int bestScore,
    required int gamesPlayed,
    required int totalMerges,
    required int bestTierNumber,
  }) async {
    await _box.putAll(<String, int>{
      'bestScore': bestScore,
      'gamesPlayed': gamesPlayed,
      'totalMerges': totalMerges,
      'bestTier': bestTierNumber,
    });
  }
}
