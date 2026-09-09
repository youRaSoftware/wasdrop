enum BallTier {
  t1,
  t2,
  t3,
  t4,
  t5,
  t6,
  t7,
  t8,
  t9,
  t10,
  t11;

  int get number => index + 1;

  /// Очки за слияние двух шаров этого тира.
  int get mergeScore => 1 << number;

  static const List<String> _emoji = <String>[
    '🍒',
    '🍓',
    '🍊',
    '🍋',
    '🍏',
    '🥝',
    '🫐',
    '🍇',
    '🍑',
    '🍈',
    '🍉',
  ];

  /// Эмодзи — только запасная отрисовка без спрайта. Название фрукта —
  /// локализованное, `FruitLabel.of(tier)` в core.
  String get emoji => _emoji[index];

  BallTier? get next =>
      this == BallTier.t11 ? null : BallTier.values[index + 1];

  /// Тир по номеру 1…11; null для 0 и значений вне диапазона.
  static BallTier? fromNumber(int number) =>
      number >= 1 && number <= values.length ? values[number - 1] : null;
}
