import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import '../engine/fruit_assets.dart';

class GameHud extends StatelessWidget {
  static const Key pauseButtonKey = Key('hud_pause');

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
                  'РЕКОРД ${state.bestScore}',
                  style: AppFonts.best.copyWith(color: theme.hudTextSecondary),
                ),
              ],
            ),
          ),
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
