/// Идентификаторы AdMob. В dev (`AppConfig.useTestAds`) — официальные
/// тестовые блоки Google; в prod — свои из консоли AdMob.
///
/// TODO(admob): после создания аккаунта AdMob вписать реальные ID в
/// [prodAppId], [prodContinueUnitId], [prodRefillUnitId] и в
/// `GAD_APPLICATION_ID` prod-конфигураций `ios/Runner.xcodeproj`.
abstract final class AdsConfig {
  /// App ID тестового приложения Google (iOS).
  static const String testAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Тестовый rewarded-блок Google (iOS).
  static const String testRewardedUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  static const String prodAppId = 'TODO';
  static const String prodContinueUnitId = 'TODO';
  static const String prodRefillUnitId = 'TODO';

  /// Таймаут загрузки ролика: дольше — считаем, что рекламы нет.
  static const Duration loadTimeout = Duration(seconds: 8);
}

/// Где показывается rewarded-ролик.
enum AdPlacement {
  /// «Продолжить за рекламу» на экране проигрыша.
  continueGame,

  /// Пополнение зарядов бонуса кнопкой под стаканом.
  refill,
}
