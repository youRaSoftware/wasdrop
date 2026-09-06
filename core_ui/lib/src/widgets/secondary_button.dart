import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_pressable.dart';

/// Вторичная кнопка из оверлеев (кадры 5–6): пилюля `secondarySurface`
/// с подписью `secondaryText`, либо [outlined] — прозрачная с обводкой
/// 2 px `stroke` («▶ Продолжить за рекламу»). При нажатии темнеет и
/// сжимается до 97 %.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool outlined;

  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.outlined = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle style = outlined
        ? AppFonts.button.copyWith(fontSize: 14, color: AppColors.textSecondary)
        : AppFonts.button
            .copyWith(fontSize: 16, color: AppColors.secondaryText);

    return AppPressable(
      onPressed: onPressed,
      child: Text(label, style: style),
      builder: (BuildContext context, double pressed, Widget? child) {
        return Transform.scale(
          scale: 1 - 0.03 * pressed,
          child: Opacity(
            opacity: onPressed == null ? 0.5 : 1,
            child: Container(
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                color: outlined
                    ? AppColors.secondarySurface.withValues(alpha: pressed)
                    : Color.lerp(
                        AppColors.secondarySurface,
                        AppColors.stroke,
                        pressed,
                      ),
                border: outlined
                    ? Border.all(color: AppColors.stroke, width: 2)
                    : null,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
