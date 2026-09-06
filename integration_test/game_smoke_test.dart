// Smoke test for the real app on a device / simulator:
//
//   flutter test integration_test -d <deviceId> --flavor dev --dart-define=environment=dev
//
// Covers: menu renders → «ИГРАТЬ» opens the game → two equal balls merge and
// score the expected points → taps on the jar drop balls that fall and rest
// on the physical floor, which matches the bottom of the jar widget.

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:features/game/engine/ball_body.dart';
import 'package:features/game/engine/merge_effects.dart';
import 'package:features/game/engine/wasdrop_game.dart';
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

  testWidgets('menu → game → merge → drop', (WidgetTester tester) async {
    await mainCommon(Flavor.dev);
    // Release the background music player, otherwise its frame callback
    // trips the binding's leak check at the end of the test.
    addTearDown(appLocator<AudioService>().dispose);
    // No pumpAndSettle anywhere: the Flame game loop schedules frames
    // continuously, so pumpAndSettle would never return.
    await tester.pump(const Duration(seconds: 2));

    // Menu.
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

    // The physics floor matches the widget's aspect ratio.
    final Size widgetSize = tester.getSize(gameFinder);
    expect(
      game.worldHeight,
      closeTo(AppDimens.worldWidth * widgetSize.height / widgetSize.width, 0.5),
    );

    // Deterministic merge: two overlapping t1 balls (radius 12, centres 10
    // apart) touch on the first physics step → one t2 ball, score += 2^1.
    game.world.addAll(<BallBody>[
      BallBody(
        tier: BallTier.t1,
        initialPosition: Vector2(170, 120),
        onMerge: game.merge,
      ),
      BallBody(
        tier: BallTier.t1,
        initialPosition: Vector2(180, 120),
        onMerge: game.merge,
      ),
    ]);
    // Merge effects (flash ring + «+N» popup) appear right after the merge…
    await tester.pump(const Duration(milliseconds: 150));
    expect(game.world.children.whereType<MergeFlash>(), hasLength(1));
    expect(game.world.children.whereType<ScorePopup>(), hasLength(1));
    await tester.pump(const Duration(seconds: 2));
    // …and clean themselves up.
    expect(game.world.children.whereType<MergeFlash>(), isEmpty);
    expect(game.world.children.whereType<ScorePopup>(), isEmpty);
    expect(game.cubit.state.score, BallTier.t1.mergeScore);
    final List<BallBody> afterMerge =
        game.world.children.whereType<BallBody>().toList();
    expect(afterMerge.length, 1);
    expect(afterMerge.single.tier, BallTier.t2);

    // Taps drop balls (450 ms cooldown between drops) at three different
    // columns so they land on the floor rather than on each other.
    final Rect jar = tester.getRect(gameFinder);
    for (final double fx in <double>[0.25, 0.5, 0.75]) {
      await tester.tapAt(Offset(jar.left + jar.width * fx, jar.center.dy));
      await tester.pump(const Duration(milliseconds: 600));
    }
    await tester.pump(const Duration(seconds: 4));

    final List<BallBody> balls =
        game.world.children.whereType<BallBody>().toList();
    expect(balls.length, 4);
    String describe() => balls
        .map(
          (BallBody b) => 't${b.tier.number}@(${b.body.position.x.round()},'
              '${b.body.position.y.round()}) '
              'gap=${(game.worldHeight - b.radius - b.body.position.y).toStringAsFixed(1)}',
        )
        .join(' ');
    debugPrint(
        'SMOKE after 4s: floor=${game.worldHeight.round()} ${describe()}');

    // No ball sinks through the floor (a ball resting on another ball is
    // fine): centre.y <= floor - radius (+ Box2D slop). The middle column
    // lands on the merged t2 on purpose — that squeeze used to push the
    // small ball through the thin floor segment.
    for (final BallBody b in balls) {
      expect(
        b.body.position.y,
        lessThanOrEqualTo(game.worldHeight - b.radius + 1.5),
        reason: 'ball t${b.tier.number} sank into the floor: ${describe()}',
      );
      expect(b.body.position.y, greaterThan(100));
    }
    debugPrint('SMOKE OK: score=${game.cubit.state.score} ${describe()}');
  });
}
