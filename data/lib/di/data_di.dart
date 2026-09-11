import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/local/local_providers.dart';
import '../repositories/repositories.dart';

final DataDI dataDI = DataDI();

class DataDI {
  Future<void> init() async {
    await Hive.initFlutter();

    // Имена боксов дублируют `StorageConstants` в core (data не может
    // импортировать core) — держать в синхроне.
    final Box<dynamic> statsBox = await Hive.openBox<dynamic>('statsBox');
    final Box<dynamic> settingsBox = await Hive.openBox<dynamic>('settingsBox');
    final Box<dynamic> gameBox = await Hive.openBox<dynamic>('gameBox');
    final Box<dynamic> premiumBox = await Hive.openBox<dynamic>('premiumBox');

    final GetIt locator = GetIt.instance;

    locator.registerLazySingleton<StatsHiveProvider>(
      () => StatsHiveProvider(statsBox),
    );
    locator.registerLazySingleton<SettingsHiveProvider>(
      () => SettingsHiveProvider(settingsBox),
    );
    locator.registerLazySingleton<GameHiveProvider>(
      () => GameHiveProvider(gameBox),
    );
    locator.registerLazySingleton<PremiumHiveProvider>(
      () => PremiumHiveProvider(premiumBox),
    );

    locator.registerLazySingleton<StatsRepository>(
      () => StatsRepositoryImpl(locator<StatsHiveProvider>()),
    );
    locator.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(locator<SettingsHiveProvider>()),
    );
    locator.registerLazySingleton<GameRepository>(
      () => GameRepositoryImpl(locator<GameHiveProvider>()),
    );
    locator.registerLazySingleton<PremiumRepository>(
      () => PremiumRepositoryImpl(locator<PremiumHiveProvider>()),
    );
  }
}
