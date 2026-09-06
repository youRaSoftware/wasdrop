import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Модальный оверлей поверх игры (пауза, проигрыш): затемнение `scrim`,
/// по центру панель `surface` радиуса 24 с внутренним отступом 24.
/// Появляется с анимацией: затемнение проявляется, панель всплывает
/// с лёгким overshoot.
class AppOverlay extends StatelessWidget {
  static const Duration duration = Duration(milliseconds: 280);

  final Widget child;
  final double width;

  const AppOverlay({
    required this.child,
    this.width = 288,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double t, Widget? child) {
        final double pop = Curves.easeOutBack.transform(t);
        return ColoredBox(
          color: AppColors.scrim.withValues(alpha: AppColors.scrim.a * t),
          child: Center(
            child: Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - pop)),
                child: Transform.scale(scale: 0.92 + 0.08 * pop, child: child),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppDimens.panelPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.panelRadius),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.panelShadow,
              offset: Offset(0, 12),
              blurRadius: 32,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
