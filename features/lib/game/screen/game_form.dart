import 'dart:async';

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import '../engine/wasdrop_game.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/pause_overlay.dart';

/// Игровая форма: HUD, стакан с движком, оверлеи паузы и проигрыша.
/// Сохраняет партию (`GameCubit.saveSnapshot`) при уходе приложения в фон,
/// раз в [autosaveInterval] и перед выходом в меню.
class GameForm extends StatefulWidget {
  static const Duration autosaveInterval = Duration(seconds: 2);

  final GameSnapshot? resumeFrom;

  const GameForm({this.resumeFrom, super.key});

  @override
  State<GameForm> createState() => _GameFormState();
}

class _GameFormState extends State<GameForm> with WidgetsBindingObserver {
  late final GameCubit _cubit = context.read<GameCubit>();
  late final WasDropGame _game = WasDropGame(
    cubit: _cubit,
    settings: appLocator<SettingsService>().settings,
    resumeFrom: widget.resumeFrom,
  );
  Timer? _autosave;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autosave = Timer.periodic(GameForm.autosaveInterval, (_) => _save());
  }

  @override
  void dispose() {
    _autosave?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _save();
    }
  }

  void _save() {
    if (!_game.isLoaded || _cubit.isClosed) return;
    unawaited(_cubit.saveSnapshot(_game.captureBalls()));
  }

  @override
  Widget build(BuildContext context) {
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
                onResume: _cubit.resume,
                onRestart: () {
                  _cubit.restart();
                  _game.reset();
                },
                onMenu: () {
                  _save();
                  context.goNamed('menu');
                },
              ),
            if (state.status == GameStatus.gameOver)
              GameOverOverlay(
                score: state.score,
                bestScore: state.bestScore,
                isNewRecord: state.isNewRecord,
                onRestart: () {
                  _cubit.restart();
                  _game.reset();
                },
                onMenu: () => context.goNamed('menu'),
                onContinueAd: _cubit.continueAfterAd,
              ),
          ],
        ),
      ),
    );
  }
}
