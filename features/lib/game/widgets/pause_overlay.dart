import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../settings/widgets/theme_label.dart';

/// Оверлей паузы (мокап, кадр 5): Продолжить / Заново / В меню, тумблеры
/// «Звук» и «Вибрация» и пикер тем-обоев — всё привязано к
/// [SettingsService.settings]; закрытые обои ведут на paywall.
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
    final PremiumService premium = appLocator<PremiumService>();

    return AppOverlay(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Text(
              context.tr(LocaleKeys.pause_title),
              style: AppFonts.overlayTitle,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: context.tr(LocaleKeys.pause_resume),
            onPressed: onResume,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: context.tr(LocaleKeys.pause_restart),
            icon: const AppIcon(AppIcons.restart, size: 20),
            onPressed: onRestart,
          ),
          const SizedBox(height: 4),
          AppTextButton(
            label: context.tr(LocaleKeys.pause_menu),
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
                    label: context.tr(LocaleKeys.pause_sound),
                    value: value.soundOn,
                    onChanged: settings.setSoundOn,
                  ),
                  AppToggleRow(
                    label: context.tr(LocaleKeys.pause_vibration),
                    value: value.hapticsOn,
                    onChanged: settings.setHapticsOn,
                  ),
                  const Divider(color: AppColors.stroke),
                  const SizedBox(height: 6),
                  Text(context.tr(LocaleKeys.pause_wallpapers),
                      style: AppFonts.best),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<bool>(
                    valueListenable: premium.isPremium,
                    builder: (BuildContext context, bool isPremium, Widget? _) {
                      return ThemePicker(
                        themes: GameThemes.all,
                        selectedId: value.themeId,
                        onSelect: settings.setThemeId,
                        labelOf: (GameTheme t) => themeLabel(context, t),
                        lockedIds:
                            isPremium ? const <String>{} : GameThemes.lockedIds,
                        onLockedTap: () => context.pushNamed('premium'),
                      );
                    },
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
