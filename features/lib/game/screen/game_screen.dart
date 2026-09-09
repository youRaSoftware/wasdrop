import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import 'game_form.dart';

/// Игровой экран. [resumeFrom] — сохранённая партия из меню («Продолжить»):
/// счёт и очередь идут в кубит, шары — в движок.
class GameScreen extends StatelessWidget {
  final GameSnapshot? resumeFrom;

  const GameScreen({this.resumeFrom, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GameCubit>(
      lazy: false,
      create: (BuildContext context) => GameCubit(
        statsRepository: appLocator<StatsRepository>(),
        gameRepository: appLocator<GameRepository>(),
        audio: appLocator<AudioService>(),
        resumeFrom: resumeFrom,
      ),
      child: GameForm(resumeFrom: resumeFrom),
    );
  }
}
