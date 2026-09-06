import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

class IconCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;

  const IconCircleButton({
    required this.child,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: AppDimens.iconButtonSize,
        height: AppDimens.iconButtonSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.stroke, width: 2),
        ),
        child: child,
      ),
    );
  }
}
