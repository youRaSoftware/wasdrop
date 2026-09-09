import 'package:domain/domain.dart';

import '../providers/local/game_hive_provider.dart';

class GameRepositoryImpl implements GameRepository {
  final GameHiveProvider _provider;

  GameRepositoryImpl(this._provider);

  @override
  Future<GameSnapshot?> load() async {
    final Map<String, dynamic>? data = _provider.read();
    if (data == null) return null;
    try {
      final List<BallSnapshot> balls = <BallSnapshot>[];
      for (final Object? raw in data['balls'] as List<dynamic>) {
        final List<dynamic> v = raw as List<dynamic>;
        final BallTier? tier = BallTier.fromNumber(v[0] as int);
        if (tier == null) continue;
        balls.add(BallSnapshot(
          tier: tier,
          x: (v[1] as num).toDouble(),
          bottomOffset: (v[2] as num).toDouble(),
          angle: (v[3] as num).toDouble(),
          vx: (v[4] as num).toDouble(),
          vy: (v[5] as num).toDouble(),
        ));
      }
      return GameSnapshot(
        score: data['score'] as int,
        current: BallTier.fromNumber(data['current'] as int) ?? BallTier.t1,
        next: BallTier.fromNumber(data['next'] as int) ?? BallTier.t1,
        merges: (data['merges'] as int?) ?? 0,
        bestTier: BallTier.fromNumber((data['bestTier'] as int?) ?? 0),
        balls: balls,
        savedAt: DateTime.fromMillisecondsSinceEpoch(data['savedAt'] as int),
      );
    } catch (_) {
      // Повреждённый или устаревший формат — партию не восстанавливаем.
      await _provider.clear();
      return null;
    }
  }

  @override
  Future<void> save(GameSnapshot snapshot) {
    return _provider.write(<String, dynamic>{
      'score': snapshot.score,
      'current': snapshot.current.number,
      'next': snapshot.next.number,
      'merges': snapshot.merges,
      'bestTier': snapshot.bestTier?.number ?? 0,
      'savedAt': snapshot.savedAt.millisecondsSinceEpoch,
      'balls': <List<Object>>[
        for (final BallSnapshot b in snapshot.balls)
          <Object>[b.tier.number, b.x, b.bottomOffset, b.angle, b.vx, b.vy],
      ],
    });
  }

  @override
  Future<void> clear() => _provider.clear();
}
