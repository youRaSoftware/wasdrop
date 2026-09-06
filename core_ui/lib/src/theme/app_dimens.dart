class AppDimens {
  const AppDimens._();

  /// Мировая ширина игрового поля (логика физики), под неё же радиусы.
  /// Высота мира не фиксирована — берётся из пропорции виджета стакана,
  /// чтобы физическое дно совпадало с видимым.
  static const double worldWidth = 360;

  /// Радиусы шаров тиров 1–11 в мировых единицах (пропорции классической
  /// suika: t1 ≈ 7% ширины стакана, t11 ≈ 58%). Рост ≈ ×1.24 за тир.
  static const List<double> ballRadii = <double>[
    12,
    15,
    19,
    24,
    30,
    37,
    46,
    56,
    70,
    86,
    105,
  ];

  /// Центр подвешенного (ещё не брошенного) шара от верха стакана.
  static const double ballSpawnY = 44;

  /// Линия проигрыша от верха стакана. Ниже подвешенного шара самого
  /// крупного бросаемого тира (t5: 44 + 30 = 74) с запасом.
  static const double deadlineTopOffset = 96;

  static const double buttonHeight = 56;
  static const double buttonRadius = 28;

  /// Глубина «толстой» тени primary-кнопки; на столько кнопка проседает.
  static const double buttonShadowDepth = 5;
  static const double iconButtonSize = 52;
  static const double panelRadius = 24;
  static const double panelPadding = 24;
  static const double jarWallWidth = 5;
  static const double minTapTarget = 44;
}
