import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_pressable.dart';

/// Круглая иконка-кнопка (меню: 🔊 / ⚙️, HUD: пауза, полоса бонусов):
/// поверхность `surface` с обводкой 2 px `stroke` (или [borderColor] —
/// например акцент у взведённой бомбочки). При нажатии сжимается до 90 %.
class IconCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final Color? borderColor;

  const IconCircleButton({
    required this.child,
    required this.onPressed,
    this.size = AppDimens.iconButtonSize,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      child: child,
      builder: (BuildContext context, double pressed, Widget? child) {
        return Transform.scale(
          scale: 1 - 0.1 * pressed,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                AppColors.surface,
                AppColors.secondarySurface,
                pressed,
              ),
              border: Border.all(
                color: borderColor ?? AppColors.stroke,
                width: 2,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
