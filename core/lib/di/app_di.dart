import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import 'package:navigation/navigation.dart';

import '../config/app_config.dart';
import '../services/audio_service.dart';

final GetIt appLocator = GetIt.instance;

Future<void> setupAppScope(Flavor flavor) async {
  appLocator.registerSingleton<AppConfig>(AppConfig.fromFlavor(flavor));
  await dataDI.init();
  setupNavigationDependencies();

  final AudioService audio = AudioService(appLocator<SettingsRepository>());
  appLocator.registerSingleton<AudioService>(audio);
  await audio.init();
}
