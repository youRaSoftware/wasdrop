import 'package:domain/domain.dart';

import '../providers/local/progress_hive_provider.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressHiveProvider _provider;

  ProgressRepositoryImpl(this._provider);

  @override
  Future<ProgressModel> getProgress() async {
    return ProgressModel(
      stars: _provider.stars,
      missionsDone: _provider.missionsDone,
      onboardingDone: _provider.onboardingDone,
      dailyPlayedSeed: _provider.dailyPlayedSeed,
      dailyScore: _provider.dailyScore,
      gardenIntroDone: _provider.gardenIntroDone,
    );
  }

  @override
  Future<void> saveProgress(ProgressModel progress) {
    return _provider.save(
      stars: progress.stars,
      missionsDone: progress.missionsDone,
      onboardingDone: progress.onboardingDone,
      dailyPlayedSeed: progress.dailyPlayedSeed,
      dailyScore: progress.dailyScore,
      gardenIntroDone: progress.gardenIntroDone,
    );
  }
}
