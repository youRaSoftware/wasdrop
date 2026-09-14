/// Внешние ссылки приложения: paywall («Политика конфиденциальности»,
/// «Условия использования») и экран настроек.
abstract final class AppConstants {
  static const String privacyPolicyUrl =
      'https://www.pyf.app/en/apps/fruity-drop/privacy';

  /// Стандартное лицензионное соглашение Apple для приложений из App Store.
  static const String termsOfServiceUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// Apple ID приложения в App Store Connect — страница отзыва в App Store
  /// («Оценить приложение» в настройках). Пустая строка скрывает кнопку.
  static const String appStoreId = '6809236566';
}
