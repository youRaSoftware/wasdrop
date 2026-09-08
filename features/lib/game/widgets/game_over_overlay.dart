import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Оверлей проигрыша (мокап, кадр 6): счёт, бейдж «НОВЫЙ РЕКОРД» или
/// текущий рекорд, Заново / В меню, под разделителем — продолжить за рекламу.
class GameOverOverlay extends StatelessWidget {
  final int score;
  final int bestScore;
  final bool isNewRecord;
  final VoidCallback onRestart;
  final VoidCallback onMenu;
  final VoidCallback onContinueAd;

  const GameOverOverlay({
    required this.score,
    required this.bestScore,
    required this.isNewRecord,
    required this.onRestart,
    required this.onMenu,
    required this.onContinueAd,
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
              'ИГРА ОКОНЧЕНА',
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
                      'НОВЫЙ РЕКОРД',
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
                'рекорд — $bestScore',
                style: AppFonts.best.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Заново',
            icon: const AppIcon(AppIcons.restart, size: 22),
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
          SecondaryButton(
            label: 'Продолжить за рекламу',
            icon: const AppIcon(AppIcons.adPlay, size: 20),
            height: 48,
            outlined: true,
            onPressed: onContinueAd,
          ),
        ],
      ),
    );
  }
}
