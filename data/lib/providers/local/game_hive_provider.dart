import 'package:hive/hive.dart';

/// Снимок партии одним значением под ключом `snapshot`: Map с примитивами
/// и списком списков `[tier, x, bottomOffset, angle, vx, vy]` — адаптеры
/// Hive не нужны.
class GameHiveProvider {
  static const String _key = 'snapshot';

  final Box<dynamic> _box;

  GameHiveProvider(this._box);

  Map<String, dynamic>? read() {
    final Object? raw = _box.get(_key);
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  Future<void> write(Map<String, dynamic> data) => _box.put(_key, data);

  Future<void> clear() => _box.delete(_key);
}
