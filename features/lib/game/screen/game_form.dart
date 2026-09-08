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
    _game = WasDropGame(
      cubit: context.read<GameCubit>(),
      settings: appLocator<SettingsService>().settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameCubit cubit = context.read<GameCubit>();
    final GameState state = context.watch<GameCubit>().state;
    final GameTheme theme = AppThemeScope.of(context);

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
                      // Заливка и стенки — из темы; движок фон не рисует,
                      // так что полупрозрачный стакан просвечивает.
                      decoration: BoxDecoration(
                        color: theme.jarFill,
                        border: Border(
                          left: BorderSide(
                              color: theme.jarWall,
                              width: AppDimens.jarWallWidth),
                          right: BorderSide(
                              color: theme.jarWall,
                              width: AppDimens.jarWallWidth),
                          bottom: BorderSide(
                              color: theme.jarWall,
                              width: AppDimens.jarWallWidth),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppDimens.jarCornerRadius),
                        ),
                      ),
                      // Холст лежит внутри обводки: физическое дно = верх
                      // стенки, иначе нижние 5 px фруктов прячутся под ней.
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppDimens.jarWallWidth,
                          right: AppDimens.jarWallWidth,
                          bottom: AppDimens.jarWallWidth,
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(
                              AppDimens.jarInnerCornerRadius,
                            ),
                          ),
                          child: GameWidget<WasDropGame>(game: _game),
                        ),
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
