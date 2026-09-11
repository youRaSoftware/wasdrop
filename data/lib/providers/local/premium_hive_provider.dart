import 'package:hive/hive.dart';

/// Флаг купленного премиума (бокс `premiumBox`, ключ `isPremium`).
class PremiumHiveProvider {
  static const String _key = 'isPremium';

  final Box<dynamic> _box;

  PremiumHiveProvider(this._box);

  bool get isPremium => (_box.get(_key) as bool?) ?? false;

  Future<void> save({required bool isPremium}) => _box.put(_key, isPremium);
}
