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
}
