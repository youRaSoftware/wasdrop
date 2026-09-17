import 'package:equatable/equatable.dart';

import '../enums/game_mode.dart';
import 'game_snapshot.dart';

/// Параметры запуска игрового экрана (`extra` роута `/game`): режим и,
/// для классики, сохранённая партия.
class GameLaunch extends Equatable {
  final GameMode mode;
  final GameSnapshot? resumeFrom;

  const GameLaunch({this.mode = GameMode.classic, this.resumeFrom});

  const GameLaunch.resume(GameSnapshot snapshot)
      : this(mode: GameMode.classic, resumeFrom: snapshot);

  @override
  List<Object?> get props => <Object?>[mode, resumeFrom];
}

/// Seed ежедневного вызова: дата UTC как yyyyMMdd.
int dailySeed([DateTime? now]) {
  final DateTime d = (now ?? DateTime.now()).toUtc();
  return d.year * 10000 + d.month * 100 + d.day;
}
