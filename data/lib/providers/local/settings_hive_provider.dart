import 'package:hive/hive.dart';

class SettingsHiveProvider {
  final Box<dynamic> _box;

  SettingsHiveProvider(this._box);

  bool get soundOn => (_box.get('soundOn') as bool?) ?? true;
  bool get hapticsOn => (_box.get('hapticsOn') as bool?) ?? false;

  Future<void> save({required bool soundOn, required bool hapticsOn}) async {
    await _box.putAll(<String, bool>{
      'soundOn': soundOn,
      'hapticsOn': hapticsOn,
    });
  }
}
