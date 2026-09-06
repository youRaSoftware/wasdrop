import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onMenu,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x802B210E),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(AppDimens.panelPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.panelRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Center(
                  child: Text('ПАУЗА', style: AppFonts.overlayTitle)),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Продолжить', onPressed: onResume),
              const SizedBox(height: 12),
              _SecondaryButton(label: 'Заново', onPressed: onRestart),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onMenu,
                child: Text(
                  'В меню',
                  style: AppFonts.button
                      .copyWith(color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
              // TODO: тумблеры «Звук» и «Вибрация» (SettingsRepository)
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: AppFonts.button
              .copyWith(color: AppColors.secondaryText, fontSize: 16),
        ),
      ),
    );
  }
}
