// Регрессия: «Продолжить» открывает партию в паузе, и GameWidget не делает
// первый update(0). Без принудительной обработки очередей Flame шары
// восстановленной партии оставались несмонтированными: «Заново» из паузы
// удаляло компоненты без onRemove (тела Box2D оставались в мире невидимыми,
// новые фрукты ложились на них в воздухе), а captureBalls() не видел шаров.
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:features/game/engine/ball_body.dart';
import 'package:features/game/engine/wasdrop_game.dart';
import 'package:features/game/cubit/game_cubit.dart';
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

class _ProgressRepository implements ProgressRepository {
  ProgressModel progress = const ProgressModel.empty();

  @override
  Future<ProgressModel> getProgress() async => progress;

  @override
  Future<void> saveProgress(ProgressModel value) async => progress = value;
}

class _PremiumRepository implements PremiumRepository {
  @override
  Future<bool> isPremium() async => false;

  @override
  Future<void> setPremium(bool value) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // PremiumService берёт InAppPurchase.instance, а под Android-платформой
    // теста плагин не регистрируется.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('«Заново» из паузы восстановленной партии не оставляет невидимых тел',
      () async {
    final SettingsService settings = SettingsService(_SettingsRepository());
    final AudioService audio = AudioService(settings);
    final PremiumService premium = PremiumService(_PremiumRepository());
    final AdsService ads =
        AdsService(AppConfig.fromFlavor(Flavor.dev), premium, audio);
    final _GameRepository games = _GameRepository();

    // Куча из двух фруктов на дне.
    final GameSnapshot snapshot = GameSnapshot(
      score: 40,
      current: BallTier.t1,
      next: BallTier.t2,
      merges: 3,
      bestTier: BallTier.t3,
      shakes: 3,
      bombs: 1,
      upgrades: 1,
      balls: <BallSnapshot>[
        BallSnapshot(
          tier: BallTier.t3,
          x: 180,
          bottomOffset: AppDimens.ballRadii[2],
          angle: 0,
          vx: 0,
          vy: 0,
        ),
        BallSnapshot(
          tier: BallTier.t2,
          x: 90,
          bottomOffset: AppDimens.ballRadii[1],
          angle: 0,
          vx: 0,
          vy: 0,
        ),
      ],
      savedAt: DateTime(2026, 9, 14),
    );
    final GameCubit cubit = GameCubit(
      statsRepository: _StatsRepository(),
      gameRepository: games,
      audio: audio,
      premium: premium,
      ads: ads,
      progressRepository: _ProgressRepository(),
      gameCenter: GameCenterService(),
      resumeFrom: snapshot,
    );
    expect(cubit.state.status, GameStatus.paused);

    final WasDropGame game = WasDropGame(
      cubit: cubit,
      settings: settings.settings,
      resumeFrom: snapshot,
    );
    // Как GameForm.build при статусе paused — до появления GameWidget.
    game.paused = true;
    game.onGameResize(Vector2(360, 640));
    // Как GameWidget: load, mount и никакого update(0) у паузного движка.
    // ignore: invalid_use_of_internal_member
    await game.load();
    // ignore: invalid_use_of_internal_member
    game.mount();
    await pumpEventQueue();

    final List<BallBody> restored =
        game.world.children.whereType<BallBody>().toList();
    expect(restored, hasLength(2));
    expect(restored.every((BallBody b) => b.isMounted), isTrue,
        reason: 'шары паузной партии должны быть смонтированы');
    expect(game.captureBalls(), hasLength(2),
        reason: 'автосейв в паузе не должен терять фрукты');

    // «Заново» из оверлея паузы (PauseOverlay.onRestart).
    cubit.restart();
    game.reset();
    game.paused = false;
    game.update(0);
    await pumpEventQueue();
    expect(game.world.children.whereType<BallBody>(), isEmpty);
    expect(restored.every((BallBody b) => !b.body.isValid), isTrue,
        reason: 'тела старой кучи должны быть уничтожены');

    // Новый фрукт долетает до дна, а не зависает на невидимой куче.
    final BallBody dropped = BallBody(
      tier: BallTier.t1,
      initialPosition: Vector2(180, WasDropGame.spawnY),
      onMerge: game.merge,
    );
    game.world.add(dropped);
    for (int i = 0; i < 180; i++) {
      game.update(1 / 60);
      await Future<void>.delayed(Duration.zero);
    }
    expect(
      dropped.body.position.y,
      closeTo(game.worldHeight - AppDimens.ballRadii[0], 2),
    );

    game.onRemove();
    await cubit.close();
  });
}
