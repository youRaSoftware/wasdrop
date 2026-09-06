import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/local/local_providers.dart';
import '../repositories/repositories.dart';

final DataDI dataDI = DataDI();

class DataDI {
  Future<void> init() async {
    await Hive.initFlutter();

    final Box<dynamic> statsBox = await Hive.openBox<dynamic>('statsBox');
    final Box<dynamic> settingsBox = await Hive.openBox<dynamic>('settingsBox');

    final GetIt locator = GetIt.instance;

    locator.registerLazySingleton<StatsHiveProvider>(
      () => StatsHiveProvider(statsBox),
    );
    locator.registerLazySingleton<SettingsHiveProvider>(
      () => SettingsHiveProvider(settingsBox),
    );

    locator.registerLazySingleton<StatsRepository>(
      () => StatsRepositoryImpl(locator<StatsHiveProvider>()),
    );
    locator.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(locator<SettingsHiveProvider>()),
    );
  }
}
