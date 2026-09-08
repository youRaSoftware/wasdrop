import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Типографика: пара **Rubik** (рабочий шрифт — весь UI, счёт, кнопки)
/// + **Unbounded** (дисплейный — лого и заголовки оверлеев). Оба Google
/// Fonts, OFL, файлы в `core/resources/fonts/`. Цифры — табличные.
class AppFonts {
  const AppFonts._();

  /// Рабочий шрифт (600 / 700 / 900).
  static const String family = 'Rubik';

  /// Дисплейный шрифт (600 / 800).
  static const String display = 'Unbounded';

  static const TextStyle score = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 34,
    height: 1,
    color: AppColors.textPrimary,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle best = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: 0.66,
    color: AppColors.textSecondary,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    color: Colors.white,
  );

  /// Лого в меню.
  static const TextStyle title = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w800,
    fontSize: 42,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  /// Заголовки оверлеев и экранов (ПАУЗА, ИГРА ОКОНЧЕНА, НАСТРОЙКИ).
  static const TextStyle overlayTitle = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w600,
    fontSize: 19,
    letterSpacing: 1,
    color: AppColors.textPrimary,
  );
}
