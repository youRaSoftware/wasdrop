class AppDimens {
  const AppDimens._();

  /// Мировая ширина игрового поля (логика физики), под неё же радиусы.
  static const double worldWidth = 360;

  /// Радиусы шаров тиров 1–11 в мировых единицах.
  static const List<double> ballRadii = <double>[
    6.7, 8.3, 10.3, 13.0, 16.3, 20.3, 25.3, 31.7, 39.7, 49.7, 62.0,
  ];

  static const double buttonHeight = 56;
  static const double buttonRadius = 28;
  static const double iconButtonSize = 52;
  static const double panelRadius = 24;
  static const double panelPadding = 24;
  static const double jarWallWidth = 5;
  static const double deadlineTopOffset = 38;
  static const double minTapTarget = 44;
}
