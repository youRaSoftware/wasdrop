import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_pressable.dart';

/// Круглая иконка-кнопка (меню: 🔊 / ⚙️, HUD: пауза): поверхность `surface`
/// с обводкой 2 px `stroke`. При нажатии сжимается до 90 %.
class IconCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double size;

  const IconCircleButton({
    required this.child,
    required this.onPressed,
    this.size = AppDimens.iconButtonSize,
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
              border: Border.all(color: AppColors.stroke, width: 2),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
