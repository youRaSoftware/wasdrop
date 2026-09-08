import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Оверлей паузы (мокап, кадр 5): Продолжить / Заново / В меню, тумблеры
/// «Звук» и «Вибрация» и пикер тем-обоев — всё привязано к
/// [SettingsService.settings].
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
    final SettingsService settings = appLocator<SettingsService>();

    return AppOverlay(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Center(child: Text('ПАУЗА', style: AppFonts.overlayTitle)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Продолжить', onPressed: onResume),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Заново',
            icon: const AppIcon(AppIcons.restart, size: 20),
            onPressed: onRestart,
          ),
          const SizedBox(height: 4),
          AppTextButton(
            label: 'В меню',
            icon: const AppIcon(AppIcons.menuHome, size: 20),
            onPressed: onMenu,
          ),
          const Divider(color: AppColors.stroke),
          const SizedBox(height: 4),
          ValueListenableBuilder<SettingsModel>(
            valueListenable: settings.settings,
            builder: (BuildContext context, SettingsModel value, Widget? _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppToggleRow(
                    label: 'Звук',
                    value: value.soundOn,
                    onChanged: settings.setSoundOn,
                  ),
                  AppToggleRow(
                    label: 'Вибрация',
                    value: value.hapticsOn,
                    onChanged: settings.setHapticsOn,
                  ),
                  const Divider(color: AppColors.stroke),
                  const SizedBox(height: 6),
                  const Text('ОБОИ', style: AppFonts.best),
                  const SizedBox(height: 10),
                  ThemePicker(
                    themes: GameThemes.all,
                    selectedId: value.themeId,
                    onSelect: settings.setThemeId,
                  ),
                  const SizedBox(height: 2),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
