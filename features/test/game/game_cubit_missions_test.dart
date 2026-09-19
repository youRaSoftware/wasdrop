// Заказы в кубите: раздача трёх при старте, выполнение по слиянию даёт
// награду (очки, заряд), звезду в прогресс и замену; снимок хранит заказы.
import 'dart:math';

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:features/game/cubit/game_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _StatsRepository implements StatsRepository {
  GameStatsModel stats = const GameStatsModel.empty();
  @override
  Future<GameStatsModel> getStats() async => stats;
  @override
  Future<void> saveStats(GameStatsModel value) async => stats = value;
}

class _GameRepository implements GameRepository {
  GameSnapshot? snapshot;
  @override
  Future<GameSnapshot?> load({GameMode mode = GameMode.classic}) async =>
      snapshot;
  @override
  Future<void> save(GameSnapshot value,
          {GameMode mode = GameMode.classic}) async =>
      snapshot = value;
  @override
  Future<void> clear({GameMode mode = GameMode.classic}) async =>
      snapshot = null;
}

class _SettingsRepository implements SettingsRepository {
  @override
  Future<SettingsModel> getSettings() async => const SettingsModel.empty();
  @override
  Future<void> saveSettings(SettingsModel settings) async {}
}

class _PremiumRepository implements PremiumRepository {
  @override
  Future<bool> isPremium() async => false;
  @override
  Future<void> setPremium(bool value) async {}
}

class _ProgressRepository implements ProgressRepository {
  ProgressModel progress = const ProgressModel.empty();
  int saves = 0;
  @override
  Future<ProgressModel> getProgress() async => progress;
  @override
  Future<void> saveProgress(ProgressModel value) async {
    progress = value;
    saves++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  late _ProgressRepository progress;
  late _GameRepository games;

  GameCubit make({GameSnapshot? resume, int seed = 1}) {
    final SettingsService settings = SettingsService(_SettingsRepository());
    final AudioService audio = AudioService(settings);
    final PremiumService premium = PremiumService(_PremiumRepository());
    return GameCubit(
      statsRepository: _StatsRepository(),
      gameRepository: games,
      audio: audio,
      premium: premium,
      ads: AdsService(AppConfig.fromFlavor(Flavor.dev), premium, audio),
      progressRepository: progress,
      gameCenter: GameCenterService(),
      resumeFrom: resume,
      missionRandom: Random(seed),
    );
  }

  setUp(() {
    progress = _ProgressRepository();
    games = _GameRepository();
  });

  test('старт: три заказа; getFruit выполняется слиянием и заменяется',
      () async {
    final GameCubit cubit = make();
    await pumpEventQueue();
    expect(cubit.state.missions, hasLength(3));
    // Найдём заказ «получи фрукт» (на уровне 0 он в пуле) — если его нет,
    // выполним заказ на счёт.
    final Mission? get = cubit.state.missions
        .where((Mission m) => m.type == MissionType.getFruit)
        .firstOrNull;
    final Mission target = get ??
        cubit.state.missions
            .firstWhere((Mission m) => m.type == MissionType.score);
    final int shakesBefore = cubit.state.shakes;
    final int scoreBefore = cubit.state.score;
    if (target.type == MissionType.getFruit) {
      // Слияние тира ниже цели даёт фрукт-цель.
      cubit.onMerge(BallTier.values[target.tier!.index - 1]);
    } else {
      final BallTier big = BallTier.t9; // 512 очков за слияние
      while (cubit.state.score < target.target) {
        cubit.onMerge(big);
      }
    }
    expect(cubit.state.completedCount, 1);
    expect(cubit.state.completedMission!.id, target.id);
    expect(cubit.state.starsEarned, 1);
    expect(cubit.state.missions, hasLength(3));
    expect(cubit.state.missions.map((Mission m) => m.id),
        isNot(contains(target.id)));
    expect(cubit.state.score,
        greaterThanOrEqualTo(scoreBefore + target.reward.points));
    if (target.reward.bonus == Bonus.shake) {
      expect(cubit.state.shakes, shakesBefore + 1);
    }
    await pumpEventQueue();
    expect(progress.progress.stars, 1);
    expect(progress.progress.missionsDone, 1);
    expect(cubit.totalStars, 1);
    await cubit.close();
  });

  test('снимок хранит заказы, восстановление их не раздаёт заново', () async {
    final GameCubit cubit = make();
    await pumpEventQueue();
    await cubit.saveSnapshot(const <BallSnapshot>[], jarId: 'classic');
    // Пустая партия снимок стирает — дадим очки.
    cubit.onMerge(BallTier.t1);
    await cubit.saveSnapshot(const <BallSnapshot>[], jarId: 'classic');
    final GameSnapshot saved = games.snapshot!;
    expect(saved.missions, cubit.state.missions);
    await cubit.close();

    final GameCubit resumed = make(resume: saved, seed: 99);
    await pumpEventQueue();
    expect(resumed.state.missions, saved.missions);
    expect(resumed.state.status, GameStatus.paused);
    await resumed.close();
  });

  test('экран заказов: из игры и из паузы возвращает туда, откуда открыт',
      () async {
    final GameCubit cubit = make();
    await pumpEventQueue();
    cubit.showMissions();
    expect(cubit.state.status, GameStatus.paused);
    expect(cubit.state.missionsOpen, isTrue);
    cubit.hideMissions();
    expect(cubit.state.status, GameStatus.playing);
    cubit.pause();
    cubit.showMissions();
    cubit.hideMissions();
    expect(cubit.state.status, GameStatus.paused);
    expect(cubit.state.missionsOpen, isFalse);
    await cubit.close();
  });

  test('restart раздаёт новые заказы и сбрасывает звёзды партии', () async {
    final GameCubit cubit = make();
    await pumpEventQueue();
    final List<Mission> first = cubit.state.missions;
    cubit.restart();
    expect(cubit.state.missions, hasLength(3));
    expect(
        cubit.state.missions
            .map((Mission m) => m.id)
            .toSet()
            .intersection(first.map((Mission m) => m.id).toSet()),
        isEmpty);
    expect(cubit.state.starsEarned, 0);
    await cubit.close();
  });
}
