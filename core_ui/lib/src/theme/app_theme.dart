import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: AppFonts.family,
  scaffoldBackgroundColor: AppColors.bgScreen,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    surface: AppColors.bgScreen,
  ),
  splashFactory: NoSplash.splashFactory,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
);
