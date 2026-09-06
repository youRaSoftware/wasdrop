import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import 'app_pressable.dart';

/// Текстовая кнопка оверлеев («В меню»): подпись `textSecondary` 15/800,
/// тап-цель не меньше 44 px. При нажатии тускнеет и чуть сжимается.
class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppTextButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      child: Text(
        label,
        style: AppFonts.button.copyWith(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
      ),
      builder: (BuildContext context, double pressed, Widget? child) {
        return Transform.scale(
          scale: 1 - 0.03 * pressed,
          child: Opacity(
            opacity: 1 - 0.4 * pressed,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppDimens.minTapTarget,
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
