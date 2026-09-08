import 'package:hive/hive.dart';

class SettingsHiveProvider {
  final Box<dynamic> _box;

  SettingsHiveProvider(this._box);

  bool get soundOn => (_box.get('soundOn') as bool?) ?? true;
  bool get musicOn => (_box.get('musicOn') as bool?) ?? true;
  bool get hapticsOn => (_box.get('hapticsOn') as bool?) ?? false;
  bool get aimLineOn => (_box.get('aimLineOn') as bool?) ?? true;
  String? get themeId => _box.get('themeId') as String?;

  Future<void> save({
    required bool soundOn,
    required bool musicOn,
    required bool hapticsOn,
    required bool aimLineOn,
    required String themeId,
  }) async {
    await _box.putAll(<String, Object>{
      'soundOn': soundOn,
      'musicOn': musicOn,
      'hapticsOn': hapticsOn,
      'aimLineOn': aimLineOn,
      'themeId': themeId,
    });
  }
}
