import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import 'package:navigation/navigation.dart';

import '../config/app_config.dart';
import '../services/ads_service.dart';
import '../services/audio_service.dart';
import '../services/premium_service.dart';
import '../services/settings_service.dart';

final GetIt appLocator = GetIt.instance;

Future<void> setupAppScope(Flavor flavor) async {
  appLocator.registerSingleton<AppConfig>(AppConfig.fromFlavor(flavor));
  await dataDI.init();
  setupNavigationDependencies();

  final SettingsService settings =
      SettingsService(appLocator<SettingsRepository>());
  appLocator.registerSingleton<SettingsService>(settings);
  await settings.init();

  final AudioService audio = AudioService(settings);
  appLocator.registerSingleton<AudioService>(audio);
  await audio.init();

  final PremiumService premium =
      PremiumService(appLocator<PremiumRepository>());
  appLocator.registerSingleton<PremiumService>(premium);
  await premium.init();

  // Реклама: согласие и инициализация SDK идут в фоне, запуск не ждут.
  final AdsService ads = AdsService(appLocator<AppConfig>(), premium, audio);
  appLocator.registerSingleton<AdsService>(ads);
  unawaited(ads.init());
}
