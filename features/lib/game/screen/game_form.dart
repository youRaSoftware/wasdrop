import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import '../engine/wasdrop_game.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/pause_overlay.dart';

class GameForm extends StatefulWidget {
  const GameForm({super.key});

  @override
  State<GameForm> createState() => _GameFormState();
}

class _GameFormState extends State<GameForm> {
  late final WasDropGame _game;

  @override
  void initState() {
    super.initState();
    _game = WasDropGame(cubit: context.read<GameCubit>());
  }

  @override
  Widget build(BuildContext context) {
    final GameCubit cubit = context.read<GameCubit>();
    final GameState state = context.watch<GameCubit>().state;

    _game.paused = state.status != GameStatus.playing;

    return AppScaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                const GameHud(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(25, 8, 25, 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.jar,
                        border: const Border(
                          left: BorderSide(
                              color: AppColors.jarWall,
                              width: AppDimens.jarWallWidth),
                          right: BorderSide(
                              color: AppColors.jarWall,
                              width: AppDimens.jarWallWidth),
                          bottom: BorderSide(
                              color: AppColors.jarWall,
                              width: AppDimens.jarWallWidth),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(26),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        child: GameWidget<WasDropGame>(game: _game),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (state.status == GameStatus.paused)
              PauseOverlay(
                onResume: cubit.resume,
                onRestart: () {
                  cubit.restart();
                  _game.reset();
                },
                onMenu: () => context.goNamed('menu'),
              ),
            if (state.status == GameStatus.gameOver)
              GameOverOverlay(
                score: state.score,
                bestScore: state.bestScore,
                isNewRecord: state.isNewRecord,
                onRestart: () {
                  cubit.restart();
                  _game.reset();
                },
                onMenu: () => context.goNamed('menu'),
                onContinueAd: cubit.continueAfterAd,
              ),
          ],
        ),
      ),
    );
  }
}
