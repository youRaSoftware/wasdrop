/// Правила партии, общие для кубита игры и хранилища снимка партии.
abstract final class GameRules {
  /// Зарядов бонуса «Встряхнуть» на партию.
  static const int shakesPerGame = 3;

  /// Зарядов бонуса «Бомбочка» на партию.
  static const int bombsPerGame = 1;

  /// Зарядов бустера «Увеличить» (фрукт на уровень выше) на партию.
  static const int upgradesPerGame = 1;

  /// Продолжений после проигрыша (снимает верхний слой фруктов) на партию:
  /// бесплатным — за rewarded-ролик, премиуму — просто так.
  static const int continuesPerGame = 1;

  /// Пополнений зарядов каждого бонуса на партию (за ролик / премиуму).
  static const int refillsPerBonus = 1;

  /// Длительность партии «На время», секунд.
  static const int timedSeconds = 120;

  /// Потолок зарядов с учётом наград за заказы: заказ может добавить заряд,
  /// но бонусы остаются редкими (встряска ≤ 4, бомбочка и увеличение ≤ 2).
  static const int maxShakes = shakesPerGame + 1;
  static const int maxBombs = bombsPerGame + 1;
  static const int maxUpgrades = upgradesPerGame + 1;
}
