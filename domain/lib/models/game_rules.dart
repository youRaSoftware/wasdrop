/// Правила партии, общие для кубита игры и хранилища снимка партии.
abstract final class GameRules {
  /// Зарядов бонуса «Встряхнуть» на партию.
  static const int shakesPerGame = 3;

  /// Зарядов бонуса «Бомбочка» на партию.
  static const int bombsPerGame = 1;

  /// Зарядов бустера «Увеличить» (фрукт на уровень выше) на партию.
  static const int upgradesPerGame = 1;
}
