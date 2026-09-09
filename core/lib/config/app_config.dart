/// Окружение сборки. Задаётся нативным flavor (`--flavor dev|prod`) и
/// дублируется dart-define `--dart-define=environment=dev|prod`
/// (см. `lib/main.dart`).
enum Flavor {
  dev,
  prod;

  static Flavor fromString(String value) {
    switch (value.toLowerCase()) {
      case 'prod':
      case 'production':
      case 'release':
        return Flavor.prod;
      case 'dev':
      case 'development':
      default:
        return Flavor.dev;
    }
  }
}

/// Конфигурация приложения, зависящая от flavor. Регистрируется в
/// `appLocator` при старте (`setupAppScope`), читается как
/// `appLocator<AppConfig>()`.
class AppConfig {
  final Flavor flavor;
  final String appName;

  const AppConfig({required this.flavor, required this.appName});

  factory AppConfig.fromFlavor(Flavor flavor) {
    switch (flavor) {
      case Flavor.dev:
        return const AppConfig(flavor: Flavor.dev, appName: 'Fruity Dev');
      case Flavor.prod:
        return const AppConfig(flavor: Flavor.prod, appName: 'Fruity Drop');
    }
  }

  bool get isDev => flavor == Flavor.dev;

  bool get isProd => flavor == Flavor.prod;

  /// Плашка «DEV» поверх приложения — только в dev-сборке.
  bool get showFlavorBanner => isDev;

  /// В dev используем тестовые рекламные блоки (rewarded ad — TODO).
  bool get useTestAds => isDev;
}
