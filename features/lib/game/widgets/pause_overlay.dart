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
  final VoidCallback onMissions;

  /// «Заново» скрыта в ежедневном вызове (один зачёт в день).
  final bool canRestart;

  const PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onMenu,
    required this.onMissions,
    this.canRestart = true,
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
          if (canRestart) ...<Widget>[
            const SizedBox(height: 12),
            SecondaryButton(
              label: context.tr(LocaleKeys.pause_restart),
              icon: const AppIcon(AppIcons.restart, size: 20),
              onPressed: onRestart,
            ),
          ],
          const SizedBox(height: 4),
          // Wrap, а не Row: длинные переводы («Aufträge» + «Menü») уходят на
          // вторую строку, а не вылезают за панель.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: <Widget>[
              AppTextButton(
                label: context.tr(LocaleKeys.pause_missions),
                icon: const AppIcon(AppIcons.missions, size: 20),
                onPressed: onMissions,
              ),
              AppTextButton(
                label: context.tr(LocaleKeys.pause_menu),
                icon: const AppIcon(AppIcons.menuHome, size: 20),
                onPressed: onMenu,
              ),
            ],
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
                  const SizedBox(height: 12),
                  // Стакан меняется для следующей партии (текущая идёт в своём).
                  AppTextButton(
                    label: context.tr(LocaleKeys.pause_changeJar),
                    icon: const AppIcon(AppIcons.jar, size: 20),
                    onPressed: () => context.pushNamed('jars'),
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
