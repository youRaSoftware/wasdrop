import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Оверлей паузы (мокап, кадр 5): Продолжить / Заново / В меню и тумблеры
/// «Звук» и «Вибрация», привязанные к [AudioService.settings].
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
    final AudioService audio = appLocator<AudioService>();

    return AppOverlay(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Center(child: Text('ПАУЗА', style: AppFonts.overlayTitle)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Продолжить', onPressed: onResume),
          const SizedBox(height: 12),
          SecondaryButton(label: 'Заново', onPressed: onRestart),
          const SizedBox(height: 4),
          AppTextButton(label: 'В меню', onPressed: onMenu),
          const Divider(color: AppColors.stroke),
          const SizedBox(height: 4),
          ValueListenableBuilder<SettingsModel>(
            valueListenable: audio.settings,
            builder: (BuildContext context, SettingsModel settings, Widget? _) {
              return Column(
                children: <Widget>[
                  AppToggleRow(
                    label: 'Звук',
                    value: settings.soundOn,
                    onChanged: audio.setSoundOn,
                  ),
                  AppToggleRow(
                    label: 'Вибрация',
                    value: settings.hapticsOn,
                    onChanged: audio.setHapticsOn,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
