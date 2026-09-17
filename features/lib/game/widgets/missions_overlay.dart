import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'mission_text.dart';

/// Экран заказов поверх игры (из панели и из паузы): три текущих заказа с
/// полным текстом и наградой, счётчики звёзд и выполненных.
class MissionsOverlay extends StatelessWidget {
  static const Key closeKey = Key('missions_close');

  final List<Mission> missions;
  final int stars;
  final int done;
  final VoidCallback onClose;

  const MissionsOverlay({
    required this.missions,
    required this.stars,
    required this.done,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle meta = AppFonts.best.copyWith(
      color: AppColors.textSecondary,
      letterSpacing: 0,
    );
    return AppOverlay(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Text(
              context.tr(LocaleKeys.missions_title),
              style: AppFonts.overlayTitle,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const AppIcon(AppIcons.star, size: 16),
              const SizedBox(width: 4),
              Text(
                context.tr(
                  LocaleKeys.missions_stars,
                  namedArgs: <String, String>{'n': '$stars'},
                ),
                style: meta,
              ),
              const SizedBox(width: 14),
              Text(
                context.tr(
                  LocaleKeys.missions_doneTotal,
                  namedArgs: <String, String>{'n': '$done'},
                ),
                style: meta,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final Mission m in missions) ...<Widget>[
            _MissionRow(mission: m),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          PrimaryButton(
            key: closeKey,
            label: context.tr(LocaleKeys.pause_resume),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final Mission mission;

  const _MissionRow({required this.mission});

  @override
  Widget build(BuildContext context) {
    final String counter = missionCounter(context, mission);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          missionIcon(mission, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  missionText(context, mission),
                  style: AppFonts.button.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      '${context.tr(LocaleKeys.missions_reward)}: ',
                      style: AppFonts.best.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                    missionRewardChip(mission.reward, iconSize: 14),
                    if (counter.isNotEmpty) ...<Widget>[
                      const Spacer(),
                      Text(
                        counter,
                        style: AppFonts.best.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
