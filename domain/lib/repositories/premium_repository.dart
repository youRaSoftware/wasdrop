/// Кэш покупки «Премиум навсегда» на устройстве: офлайн премиум работает
/// из кэша, магазин (`PremiumService`) обновляет его при покупке и
/// восстановлении.
abstract interface class PremiumRepository {
  Future<bool> isPremium();
  Future<void> setPremium(bool value);
}
