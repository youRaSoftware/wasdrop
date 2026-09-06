import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

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
    return ColoredBox(
      color: const Color(0x8C2B210E),
      child: Center(
        child: Container(
          width: 288,
          padding: const EdgeInsets.all(AppDimens.panelPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.panelRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Text(
                  'ИГРА ОКОНЧЕНА',
                  style: AppFonts.overlayTitle.copyWith(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '$score',
                  style: AppFonts.score.copyWith(fontSize: 44),
                ),
              ),
              if (isNewRecord) ...<Widget>[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[AppColors.goldTop, AppColors.gold],
                      ),
                    ),
                    child: Text(
                      '🏆 НОВЫЙ РЕКОРД',
                      style: AppFonts.button.copyWith(
                          fontSize: 13, color: AppColors.goldText),
                    ),
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'рекорд — $bestScore',
                    style:
                        AppFonts.best.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(label: 'Заново', onPressed: onRestart),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onMenu,
                child: Text(
                  'В меню',
                  style: AppFonts.button
                      .copyWith(color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
              const Divider(color: AppColors.stroke),
              OutlinedButton(
                onPressed: onContinueAd,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.stroke, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  '▶ Продолжить за рекламу',
                  style: AppFonts.button.copyWith(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
