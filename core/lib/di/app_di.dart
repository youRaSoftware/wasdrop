import 'dart:async';

import 'package:data/data.dart';
import 'package:get_it/get_it.dart';
import 'package:navigation/navigation.dart';

import '../config/app_config.dart';

final GetIt appLocator = GetIt.instance;

Future<void> setupAppScope(Flavor flavor) async {
  appLocator.registerSingleton<AppConfig>(AppConfig.fromFlavor(flavor));
  await dataDI.init();
  setupNavigationDependencies();
}
