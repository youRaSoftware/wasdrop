import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import 'game_form.dart';

/// Игровой экран. [launch] — режим и (для классики) сохранённая партия из
/// меню («Продолжить»): счёт и очередь идут в кубит, шары — в движок.
class GameScreen extends StatelessWidget {
  final GameLaunch launch;

  const GameScreen({this.launch = const GameLaunch(), super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GameCubit>(
      lazy: false,
      create: (BuildContext context) => GameCubit(
        statsRepository: appLocator<StatsRepository>(),
        gameRepository: appLocator<GameRepository>(),
        audio: appLocator<AudioService>(),
        premium: appLocator<PremiumService>(),
        ads: appLocator<AdsService>(),
        progressRepository: appLocator<ProgressRepository>(),
        gameCenter: appLocator<GameCenterService>(),
        mode: launch.mode,
        resumeFrom: launch.resumeFrom,
      ),
      child: GameForm(resumeFrom: launch.resumeFrom),
    );
  }
}
