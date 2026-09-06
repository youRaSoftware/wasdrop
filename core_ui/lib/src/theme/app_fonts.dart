import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppFonts {
  const AppFonts._();

  static const String family = 'Archivo';

  static const TextStyle score = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 34,
    height: 1,
    color: AppColors.textPrimary,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle best = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 0.66,
    color: AppColors.textSecondary,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 17,
    color: Colors.white,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w900,
    fontSize: 46,
    height: 1,
    color: AppColors.textPrimary,
  );

  static const TextStyle overlayTitle = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w900,
    fontSize: 20,
    letterSpacing: 1,
    color: AppColors.textPrimary,
  );
}
