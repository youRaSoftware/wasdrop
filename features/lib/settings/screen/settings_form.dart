import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../game/engine/fruit_assets.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/fruit_chain.dart';
import '../widgets/language_overlay.dart';
import '../widgets/reset_stats_overlay.dart';
import '../widgets/settings_link_row.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_value_row.dart';
import '../widgets/theme_label.dart';

/// Экран настроек: секции «Звук», «Игра» (линия прицела, обои, язык),
/// «Статистика», «Фрукты», «О приложении». Тумблеры привязаны к
/// [SettingsService.settings], статистика, версия и оверлеи —
/// в [SettingsCubit].
class SettingsForm extends StatelessWidget {
  static const Key languageRowKey = Key('settings_language');

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
                      Expanded(
                        child: Text(
                          context.tr(LocaleKeys.settings_title),
                          style: AppFonts.overlayTitle
                              .copyWith(color: theme.hudText),
                        ),
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
                                title: context.tr(LocaleKeys.settings_sound),
                                children: <Widget>[
                                  AppToggleRow(
                                    label:
                                        context.tr(LocaleKeys.settings_sounds),
                                    value: value.soundOn,
                                    onChanged: settings.setSoundOn,
                                  ),
                                  AppToggleRow(
                                    label:
                                        context.tr(LocaleKeys.settings_music),
                                    value: value.musicOn,
                                    onChanged: settings.setMusicOn,
                                  ),
                                  AppToggleRow(
                                    label: context
                                        .tr(LocaleKeys.settings_vibration),
                                    value: value.hapticsOn,
                                    onChanged: settings.setHapticsOn,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SettingsSection(
                                title: context.tr(LocaleKeys.settings_game),
                                children: <Widget>[
                                  AppToggleRow(
                                    label:
                                        context.tr(LocaleKeys.settings_aimLine),
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
                                          context.tr(
                                              LocaleKeys.settings_wallpapers),
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
                                          labelOf: (GameTheme t) =>
                                              themeLabel(context, t),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SettingsLinkRow(
                                    key: languageRowKey,
                                    label: context
                                        .tr(LocaleKeys.settings_language),
                                    value: AppLocalizationEnum.byCode(
                                          value.localeCode,
                                        )?.languageDisplayName ??
                                        context.tr(
                                            LocaleKeys.settings_languageSystem),
                                    onPressed: cubit.askLanguage,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SettingsSection(
                        title: context.tr(LocaleKeys.settings_stats),
                        children: <Widget>[
                          SettingsValueRow(
                            label: context.tr(LocaleKeys.settings_best),
                            value: '${stats.bestScore}',
                          ),
                          SettingsValueRow(
                            label: context.tr(LocaleKeys.settings_gamesPlayed),
                            value: '${stats.gamesPlayed}',
                          ),
                          SettingsValueRow(
                            label: context.tr(LocaleKeys.settings_merges),
                            value: '${stats.totalMerges}',
                          ),
                          SettingsValueRow(
                            label: context.tr(LocaleKeys.settings_biggestFruit),
                            value: bestTier == null
                                ? '—'
                                : FruitLabel.of(context, bestTier),
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
                            label: context.tr(LocaleKeys.settings_reset),
                            height: 46,
                            onPressed: cubit.askReset,
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SettingsSection(
                        title: context.tr(LocaleKeys.settings_fruits),
                        children: const <Widget>[FruitChain()],
                      ),
                      const SizedBox(height: 20),
                      SettingsSection(
                        title: context.tr(LocaleKeys.settings_about),
                        children: <Widget>[
                          SettingsValueRow(
                            label: context.tr(LocaleKeys.settings_version),
                            value: state.version.isEmpty ? '—' : state.version,
                          ),
                          SettingsLinkRow(
                            label: context.tr(LocaleKeys.settings_licenses),
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
          if (state.choosingLanguage)
            ValueListenableBuilder<SettingsModel>(
              valueListenable: settings.settings,
              builder: (BuildContext context, SettingsModel value, Widget? _) {
                return LanguageOverlay(
                  selectedCode: value.localeCode,
                  onSelect: (String? code) {
                    settings.setLocale(code);
                    final AppLocalizationEnum? lang =
                        AppLocalizationEnum.byCode(code);
                    if (lang == null) {
                      context.resetLocale();
                    } else {
                      context.setLocale(lang.locale);
                    }
                    cubit.closeLanguage();
                  },
                  onCancel: cubit.closeLanguage,
                );
              },
            ),
        ],
      ),
    );
  }
}
