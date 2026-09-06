import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';

class GameHud extends StatelessWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context) {
    final GameCubit cubit = context.read<GameCubit>();
    final GameState state = context.watch<GameCubit>().state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${state.score}', style: AppFonts.score),
                const SizedBox(height: 5),
                Text('РЕКОРД ${state.bestScore}', style: AppFonts.best),
              ],
            ),
          ),
          // Следующий шар.
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.stroke, width: 2),
            ),
            child: BallView(tier: state.next, diameter: 22),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: cubit.pause,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.stroke, width: 2),
              ),
              icon: const Icon(Icons.pause,
                  size: 20, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
