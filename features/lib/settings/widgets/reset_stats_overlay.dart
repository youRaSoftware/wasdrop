import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Подтверждение сброса статистики поверх экрана настроек.
class ResetStatsOverlay extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ResetStatsOverlay({
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppOverlay(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.tr(LocaleKeys.settings_resetTitle),
            textAlign: TextAlign.center,
            style: AppFonts.overlayTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(LocaleKeys.settings_resetBody),
            textAlign: TextAlign.center,
            style: AppFonts.button.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: context.tr(LocaleKeys.settings_resetConfirm),
            onPressed: onConfirm,
          ),
          const SizedBox(height: 4),
          AppTextButton(
            label: context.tr(LocaleKeys.settings_cancel),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
