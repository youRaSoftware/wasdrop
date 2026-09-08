import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import 'app_pressable.dart';
import 'button_label.dart';

/// Текстовая кнопка оверлеев («В меню»): подпись `textSecondary` 15/700,
/// тап-цель не меньше 44 px. При нажатии тускнеет и чуть сжимается.
/// [icon] рисуется слева от подписи.
class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  const AppTextButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      child: ButtonLabel(
        label: label,
        style: AppFonts.button.copyWith(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
        icon: icon,
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
