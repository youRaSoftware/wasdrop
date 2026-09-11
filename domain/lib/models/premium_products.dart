/// Идентификаторы покупок в App Store Connect / Google Play.
abstract final class PremiumProducts {
  /// Non-consumable «Премиум навсегда»: без рекламы, все обои, продолжение
  /// и пополнение зарядов без роликов.
  static const String lifetime = 'com.wasdrop.premium.lifetime';

  static const Set<String> all = <String>{lifetime};
}
