import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../game/engine/fruit_assets.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/fruit_chain.dart';
import '../widgets/reset_stats_overlay.dart';
import '../widgets/settings_link_row.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_value_row.dart';

/// Экран настроек: секции «Звук», «Игра», «Статистика», «Фрукты»,
/// «О приложении». Тумблеры привязаны к [SettingsService.settings],
/// статистика и версия — в [SettingsCubit].
class SettingsForm extends StatelessWidget {
  const SettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsCubit cubit = context.read<SettingsCubit>();
    final SettingsState state = context.watch<SettingsCubit>().state;
    final SettingsService settings = appLocator<SettingsService>();
    final AppConfig config = appLocator<AppConfig>();
    final GameStatsModel stats = state.stats;
    final BallTier? bestTier = stats.bestTier;
    final GameTheme theme = AppThemeScope.of(context);

    return AppScaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: <Widget>[
                      IconCircleButton(
                        size: AppDimens.minTapTarget,
                        onPressed: context.pop,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'НАСТРОЙКИ',
                        style: AppFonts.overlayTitle
                            .copyWith(color: theme.hudText),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: <Widget>[
                      ValueListenableBuilder<SettingsModel>(
                        valueListenable: settings.settings,
                        builder: (BuildContext context, SettingsModel value,
                            Widget? _) {
                          return Column(
                            children: <Widget>[
                              SettingsSection(
                                title: 'ЗВУК',
                                children: <Widget>[
                                  AppToggleRow(
                                    label: 'Звуки',
                                    value: value.soundOn,
                                    onChanged: settings.setSoundOn,
                                  ),
                                  AppToggleRow(
                                    label: 'Музыка',
                                    value: value.musicOn,
                                    onChanged: settings.setMusicOn,
                                  ),
                                  AppToggleRow(
                                    label: 'Вибрация',
                                    value: value.hapticsOn,
                                    onChanged: settings.setHapticsOn,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SettingsSection(
                                title: 'ИГРА',
                                children: <Widget>[
                                  AppToggleRow(
                                    label: 'Линия прицела',
                                    value: value.aimLineOn,
                                    onChanged: settings.setAimLineOn,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      bottom: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Обои',
                                          style: AppFonts.button.copyWith(
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ThemePicker(
                                          themes: GameThemes.all,
                                          selectedId: value.themeId,
                                          onSelect: settings.setThemeId,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SettingsSection(
                        title: 'СТАТИСТИКА',
                        children: <Widget>[
                          SettingsValueRow(
                            label: 'Рекорд',
                            value: '${stats.bestScore}',
                          ),
                          SettingsValueRow(
                            label: 'Игр сыграно',
                            value: '${stats.gamesPlayed}',
                          ),
                          SettingsValueRow(
                            label: 'Слияний',
                            value: '${stats.totalMerges}',
                          ),
                          SettingsValueRow(
                            label: 'Самый большой фрукт',
                            value: bestTier?.title ?? '—',
                            leading: bestTier == null
                                ? null
                                : BallView(
                                    tier: bestTier,
                                    diameter: 24,
                                    image: FruitAssets.idle(bestTier),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          SecondaryButton(
                            label: 'Сбросить статистику',
                            height: 46,
                            onPressed: cubit.askReset,
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const SettingsSection(
                        title: 'ФРУКТЫ',
                        children: <Widget>[FruitChain()],
                      ),
                      const SizedBox(height: 20),
                      SettingsSection(
                        title: 'О ПРИЛОЖЕНИИ',
                        children: <Widget>[
                          SettingsValueRow(
                            label: 'Версия',
                            value: state.version.isEmpty ? '—' : state.version,
                          ),
                          SettingsLinkRow(
                            label: 'Лицензии',
                            onPressed: () => showLicensePage(
                              context: context,
                              applicationName: config.appName,
                              applicationVersion: state.version,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (state.confirmingReset)
            ResetStatsOverlay(
              onConfirm: cubit.confirmReset,
              onCancel: cubit.cancelReset,
            ),
        ],
      ),
    );
  }
}
