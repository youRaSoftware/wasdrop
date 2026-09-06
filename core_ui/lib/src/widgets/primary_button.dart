import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Кнопка из мокапа: градиент, «толстая» нижняя тень.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double height;

  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.height = 56,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.accentTop, AppColors.accent],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: AppColors.accentShadow, offset: Offset(0, 5)),
          ],
        ),
        child: Text(label, style: AppFonts.button),
      ),
    );
  }
}
