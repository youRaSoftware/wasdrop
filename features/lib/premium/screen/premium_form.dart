import 'dart:async';

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../settings/widgets/theme_label.dart';
import '../cubit/premium_cubit.dart';
import '../widgets/premium_feature_row.dart';
import '../widgets/premium_link_row.dart';

/// Paywall: корона, заголовок, три пункта (без рекламы, все обои,
/// продолжение и заряды без роликов), «Купить за {price}», «Восстановить
/// покупки», ссылки на политику и условия. Если премиум куплен — карточка
/// «Премиум активен» и «Готово».
class PremiumForm extends StatelessWidget {
  static const Key buyKey = Key('premium_buy');
  static const Key restoreKey = Key('premium_restore');
  static const Key doneKey = Key('premium_done');

  const PremiumForm({super.key});

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('PremiumForm: cannot open $url: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final PremiumCubit cubit = context.read<PremiumCubit>();
    final PremiumState state = context.watch<PremiumCubit>().state;
    final GameTheme theme = AppThemeScope.of(context);
    final String? message = state.message;

    return AppScaffold(
      body: SafeArea(
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
                      context.tr(LocaleKeys.premium_title),
                      style:
                          AppFonts.overlayTitle.copyWith(color: theme.hudText),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(AppDimens.panelPadding),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimens.panelRadius),
                      border: Border.all(color: AppColors.stroke, width: 2),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: AppColors.panelShadow,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Center(child: AppIcon(AppIcons.crown, size: 64)),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            state.isPremium
                                ? context.tr(LocaleKeys.premium_active)
                                : context.tr(LocaleKeys.premium_subtitle),
                            textAlign: TextAlign.center,
                            style: AppFonts.overlayTitle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state.isPremium)
                          Text(
                            context.tr(LocaleKeys.premium_activeBody),
                            textAlign: TextAlign.center,
                            style: AppFonts.button.copyWith(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else ...<Widget>[
                          PremiumFeatureRow(
                            icon: const Icon(
                              Icons.block_rounded,
                              size: 22,
                              color: AppColors.alert,
                            ),
                            label: context.tr(LocaleKeys.premium_featureNoAds),
                          ),
                          // Пункт про обои есть только пока есть закрытые темы.
                          if (GameThemes.lockedIds.isNotEmpty)
                            PremiumFeatureRow(
                              icon: const Icon(
                                Icons.palette_rounded,
                                size: 22,
                                color: AppColors.accent,
                              ),
                              label:
                                  context.tr(LocaleKeys.premium_featureThemes),
                              trailing: IgnorePointer(
                                child: ThemePicker(
                                  themes: GameThemes.all,
                                  selectedId: '',
                                  onSelect: (String _) {},
                                  labelOf: (GameTheme t) =>
                                      themeLabel(context, t),
                                ),
                              ),
                            ),
                          PremiumFeatureRow(
                            icon: const AppIcon(AppIcons.adPlay, size: 22),
                            label:
                                context.tr(LocaleKeys.premium_featureContinue),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (state.isPremium)
                          PrimaryButton(
                            key: doneKey,
                            label: context.tr(LocaleKeys.premium_done),
                            onPressed: context.pop,
                          )
                        else ...<Widget>[
                          PrimaryButton(
                            key: buyKey,
                            label: context.tr(
                              LocaleKeys.premium_buy,
                              namedArgs: <String, String>{
                                'price': state.store.price ?? '…',
                              },
                            ),
                            onPressed: state.store.isReady && !state.busy
                                ? cubit.buy
                                : null,
                          ),
                          const SizedBox(height: 4),
                          AppTextButton(
                            key: restoreKey,
                            label: context.tr(LocaleKeys.premium_restore),
                            onPressed: state.busy ? null : cubit.restore,
                          ),
                        ],
                        if (state.store.status ==
                                PremiumStoreStatus.unavailable &&
                            !state.isPremium) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            context.tr(LocaleKeys.premium_storeUnavailable),
                            textAlign: TextAlign.center,
                            style: AppFonts.best.copyWith(
                              color: AppColors.textTertiary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                        if (message != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            context.tr(message),
                            textAlign: TextAlign.center,
                            style: AppFonts.best.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  PremiumLinkRow(
                    privacyLabel: context.tr(LocaleKeys.premium_privacy),
                    termsLabel: context.tr(LocaleKeys.premium_terms),
                    onPrivacy: () =>
                        unawaited(_open(AppConstants.privacyPolicyUrl)),
                    onTerms: () =>
                        unawaited(_open(AppConstants.termsOfServiceUrl)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
