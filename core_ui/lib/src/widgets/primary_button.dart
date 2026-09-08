import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import 'app_pressable.dart';
import 'button_label.dart';

/// Primary-кнопка из мокапа: градиент `accentTop → accent` и «толстая»
/// нижняя тень. При нажатии кнопка проседает на глубину тени (тень
/// схлопывается) и чуть сжимается. [icon] рисуется слева от подписи.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Widget? icon;

  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.height = AppDimens.buttonHeight,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    return AppPressable(
      onPressed: onPressed,
      child: ButtonLabel(label: label, style: AppFonts.button, icon: icon),
      builder: (BuildContext context, double pressed, Widget? child) {
        final double depth = AppDimens.buttonShadowDepth;
        return Transform.translate(
          offset: Offset(0, depth * pressed),
          child: Transform.scale(
            scale: 1 - 0.02 * pressed,
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
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
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.accentShadow,
                      offset: Offset(0, depth * (1 - pressed)),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
