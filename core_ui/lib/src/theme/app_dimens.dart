class AppDimens {
  const AppDimens._();

  /// Мировая ширина игрового поля (логика физики), под неё же радиусы.
  /// Высота мира не фиксирована — берётся из пропорции виджета стакана,
  /// чтобы физическое дно совпадало с видимым.
  static const double worldWidth = 360;

  /// Радиусы шаров тиров 1–11 в мировых единицах (крупнее классической
  /// suika: t1 ≈ 8% ширины стакана, t11 ≈ 72%). Рост ≈ ×1.24 за тир.
  static const List<double> ballRadii = <double>[
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
    130,
  ];

  /// Центр подвешенного (ещё не брошенного) шара от верха стакана.
  static const double ballSpawnY = 44;

  /// Линия проигрыша от верха стакана. Ниже подвешенного шара самого
  /// крупного бросаемого тира (t5: 44 + 37 = 81) с запасом.
  static const double deadlineTopOffset = 96;

  static const double buttonHeight = 56;
  static const double buttonRadius = 28;

  /// Глубина «толстой» тени primary-кнопки; на столько кнопка проседает.
  static const double buttonShadowDepth = 5;
  static const double iconButtonSize = 52;
  static const double panelRadius = 24;
  static const double panelPadding = 24;
  static const double jarWallWidth = 5;

  /// Радиус нижних углов стакана снаружи; внутренний = минус стенка.
  /// Внутренний радиус повторяется скосами в физике, чтобы фрукт в углу
  /// не обрезался скруглением.
  static const double jarCornerRadius = 26;
  static const double jarInnerCornerRadius = jarCornerRadius - jarWallWidth;
  static const double minTapTarget = 44;
}
