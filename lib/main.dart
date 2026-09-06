import 'package:core/core.dart';
import 'package:flutter/services.dart' show appFlavor;

import 'main_common.dart';

/// Flavor берётся из `--dart-define=environment=dev|prod`; если define не
/// передан — из нативного `--flavor` (Flutter прокидывает его как
/// `appFlavor`); по умолчанию dev.
void main() async {
  const String environment = String.fromEnvironment('environment');
  final String flavorName =
      environment.isNotEmpty ? environment : (appFlavor ?? 'dev');

  await mainCommon(Flavor.fromString(flavorName));
}
