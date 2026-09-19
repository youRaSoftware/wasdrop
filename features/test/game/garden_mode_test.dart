// «Сад чудес»: особые фрукты в очереди и их поведение в движке —
// Радужка сливается с любым, Льдинка замораживает, Пузырик всплывает и
// лопается, Гнилушка гибнет от слияния рядом; снимок режима отдельный.
import 'dart:math';

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:features/game/cubit/game_cubit.dart';
import 'package:features/game/engine/ball_body.dart';
import 'package:features/game/engine/wasdrop_game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
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
  final Map<GameMode, GameSnapshot> saved = <GameMode, GameSnapshot>{};
  @override
  Future<GameSnapshot?> load({GameMode mode = GameMode.classic}) async =>
      saved[mode];
  @override
  Future<void> save(GameSnapshot value,
          {GameMode mode = GameMode.classic}) async =>
      saved[mode] = value;
  @override
  Future<void> clear({GameMode mode = GameMode.classic}) async =>
      saved.remove(mode);
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
  ProgressModel progress =
      const ProgressModel.empty().copyWith(onboardingDone: true);
  @override
  Future<ProgressModel> getProgress() async => progress;
  @override
  Future<void> saveProgress(ProgressModel value) async => progress = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  late _GameRepository games;
  late _ProgressRepository progress;
  late SettingsService settings;

  GameCubit makeCubit({GameSnapshot? resume}) {
    settings = SettingsService(_SettingsRepository());
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
      mode: GameMode.garden,
      resumeFrom: resume,
      missionRandom: Random(4),
    );
  }

  Future<WasDropGame> makeGame(GameCubit cubit) async {
    final WasDropGame game = WasDropGame(
      cubit: cubit,
      settings: settings.settings,
    );
    game.onGameResize(Vector2(360, 640));
    // ignore: invalid_use_of_internal_member
    await game.load();
    // ignore: invalid_use_of_internal_member
    game.mount();
    game.update(0);
    await pumpEventQueue();
    return game;
  }

  Future<void> run(WasDropGame game, double seconds) async {
    for (int i = 0; i < seconds * 60; i++) {
      game.update(1 / 60);
      await Future<void>.delayed(Duration.zero);
    }
  }

  List<BallBody> balls(WasDropGame g) =>
      g.world.children.whereType<BallBody>().toList();

  setUp(() {
    games = _GameRepository();
    progress = _ProgressRepository();
  });

  test('очередь: особые появляются, но не два сразу; справка при первом входе',
      () async {
    final GameCubit cubit = makeCubit();
    await pumpEventQueue();
    expect(cubit.state.gardenIntroOpen, isTrue);
    await cubit.finishGardenIntro();
    expect(progress.progress.gardenIntroDone, isTrue);
    final Set<SpecialKind> seen = <SpecialKind>{};
    for (int i = 0; i < 80; i++) {
      final SpecialKind? c = cubit.state.currentSpecial;
      final SpecialKind? n = cubit.state.nextSpecial;
      expect(c == null || n == null, isTrue, reason: 'не два особых сразу');
      if (c != null) seen.add(c);
      cubit.onDropped();
    }
    expect(seen, containsAll(SpecialKind.values),
        reason: 'за 80 бросков все четыре особых побывали в очереди');
    await cubit.close();
  });

  test('радужка сливается с любым фруктом и даёт следующий тир', () async {
    final GameCubit cubit = makeCubit();
    await pumpEventQueue();
    await cubit.finishGardenIntro();
    final WasDropGame game = await makeGame(cubit);
    final double floor = game.worldHeight;
    final BallBody apple = BallBody(
      tier: BallTier.t5,
      initialPosition: Vector2(180, floor - AppDimens.ballRadii[4]),
      onMerge: game.merge,
    );
    game.world.add(apple);
    await run(game, 1);
    final BallBody rainbow = BallBody(
      tier: BallTier.t1,
      initialPosition: Vector2(180, 60),
      onMerge: game.merge,
      special: SpecialKind.rainbow,
      onSpecial: game.handleSpecial,
    );
    game.world.add(rainbow);
    await run(game, 3);
    final List<BallBody> left = balls(game);
    expect(left.where((BallBody b) => b.isSpecial), isEmpty);
    expect(left.map((BallBody b) => b.tier), contains(BallTier.t6),
        reason: 'радужка + яблоко → киви');
    expect(cubit.state.score, BallTier.t5.mergeScore);
    game.onRemove();
    await cubit.close();
  });

  test('льдинка замораживает фрукт: соседи одного тира не сливаются 3 броска',
      () async {
    final GameCubit cubit = makeCubit();
    await pumpEventQueue();
    await cubit.finishGardenIntro();
    final WasDropGame game = await makeGame(cubit);
    final double floor = game.worldHeight;
    final double r = AppDimens.ballRadii[1];
    final BallBody a = BallBody(
      tier: BallTier.t2,
      initialPosition: Vector2(120, floor - r),
      onMerge: game.merge,
    );
    game.world.add(a);
    await run(game, 1);
    final BallBody ice = BallBody(
      tier: BallTier.t1,
      initialPosition: Vector2(120, 60),
      onMerge: game.merge,
      special: SpecialKind.ice,
      onSpecial: game.handleSpecial,
    );
    game.world.add(ice);
    await run(game, 3);
    expect(a.frozen, SpecialKind.frozenDrops);
    expect(balls(game).where((BallBody b) => b.isSpecial), isEmpty,
        reason: 'льдинка растаяла');
    // Такой же фрукт рядом — не сливается, пока лёд держится.
    final BallBody b = BallBody(
      tier: BallTier.t2,
      initialPosition: Vector2(120 + 2 * r + 4, 60),
      onMerge: game.merge,
    );
    game.world.add(b);
    await run(game, 3);
    expect(balls(game).where((BallBody x) => x.tier == BallTier.t2).length, 2);
    expect(cubit.state.merges, 0);
    game.onRemove();
    await cubit.close();
  });

  test('пузырик уносит фрукт, на который упал; на дне просто лопается',
      () async {
    final GameCubit cubit = makeCubit();
    await pumpEventQueue();
    await cubit.finishGardenIntro();
    final WasDropGame game = await makeGame(cubit);
    final double floor = game.worldHeight;
    final BallBody apple = BallBody(
      tier: BallTier.t5,
      initialPosition: Vector2(120, floor - AppDimens.ballRadii[4]),
      onMerge: game.merge,
    );
    game.world.add(apple);
    await run(game, 1);
    game.world.add(BallBody(
      tier: BallTier.t1,
      initialPosition: Vector2(120, 60),
      onMerge: game.merge,
      special: SpecialKind.bubble,
      onSpecial: game.handleSpecial,
    ));
    await run(game, 3);
    expect(balls(game), isEmpty, reason: 'яблоко унесено вместе с пузыриком');
    expect(cubit.state.score, 0, reason: 'очков за это нет');
    expect(cubit.state.merges, 0);

    game.world.add(BallBody(
      tier: BallTier.t1,
      initialPosition: Vector2(250, 60),
      onMerge: game.merge,
      special: SpecialKind.bubble,
      onSpecial: game.handleSpecial,
    ));
    await run(game, 3);
    expect(balls(game), isEmpty, reason: 'на дне пузырик лопнул сам');
    game.onRemove();
    await cubit.close();
  });

  test('гнилушка гибнет рядом со слиянием', () async {
    final GameCubit cubit = makeCubit();
    await pumpEventQueue();
    await cubit.finishGardenIntro();
    final WasDropGame game = await makeGame(cubit);
    final double floor = game.worldHeight;
    final BallBody rotten = BallBody(
      tier: BallTier.t1,
      initialPosition: Vector2(180, floor - SpecialKind.rotten.radius),
      onMerge: game.merge,
      special: SpecialKind.rotten,
      onSpecial: game.handleSpecial,
    );
    game.world.add(rotten);
    await run(game, 1);
    final int before = cubit.state.score;
    final double r1 = AppDimens.ballRadii[0];
    game.world.add(BallBody(
      tier: BallTier.t1,
      initialPosition:
          Vector2(180 - SpecialKind.rotten.radius - r1 - 1, floor - r1),
      onMerge: game.merge,
    ));
    game.world.add(BallBody(
      tier: BallTier.t1,
      initialPosition:
          Vector2(180 - SpecialKind.rotten.radius - 3 * r1 - 4, floor - r1),
      initialVelocity: Vector2(200, 0),
      onMerge: game.merge,
    ));
    await run(game, 3);
    expect(balls(game).where((BallBody b) => b.special == SpecialKind.rotten),
        isEmpty,
        reason: 'слияние рядом уничтожило гнилушку');
    expect(cubit.state.score,
        before + BallTier.t1.mergeScore + SpecialKind.rottenReward);
    game.onRemove();
    await cubit.close();
  });

  test('оттаявший фрукт сливается с таким же соседом сам', () async {
    final GameCubit cubit = makeCubit();
    await pumpEventQueue();
    await cubit.finishGardenIntro();
    final WasDropGame game = await makeGame(cubit);
    final double floor = game.worldHeight;
    final double r = AppDimens.ballRadii[6];
    final BallBody a = BallBody(
      tier: BallTier.t7,
      initialPosition: Vector2(120, floor - r),
      onMerge: game.merge,
      frozen: SpecialKind.frozenDrops,
    );
    final BallBody b = BallBody(
      tier: BallTier.t7,
      initialPosition: Vector2(120 + 2 * r + 2, floor - r),
      onMerge: game.merge,
    );
    game.world.add(a);
    game.world.add(b);
    await run(game, 2);
    expect(balls(game).length, 2, reason: 'под льдом не сливаются');
    for (int i = 0; i < SpecialKind.frozenDrops; i++) {
      game.thawTick();
      await run(game, 0.5);
    }
    await run(game, 1);
    expect(balls(game).map((BallBody x) => x.tier), contains(BallTier.t8),
        reason: 'после оттаивания слились в виноград');
    game.onRemove();
    await cubit.close();
  });

  test('снимок сада хранится отдельно от классики, с особыми и льдом',
      () async {
    final GameCubit cubit = makeCubit();
    await pumpEventQueue();
    await cubit.finishGardenIntro();
    cubit.onMerge(BallTier.t1);
    await cubit.saveSnapshot(
      const <BallSnapshot>[
        BallSnapshot(
          tier: BallTier.t2,
          x: 100,
          bottomOffset: 19,
          angle: 0,
          vx: 0,
          vy: 0,
          frozen: 2,
        ),
        BallSnapshot(
          tier: BallTier.t1,
          x: 200,
          bottomOffset: 34,
          angle: 0,
          vx: 0,
          vy: 0,
          special: SpecialKind.rotten,
        ),
      ],
      jarId: 'classic',
    );
    expect(games.saved[GameMode.classic], isNull);
    final GameSnapshot saved = games.saved[GameMode.garden]!;
    expect(saved.balls[0].frozen, 2);
    expect(saved.balls[1].special, SpecialKind.rotten);
    await cubit.close();

    final GameCubit resumed = makeCubit(resume: saved);
    await pumpEventQueue();
    expect(resumed.state.mode, GameMode.garden);
    expect(resumed.state.gardenIntroOpen, isFalse);
    await resumed.close();
  });
}
