import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Оверлей проигрыша (мокап, кадр 6): счёт, бейдж «НОВЫЙ РЕКОРД» или
/// текущий рекорд, Заново / В меню, под разделителем — «Продолжить за
/// рекламу» (премиуму — просто «Продолжить»; пока есть продолжения) и
/// «Убрать рекламу» → paywall (без премиума).
class GameOverOverlay extends StatelessWidget {
  static const Key continueKey = Key('game_over_continue');
  static const Key removeAdsKey = Key('game_over_remove_ads');

  final int score;
  final int bestScore;
  final bool isNewRecord;
  final VoidCallback onRestart;
  final VoidCallback onMenu;
  final VoidCallback onContinueAd;
  final VoidCallback onRemoveAds;

  /// Есть продолжения; без ролика (премиум или монетизация выключена);
  /// идёт показ ролика; ролик не загрузился (подсказка под кнопкой);
  /// показывать «Убрать рекламу» (монетизация включена, премиума нет).
  final bool canContinue;
  final bool isPremium;
  final bool adBusy;
  final bool adUnavailable;
  final bool showRemoveAds;

  const GameOverOverlay({
    required this.score,
    required this.bestScore,
    required this.isNewRecord,
    required this.onRestart,
    required this.onMenu,
    required this.onContinueAd,
    required this.onRemoveAds,
    required this.canContinue,
    required this.isPremium,
    required this.adBusy,
    required this.adUnavailable,
    this.showRemoveAds = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Text(
              context.tr(LocaleKeys.gameOver_title),
              textAlign: TextAlign.center,
              style: AppFonts.overlayTitle.copyWith(
                fontSize: 17,
                color: AppColors.textSecondary,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('$score', style: AppFonts.score.copyWith(fontSize: 44)),
          ),
          if (isNewRecord) ...<Widget>[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[AppColors.goldTop, AppColors.gold],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const AppIcon(AppIcons.trophy, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      context.tr(LocaleKeys.gameOver_newRecord),
                      style: AppFonts.button.copyWith(
                        fontSize: 13,
                        color: AppColors.goldText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.tr(
                  LocaleKeys.gameOver_best,
                  namedArgs: <String, String>{'score': '$bestScore'},
                ),
                style: AppFonts.best.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: context.tr(LocaleKeys.gameOver_restart),
            icon: const AppIcon(AppIcons.restart, size: 22),
            onPressed: onRestart,
          ),
          const SizedBox(height: 4),
          AppTextButton(
            label: context.tr(LocaleKeys.gameOver_menu),
            icon: const AppIcon(AppIcons.menuHome, size: 20),
            onPressed: onMenu,
          ),
          if (canContinue || showRemoveAds) ...<Widget>[
            const Divider(color: AppColors.stroke),
            const SizedBox(height: 4),
          ],
          if (canContinue)
            SecondaryButton(
              key: continueKey,
              label: context.tr(
                isPremium
                    ? LocaleKeys.gameOver_continueFree
                    : LocaleKeys.gameOver_continueAd,
              ),
              icon: isPremium ? null : const AppIcon(AppIcons.adPlay, size: 20),
              height: 48,
              outlined: true,
              onPressed: adBusy ? null : onContinueAd,
            ),
          if (canContinue && adUnavailable) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              context.tr(LocaleKeys.gameOver_adUnavailable),
              textAlign: TextAlign.center,
              style: AppFonts.best.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0,
              ),
            ),
          ],
          if (showRemoveAds)
            AppTextButton(
              key: removeAdsKey,
              label: context.tr(LocaleKeys.gameOver_removeAds),
              icon: const AppIcon(AppIcons.crown, size: 20),
              onPressed: adBusy ? null : onRemoveAds,
            ),
        ],
      ),
    );
  }
}
