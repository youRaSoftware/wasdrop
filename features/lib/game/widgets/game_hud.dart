import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import '../engine/fruit_assets.dart';

class GameHud extends StatelessWidget {
  static const Key pauseButtonKey = Key('hud_pause');
  static const Key timerKey = Key('hud_timer');

  static String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  const GameHud({super.key});

  @override
  Widget build(BuildContext context) {
    final GameCubit cubit = context.read<GameCubit>();
    final GameState state = context.watch<GameCubit>().state;
    final GameTheme theme = AppThemeScope.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${state.score}',
                  style: AppFonts.score.copyWith(color: theme.hudText),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(
                    LocaleKeys.hud_best,
                    namedArgs: <String, String>{'score': '${state.bestScore}'},
                  ),
                  style: AppFonts.best.copyWith(color: theme.hudTextSecondary),
                ),
              ],
            ),
          ),
          if (state.mode == GameMode.timed && state.secondsLeft != null)
            _ModeChip(
              key: timerKey,
              text: _clock(state.secondsLeft!),
              alert: state.secondsLeft! <= 10,
            )
          else if (state.mode == GameMode.daily)
            _ModeChip(text: context.tr(LocaleKeys.hud_daily)),
          if (state.mode != GameMode.classic) const SizedBox(width: 8),
          // Следующий шар.
          Container(
            width: AppDimens.minTapTarget,
            height: AppDimens.minTapTarget,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.stroke, width: 2),
            ),
            child: BallView(
              tier: state.next,
              diameter: 26,
              image: FruitAssets.idle(state.next),
            ),
          ),
          const SizedBox(width: 8),
          IconCircleButton(
            key: pauseButtonKey,
            size: AppDimens.minTapTarget,
            onPressed: cubit.pause,
            child: const AppIcon(AppIcons.pause, size: 22),
          ),
        ],
      ),
    );
  }
}

/// Пилюля режима в HUD: таймер «На время» (красный на последних секундах)
/// или метка ежедневного вызова.
class _ModeChip extends StatelessWidget {
  final String text;
  final bool alert;

  const _ModeChip({required this.text, this.alert = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.minTapTarget,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.minTapTarget / 2),
        border: Border.all(
          color: alert ? AppColors.alert : AppColors.stroke,
          width: 2,
        ),
      ),
      child: Text(
        text,
        style: AppFonts.button.copyWith(
          fontSize: 15,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          color: alert ? AppColors.alert : AppColors.textPrimary,
        ),
      ),
    );
  }
}
