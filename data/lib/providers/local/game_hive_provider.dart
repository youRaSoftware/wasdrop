import 'package:hive/hive.dart';

/// Снимок партии одним значением под ключом режима (`snapshot` — классика,
/// `snapshot_garden` — сад): Map с примитивами и списком списков
/// `[tier, x, bottomOffset, angle, vx, vy, special, frozen]` — адаптеры
/// Hive не нужны.
class GameHiveProvider {
  final Box<dynamic> _box;

  GameHiveProvider(this._box);

  Map<String, dynamic>? read(String key) {
    final Object? raw = _box.get(key);
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  Future<void> write(String key, Map<String, dynamic> data) =>
      _box.put(key, data);

  Future<void> clear(String key) => _box.delete(key);
}
