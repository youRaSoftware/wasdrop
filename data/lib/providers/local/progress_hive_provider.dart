import 'package:hive/hive.dart';

class ProgressHiveProvider {
  final Box<dynamic> _box;

  ProgressHiveProvider(this._box);

  int get stars => (_box.get('stars') as int?) ?? 0;
  int get missionsDone => (_box.get('missionsDone') as int?) ?? 0;
  bool get onboardingDone => (_box.get('onboardingDone') as bool?) ?? false;
  int get dailyPlayedSeed => (_box.get('dailyPlayedSeed') as int?) ?? 0;
  int get dailyScore => (_box.get('dailyScore') as int?) ?? 0;
  bool get gardenIntroDone => (_box.get('gardenIntroDone') as bool?) ?? false;

  Future<void> save({
    required int stars,
    required int missionsDone,
    required bool onboardingDone,
    required int dailyPlayedSeed,
    required int dailyScore,
    required bool gardenIntroDone,
  }) {
    return _box.putAll(<String, Object>{
      'stars': stars,
      'missionsDone': missionsDone,
      'onboardingDone': onboardingDone,
      'dailyPlayedSeed': dailyPlayedSeed,
      'dailyScore': dailyScore,
      'gardenIntroDone': gardenIntroDone,
    });
  }
}
