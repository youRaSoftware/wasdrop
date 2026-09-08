import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Статичный декор фона темы (полупрозрачные фигуры, на геймплей не влияет).
enum ThemeDecor { none, stars, clouds, petals }

/// Тема-обои (ТЗ `my_docs/TZ_ASSETS.md`): фон экрана, стакан, линия
/// проигрыша и цвет текста поверх фона. Панели, кнопки и карточки остаются
/// светлыми `surface` во всех темах.
class GameTheme {
  final String id;
  final String name;
  final Color bgTop;
  final Color bgBottom;

  /// Заливка стакана; у большинства тем полупрозрачная — фон просвечивает.
  final Color jarFill;
  final Color jarWall;

  /// Линия проигрыша в покое и в тревоге.
  final Color deadline;
  final Color deadlineAlert;

  /// Текст поверх фона (счёт, «РЕКОРД», лого, заголовки).
  final Color hudText;
  final ThemeDecor decor;

  /// Задел под подписку: закрытая тема показывается с замком.
  final bool isLocked;

  const GameTheme({
    required this.id,
    required this.name,
    required this.bgTop,
    required this.bgBottom,
    required this.jarFill,
    required this.jarWall,
    required this.deadline,
    required this.hudText,
    this.deadlineAlert = AppColors.alert,
    this.decor = ThemeDecor.none,
    this.isLocked = false,
  });

  /// Вторичный текст поверх фона.
  Color get hudTextSecondary => hudText.withValues(alpha: 0.62);

  /// Третичный текст / пунктир прицела поверх фона.
  Color get hudTextTertiary => hudText.withValues(alpha: 0.42);

  LinearGradient get background => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[bgTop, bgBottom],
      );
}

/// Все темы. Выбранная хранится в `SettingsModel.themeId`.
abstract final class GameThemes {
  static const String defaultId = 'cream';

  static const GameTheme cream = GameTheme(
    id: defaultId,
    name: 'Крем',
    bgTop: AppColors.bgScreen,
    bgBottom: AppColors.bgScreen,
    jarFill: AppColors.jar,
    jarWall: AppColors.jarWall,
    deadline: AppColors.deadline,
    hudText: AppColors.textPrimary,
  );

  static const GameTheme sunset = GameTheme(
    id: 'sunset',
    name: 'Персиковый закат',
    bgTop: Color(0xFFFFE3C2),
    bgBottom: Color(0xFFF7B2A0),
    jarFill: Color(0xB8FFF4E6),
    jarWall: Color(0xFFE8B490),
    deadline: Color(0xFFC5997A),
    hudText: Color(0xFF5C3A24),
  );

  static const GameTheme mint = GameTheme(
    id: 'mint',
    name: 'Мятный сад',
    bgTop: Color(0xFFDFF3E4),
    bgBottom: Color(0xFFBFE6CB),
    jarFill: Color(0x9EFFFFFF),
    jarWall: Color(0xFF9CC9A9),
    deadline: Color(0xFF85AB90),
    hudText: Color(0xFF1F4A2E),
  );

  static const GameTheme night = GameTheme(
    id: 'night',
    name: 'Ночной сад',
    bgTop: Color(0xFF1E2433),
    bgBottom: Color(0xFF141926),
    jarFill: Color(0xFF232B3D),
    jarWall: Color(0xFF3A4358),
    // На тёмном стакане затемнённая стенка не видна — линия светлее.
    deadline: Color(0xFF5B667F),
    deadlineAlert: Color(0xFFFF5D7A),
    hudText: Color(0xFFF2EFE6),
    decor: ThemeDecor.stars,
  );

  static const GameTheme rose = GameTheme(
    id: 'rose',
    name: 'Пудрово-розовая',
    bgTop: Color(0xFFFBE4EC),
    bgBottom: Color(0xFFF6CFDD),
    jarFill: Color(0xB3FFF5F9),
    jarWall: Color(0xFFE3A8C0),
    deadline: Color(0xFFC18FA3),
    hudText: Color(0xFF6E2E48),
    decor: ThemeDecor.petals,
  );

  static const GameTheme sky = GameTheme(
    id: 'sky',
    name: 'Небо и облака',
    bgTop: Color(0xFFCBE8F7),
    bgBottom: Color(0xFFA9D6EF),
    jarFill: Color(0x99FFFFFF),
    jarWall: Color(0xFF8FBEDA),
    deadline: Color(0xFF7AA2B9),
    hudText: Color(0xFF6E9FBD),
    decor: ThemeDecor.clouds,
  );

  static const List<GameTheme> all = <GameTheme>[
    cream,
    sunset,
    mint,
    night,
    rose,
    sky,
  ];

  /// Тема по id; неизвестный id → [cream].
  static GameTheme byId(String id) {
    for (final GameTheme theme in all) {
      if (theme.id == id) return theme;
    }
    return cream;
  }
}
