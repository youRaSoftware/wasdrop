import 'dart:async';

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> mainCommon(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[DeviceOrientation.portraitUp],
  );
  await setupAppScope(flavor);

  // Звук + хаптика на нажатия кнопок дизайн-системы.
  ButtonFeedback.onPressed = appLocator<AudioService>().tap;

  // Шрифты Rubik и Unbounded (OFL) — в «Лицензиях» на экране настроек.
  LicenseRegistry.addLicense(() async* {
    for (final String font in <String>['Rubik', 'Unbounded']) {
      final String text =
          await rootBundle.loadString('core/resources/fonts/OFL-$font.txt');
      yield LicenseEntryWithLineBreaks(<String>[font], text);
    }
  });

  runApp(const App());
}
