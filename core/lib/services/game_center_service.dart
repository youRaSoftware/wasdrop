import 'dart:async';
import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

/// Лидерборды и достижения Game Center (`games_services`, только iOS).
///
/// Тихий вход при старте ([init]); если игрок не вошёл в Game Center,
/// iOS сама покажет системный экран входа. Без входа кнопки «Рекорды» в
/// меню и на экране проигрыша скрыты ([isSignedIn]), а отправка счёта и
/// достижений молча пропускается. Ошибки платформы не роняют игру. В
/// dev-флейворе (`com.wasdrop.dev`) лидербордов в App Store Connect нет —
/// вход работает, отправка падает в лог.
class GameCenterService {
  /// Идентификаторы лидербордов в App Store Connect (по режиму).
  static const Map<GameMode, String> leaderboardIds = <GameMode, String>{
    GameMode.classic: 'com.wasdrop.leaderboard.classic',
    GameMode.timed: 'com.wasdrop.leaderboard.timed',
    GameMode.daily: 'com.wasdrop.leaderboard.daily',
    GameMode.garden: 'com.wasdrop.leaderboard.garden',
  };

  final ValueNotifier<bool> isSignedIn = ValueNotifier<bool>(false);

  /// Достижения, уже отправленные в этой сессии (повторно не шлём).
  final Set<GameAchievement> _unlocked = <GameAchievement>{};

  bool get available => Platform.isIOS;

  /// Вход в фоне, запуск не ждёт.
  Future<void> init() async {
    if (!available) return;
    try {
      await GameAuth.signIn();
      isSignedIn.value = await GameAuth.isSignedIn;
    } catch (error) {
      debugPrint('GameCenterService: sign-in failed: $error');
      isSignedIn.value = false;
    }
  }

  /// Счёт партии в лидерборд режима (Game Center хранит лучший).
  Future<void> submitScore(GameMode mode, int score) async {
    if (!isSignedIn.value || score <= 0) return;
    try {
      await Leaderboards.submitScore(
        score: Score(iOSLeaderboardID: leaderboardIds[mode]!, value: score),
      );
    } catch (error) {
      debugPrint('GameCenterService: submitScore failed: $error');
    }
  }

  Future<void> unlock(Iterable<GameAchievement> achievements) async {
    if (!isSignedIn.value) return;
    for (final GameAchievement a in achievements) {
      if (!_unlocked.add(a)) continue;
      try {
        await Achievements.unlock(
          achievement: Achievement(iOSID: a.id, percentComplete: 100),
        );
      } catch (error) {
        _unlocked.remove(a);
        debugPrint('GameCenterService: unlock ${a.id} failed: $error');
      }
    }
  }

  /// Системный экран лидербордов ([mode] — сразу нужный, иначе список).
  Future<void> showLeaderboards([GameMode? mode]) async {
    if (!isSignedIn.value) return;
    try {
      await Leaderboards.showLeaderboards(
        iOSLeaderboardID: mode == null ? '' : leaderboardIds[mode]!,
      );
    } catch (error) {
      debugPrint('GameCenterService: showLeaderboards failed: $error');
    }
  }

  Future<void> showAchievements() async {
    if (!isSignedIn.value) return;
    try {
      await Achievements.showAchievements();
    } catch (error) {
      debugPrint('GameCenterService: showAchievements failed: $error');
    }
  }
}
