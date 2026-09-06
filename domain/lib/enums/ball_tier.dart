enum BallTier {
  t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11;

  int get number => index + 1;

  /// Очки за слияние двух шаров этого тира.
  int get mergeScore => 1 << number;

  static const List<String> _emoji = <String>[
    '🍒', '🍓', '🍊', '🍋', '🍏', '🥝', '🫐', '🍇', '🍑', '🍈', '🍉',
  ];

  String get emoji => _emoji[index];

  BallTier? get next =>
      this == BallTier.t11 ? null : BallTier.values[index + 1];
}
