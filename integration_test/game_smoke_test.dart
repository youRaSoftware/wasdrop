// Smoke test for the real app on a device / simulator:
//
//   flutter test integration_test -d <deviceId> --flavor dev --dart-define=environment=dev
//
// Covers: menu renders → settings screen opens, a toggle persists → «ИГРАТЬ»
// opens the game → physics feel checks (rolling, touch-before-merge, merge
// momentum, fall time, no floor penetration) → taps on the jar drop balls
// that fall and rest on the physical floor, which matches the bottom of the
// jar widget.

import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:features/game/cubit/game_cubit.dart';
import 'package:features/game/engine/ball_body.dart';
import 'package:features/game/engine/merge_effects.dart';
import 'package:features/game/engine/wasdrop_game.dart';
import 'package:features/game/widgets/game_hud.dart';
import 'package:features/menu/screen/menu_screen.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wasdrop/main_common.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Real-time frames: with the default policy the engine only ticks on
  // pump(), so pump(3 s) would step the physics once with dt = 3 s.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('menu → settings → game → physics → drop',
      (WidgetTester tester) async {
    await mainCommon(Flavor.dev);
    // Release the background music player, otherwise its frame callback
    // trips the binding's leak check at the end of the test.
    addTearDown(appLocator<AudioService>().dispose);
    // No pumpAndSettle anywhere: the Flame game loop schedules frames
    // continuously, so pumpAndSettle would never return.
    await tester.pump(const Duration(seconds: 2));

    // Menu.
    expect(find.text('ИГРАТЬ'), findsOneWidget);

    // Settings: open from ⚙️, toggle «Музыка» twice (persisted both ways),
    // the fruit chain shows all 11 tiers, back returns to the menu.
    final SettingsService settings = appLocator<SettingsService>();
    final bool musicBefore = settings.value.musicOn;
    final String themeBefore = settings.value.themeId;
    await tester.tap(find.byKey(MenuScreen.settingsButtonKey));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('НАСТРОЙКИ'), findsOneWidget);
    expect(find.text('Линия прицела'), findsOneWidget);
    expect(find.byType(BallView), findsAtLeast(BallTier.values.length));
    // Theme picker: choosing «night» persists and reaches the theme scope.
    expect(find.byType(ThemePicker), findsOneWidget);
    await tester.tap(find.byKey(const Key('theme_night')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(settings.value.themeId, 'night');
    expect(
      (await appLocator<SettingsRepository>().getSettings()).themeId,
      'night',
    );
    expect(
      AppThemeScope.of(tester.element(find.text('НАСТРОЙКИ'))).id,
      'night',
    );
    await tester.tap(find.byKey(Key('theme_$themeBefore')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(settings.value.themeId, themeBefore);
    await tester.tap(find.text('Музыка'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.value.musicOn, !musicBefore);
    expect(
      (await appLocator<SettingsRepository>().getSettings()).musicOn,
      !musicBefore,
    );
    await tester.tap(find.text('Музыка'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.value.musicOn, musicBefore);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ИГРАТЬ'), findsOneWidget);

    await tester.tap(find.text('ИГРАТЬ'));
    await tester.pump(const Duration(seconds: 2));

    // Game screen with a loaded Forge2D world.
    final Finder gameFinder = find.byType(GameWidget<WasDropGame>);
    expect(gameFinder, findsOneWidget);
    final WasDropGame game =
        tester.widget<GameWidget<WasDropGame>>(gameFinder).game!;
    await tester.pump(const Duration(seconds: 1));
    expect(game.isLoaded, isTrue);
    expect(game.cubit.state.score, 0);
    // Fruit sprites: every tier has its own art (TZ_SPRITES § 5). Round
    // fruits are circles, elongated ones (grape, lemon, strawberry) get a
    // rounded polygon fitted to the silhouette.
    expect(game.fruitSprites.ownArt, containsAll(BallTier.values));
    expect(game.fruitSprites[BallTier.t1]!.isPolygon, isFalse);
    expect(game.fruitSprites[BallTier.t8]!.isPolygon, isTrue,
        reason: 'the grape is an oval');
    debugPrint(
        'SMOKE shapes: ${BallTier.values.map((BallTier t) => 't${t.number}:${game.fruitSprites[t]!.isPolygon ? 'poly' : 'circle'}').join(' ')}');
    // Adaptive physics steps: enough to keep per-step travel under the
    // speculative contact distance (6 at 60 fps).
    expect(game.lastPhysicsSteps, greaterThanOrEqualTo(4));
    debugPrint('SMOKE physics steps/frame: ${game.lastPhysicsSteps}');

    // The physics floor matches the widget's aspect ratio.
    final Size widgetSize = tester.getSize(gameFinder);
    expect(
      game.worldHeight,
      closeTo(AppDimens.worldWidth * widgetSize.height / widgetSize.width, 0.5),
    );
    final double floor = game.worldHeight;
    double r(BallTier tier) => AppDimens.ballRadii[tier.index];
    List<BallBody> balls() =>
        game.world.children.whereType<BallBody>().toList();

    // --- Rolling: a t3 resting on the shoulder of a t9 rolls off. With the
    // old rollingResistance 0.2 it froze on the spot.
    final double bigY = floor - r(BallTier.t9);
    final double smallDy =
        math.sqrt(math.pow(r(BallTier.t9) + r(BallTier.t3), 2) - 20 * 20);
    game.world.addAll(<BallBody>[
      BallBody(
        tier: BallTier.t9,
        initialPosition: Vector2(180, bigY),
        onMerge: game.merge,
      ),
      BallBody(
        tier: BallTier.t3,
        initialPosition: Vector2(200, bigY - smallDy),
        onMerge: game.merge,
      ),
    ]);
    await tester.pump(const Duration(seconds: 1));
    final BallBody roller = balls().singleWhere(
      (BallBody b) => b.tier == BallTier.t3,
    );
    debugPrint('SMOKE rolling: t3 x=${roller.body.position.x.round()}');
    expect(roller.body.position.x, greaterThan(200 + 25),
        reason: 'a small fruit on a slope should roll off');
    game.reset();
    await tester.pump(const Duration(milliseconds: 200));
    expect(balls(), isEmpty);

    // --- An oval falls over: a grape dropped upright with a nudge ends up
    // lying on its side (a circle would just spin in place).
    game.world.add(BallBody(
      tier: BallTier.t8,
      initialPosition: Vector2(180, floor - 200),
      onMerge: game.merge,
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final BallBody grape = balls().single;
    grape.body.angularVelocity = 2;
    await tester.pump(const Duration(seconds: 3));
    final double tilt =
        (grape.body.angle.abs() % math.pi) * 180 / math.pi; // 0…180
    debugPrint('SMOKE grape tilt: ${tilt.toStringAsFixed(0)}°');
    expect(tilt, inInclusiveRange(45, 135),
        reason: 'the grape should come to rest on its side');
    game.reset();
    await tester.pump(const Duration(milliseconds: 200));

    // --- Resting neighbours merge: two t1 lying side by side on the floor
    // with a 2-unit gap (inside the Box2D speculative contact distance, and
    // under the sprites' overhang) merge on their own — a stricter
    // «real touch» rule left such pairs unmerged forever.
    final double t1Y = floor - r(BallTier.t1);
    game.world.addAll(<BallBody>[
      BallBody(
        tier: BallTier.t1,
        initialPosition: Vector2(60, t1Y),
        onMerge: game.merge,
      ),
      BallBody(
        tier: BallTier.t1,
        initialPosition: Vector2(60 + 2 * r(BallTier.t1) + 2, t1Y),
        onMerge: game.merge,
      ),
    ]);
    await tester.pump(const Duration(milliseconds: 600));
    expect(balls().length, 1, reason: 'adjacent equal fruits must merge');
    expect(balls().single.tier, BallTier.t2);
    expect(game.cubit.state.score, BallTier.t1.mergeScore);
    game.reset();
    await tester.pump(const Duration(milliseconds: 200));

    // --- Merge momentum: two overlapping t1 moving right at 60 u/s merge on
    // the first update; the t2 keeps that velocity (equal parents → the
    // mass-weighted average is the same velocity).
    game.world.addAll(<BallBody>[
      BallBody(
        tier: BallTier.t1,
        initialPosition: Vector2(170, 120),
        initialVelocity: Vector2(60, 0),
        onMerge: game.merge,
      ),
      BallBody(
        tier: BallTier.t1,
        initialPosition: Vector2(180, 120),
        initialVelocity: Vector2(60, 0),
        onMerge: game.merge,
      ),
    ]);
    // Merge effects (flash ring + «+N» popup) appear right after the merge…
    await tester.pump(const Duration(milliseconds: 150));
    expect(game.world.children.whereType<MergeFlash>(), hasLength(1));
    expect(game.world.children.whereType<ScorePopup>(), hasLength(1));
    final List<BallBody> afterMerge = balls();
    expect(afterMerge.length, 1);
    expect(afterMerge.single.tier, BallTier.t2);
    final double vx = afterMerge.single.body.linearVelocity.x;
    debugPrint('SMOKE merge momentum: vx=${vx.toStringAsFixed(1)}');
    expect(vx, inInclusiveRange(45, 66),
        reason: 'the merged fruit should inherit its parents\' velocity');
    await tester.pump(const Duration(seconds: 2));
    // …and clean themselves up.
    expect(game.world.children.whereType<MergeFlash>(), isEmpty);
    expect(game.world.children.whereType<ScorePopup>(), isEmpty);
    expect(game.cubit.state.score, 2 * BallTier.t1.mergeScore);

    // --- Drops. The first one is timed: from the tap to the landing «ойк»
    // (was ≈ 1.8 s with the old floaty gravity), and while it falls no ball
    // may sink into the floor.
    final Rect jar = tester.getRect(gameFinder);
    final Set<BallBody> before = balls().toSet();
    final Stopwatch fall = Stopwatch()..start();
    await tester.tapAt(Offset(jar.left + jar.width * 0.25, jar.center.dy));
    double maxPenetration = 0;
    BallBody? dropped;
    for (int i = 0;
        i < 40 && (dropped == null || dropped.squishCount == 0);
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
      dropped ??=
          balls().where((BallBody b) => !before.contains(b)).firstOrNull;
      for (final BallBody b in balls()) {
        if (!b.isMounted) continue;
        maxPenetration = math.max(
          maxPenetration,
          b.body.position.y + b.minExtent - floor,
        );
      }
    }
    fall.stop();
    debugPrint('SMOKE fall: ${fall.elapsedMilliseconds} ms, '
        'max floor penetration ${maxPenetration.toStringAsFixed(2)}');
    expect(dropped, isNotNull);
    expect(dropped!.squishCount, greaterThan(0),
        reason: 'a dropped ball should squish on landing');
    // ≈ 1.2 s on a tall jar (gravity 1000, cap 800); was ≈ 1.8 s.
    expect(fall.elapsedMilliseconds, lessThan(1600));
    // Circles stay at 0.00; a tumbling rounded polygon can dip a corner up
    // to the speculative distance (2.4) for a frame — invisible on screen.
    // The old bug was 4.8 units (16 % of the cherry's diameter).
    expect(maxPenetration, lessThanOrEqualTo(2.0),
        reason: 'falling fruits must not sink into the floor');

    // Two more drops (450 ms cooldown) at other columns so they land on the
    // floor rather than on each other.
    for (final double fx in <double>[0.5, 0.75]) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tapAt(Offset(jar.left + jar.width * fx, jar.center.dy));
    }
    await tester.pump(const Duration(seconds: 3));

    final List<BallBody> resting = balls();
    // 1 merged t2 + 3 drops; random tiers may merge with each other or with
    // the t2, so the count can be lower — but never higher.
    expect(resting.length, inInclusiveRange(1, 4));
    expect(
      game.cubit.state.score,
      greaterThanOrEqualTo(2 * BallTier.t1.mergeScore),
    );
    String describe() => resting
        .map(
          (BallBody b) => 't${b.tier.number}@(${b.body.position.x.round()},'
              '${b.body.position.y.round()}) '
              'gap=${(floor - b.radius - b.body.position.y).toStringAsFixed(1)}',
        )
        .join(' ');
    debugPrint('SMOKE after drops: floor=${floor.round()} ${describe()}');

    // No ball sinks through the floor (a ball resting on another ball is
    // fine): centre.y <= floor - smallest half-extent (+ Box2D slop); an
    // oval lying on its side is lower than its nominal radius.
    for (final BallBody b in resting) {
      expect(
        b.body.position.y,
        lessThanOrEqualTo(floor - b.minExtent + 1.5),
        reason: 'ball t${b.tier.number} sank into the floor: ${describe()}',
      );
      expect(b.body.position.y, greaterThan(100));
    }
    // Pause overlay carries the theme picker; resume continues the game.
    await tester.tap(find.byKey(GameHud.pauseButtonKey));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ПАУЗА'), findsOneWidget);
    expect(find.byType(ThemePicker), findsOneWidget);
    await tester.tap(find.text('Продолжить'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(game.cubit.state.status, GameStatus.playing);
    debugPrint('SMOKE OK: score=${game.cubit.state.score} ${describe()}');
  });
}
