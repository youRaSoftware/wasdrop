import 'package:flutter/material.dart';

/// Вариант 1a «тёплый фруктовый» из мокапов WasDrop.
class AppColors {
  const AppColors._();

  static const Color bgScreen = Color(0xFFF7F2E7);
  static const Color surface = Color(0xFFFFFDF6);
  static const Color jar = Color(0xFFECE5D6);
  static const Color jarWall = Color(0xFFD9CFBB);
  static const Color deadline = Color(0xFFBDB29B);
  static const Color textPrimary = Color(0xFF33291A);
  static const Color textSecondary = Color(0xFF8A7D63);
  static const Color textTertiary = Color(0xFFB3A88C);
  static const Color stroke = Color(0xFFE4DCC9);
  static const Color secondarySurface = Color(0xFFF1EADA);
  static const Color secondaryText = Color(0xFF6B5F45);

  static const Color accent = Color(0xFFF76B15);
  static const Color accentTop = Color(0xFFFF8A34);
  static const Color accentShadow = Color(0xFFD95806);
  static const Color alert = Color(0xFFE5484D);
  static const Color scoreGain = Color(0xFF12A594);
  static const Color goldTop = Color(0xFFF8CF5B);
  static const Color gold = Color(0xFFEFB008);
  static const Color goldText = Color(0xFF5C4703);

  /// Цвета тиров 1–11: тон по кругу, светлота ~const.
  static const List<Color> tiers = <Color>[
    Color(0xFFE5484D),
    Color(0xFFF76B15),
    Color(0xFFEFB008),
    Color(0xFF8FBF1F),
    Color(0xFF3BA55C),
    Color(0xFF12A594),
    Color(0xFF00A2C7),
    Color(0xFF0090FF),
    Color(0xFF6E56CF),
    Color(0xFFAB4ABA),
    Color(0xFFE93D82),
  ];
}
