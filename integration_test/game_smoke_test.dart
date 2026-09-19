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
import 'package:features/game/screen/game_form.dart';
import 'package:features/game/widgets/bonus_bar.dart';
import 'package:features/game/widgets/game_hud.dart';
import 'package:features/game/widgets/game_over_overlay.dart';
import 'package:features/game/widgets/garden_intro_overlay.dart';
import 'package:features/game/widgets/mission_toast.dart';
import 'package:features/game/widgets/missions_overlay.dart';
import 'package:features/game/widgets/missions_panel.dart';
import 'package:features/game/widgets/onboarding_overlay.dart';
import 'package:features/jars/screen/jars_form.dart';
import 'package:features/menu/screen/menu_screen.dart';
import 'package:features/premium/screen/premium_form.dart';
import 'package:features/settings/screen/settings_form.dart';
import 'package:features/splash/engine/splash_game.dart';
import 'package:features/splash/screen/splash_screen.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
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
    // Layout overflows are reported by the framework at teardown with a
    // defunct element chain; print the widget chain while it is alive.
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      if (d.exceptionAsString().contains('overflowed')) {
        final String chain = d.informationCollector
                ?.call()
                .map((DiagnosticsNode n) => n.toStringDeep())
                .join(' | ') ??
            '';
        debugPrint('SMOKE OVERFLOW: ${d.exceptionAsString()} :: '
            '${chain.replaceAll('\n', ' ').substring(0, chain.length.clamp(0, 1200))}');
      }
      previous?.call(d);
    };
    addTearDown(() => FlutterError.onError = previous);
    await mainCommon(Flavor.dev);
    // Release the background music player, otherwise its frame callback
    // trips the binding's leak check at the end of the test.
    addTearDown(appLocator<AudioService>().dispose);
    // A previous (interrupted) run may have left a saved game or a language:
    // start from a clean slate so the menu shows «Play».
    await appLocator<GameRepository>().clear();
    await appLocator<GameRepository>().clear(mode: GameMode.garden);
    await appLocator<SettingsService>().setLocale(null);
    await appLocator<SettingsService>().setJarId(JarShapes.defaultId);
    {
      // Fresh day for the daily challenge and a fresh first launch for the
      // onboarding.
      final ProgressRepository pr = appLocator<ProgressRepository>();
      await pr.saveProgress((await pr.getProgress())
          .copyWith(dailyPlayedSeed: 0, onboardingDone: false));
    }
    addTearDown(
        () => appLocator<SettingsService>().setJarId(JarShapes.defaultId));
    final PremiumService premium = appLocator<PremiumService>();
    await premium.setPremium(false);
    addTearDown(() => premium.setPremium(false));
    // No pumpAndSettle anywhere: the Flame game loop schedules frames
    // continuously, so pumpAndSettle would never return.
    await tester.pump(const Duration(milliseconds: 1500));

    // Splash: fruits are raining down on the shared engine; tap skips it.
    final Finder splashFinder = find.byType(GameWidget<SplashGame>);
    expect(splashFinder, findsOneWidget);
    final SplashGame splash =
        tester.widget<GameWidget<SplashGame>>(splashFinder).game!;
    expect(splash.spawned, greaterThan(3));
    await tester.tap(find.byKey(SplashScreen.skipKey));
    await tester.pump(const Duration(seconds: 1));

    // Menu.
    expect(find.text(LocaleKeys.menu_play.tr()), findsOneWidget);

    // Settings: open from ⚙️, toggle «Музыка» twice (persisted both ways),
    // the fruit chain shows all 11 tiers, back returns to the menu.
    final SettingsService settings = appLocator<SettingsService>();
    final bool musicBefore = settings.value.musicOn;
    final String themeBefore = settings.value.themeId;
    await tester.tap(find.byKey(MenuScreen.settingsButtonKey));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(LocaleKeys.settings_title.tr()), findsOneWidget);
    expect(find.text(LocaleKeys.settings_aimLine.tr()), findsOneWidget);
    // Premium row opens the paywall (no store in tests: the buy button is
    // disabled, «back» returns); once premium is set the row turns into a
    // status line. All wallpapers are free for now, so «night» selects,
    // persists and reaches the theme scope without the purchase.
    // Without monetization (release 1.0, the default) there is no premium
    // row at all: run with --dart-define=monetization=on to cover the
    // paywall.
    expect(find.byType(ThemePicker), findsOneWidget);
    expect(GameThemes.lockedIds, isEmpty);
    if (AppConfig.monetizationEnabled) {
      await tester.tap(find.byKey(SettingsForm.premiumRowKey));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(PremiumForm), findsOneWidget);
      expect(find.byKey(PremiumForm.restoreKey), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(PremiumForm), findsNothing);
    } else {
      expect(find.byKey(SettingsForm.premiumRowKey), findsNothing);
    }
    await tester.tap(find.byKey(const Key('theme_night')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(settings.value.themeId, 'night');
    await premium.setPremium(true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(SettingsForm.premiumRowKey), findsNothing);
    expect(
      (await appLocator<SettingsRepository>().getSettings()).themeId,
      'night',
    );
    expect(
      AppThemeScope.of(
              tester.element(find.text(LocaleKeys.settings_title.tr())))
          .id,
      'night',
    );
    // Language: pick 日本語 in the language overlay → UI switches and the
    // choice persists; «System» restores the device language (null).
    expect(settings.value.localeCode, isNull);
    await tester.tap(find.byKey(SettingsForm.languageRowKey));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('language_ja')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(settings.value.localeCode, 'ja');
    expect(
      (await appLocator<SettingsRepository>().getSettings()).localeCode,
      'ja',
    );
    expect(find.text('設定'), findsOneWidget);
    await tester.tap(find.byKey(SettingsForm.languageRowKey));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('language_system')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(settings.value.localeCode, isNull);
    expect(find.text(LocaleKeys.settings_title.tr()), findsOneWidget);
    await tester.tap(find.byKey(Key('theme_$themeBefore')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(settings.value.themeId, themeBefore);
    await tester.tap(find.text(LocaleKeys.settings_music.tr()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.value.musicOn, !musicBefore);
    expect(
      (await appLocator<SettingsRepository>().getSettings()).musicOn,
      !musicBefore,
    );
    await tester.tap(find.text(LocaleKeys.settings_music.tr()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.value.musicOn, musicBefore);
    // The fruit chain (11 sprites) lives below the fold: the ListView builds
    // it lazily, so scroll down before looking, then scroll back.
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(BallView), findsAtLeast(BallTier.values.length));
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(LocaleKeys.menu_play.tr()), findsOneWidget);

    await tester.tap(find.byKey(MenuScreen.playButtonKey));
    await tester.pump(const Duration(seconds: 2));

    // Game screen with a loaded Forge2D world.
    final Finder gameFinder = find.byType(GameWidget<WasDropGame>);
    expect(gameFinder, findsOneWidget);
    final WasDropGame game =
        tester.widget<GameWidget<WasDropGame>>(gameFinder).game!;
    await tester.pump(const Duration(seconds: 1));
    expect(game.isLoaded, isTrue);
    expect(game.cubit.state.score, 0);

    // --- Onboarding on the first game: three steps, the engine waits;
    // «Let's play!» closes it for good.
    expect(find.byType(OnboardingOverlay), findsOneWidget);
    expect(game.paused, isTrue);
    await tester.pump(const Duration(seconds: 2)); // screenshot window
    await tester.tap(find.byKey(OnboardingOverlay.nextKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(OnboardingOverlay.nextKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(OnboardingOverlay.nextKey));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OnboardingOverlay), findsNothing);
    expect(game.paused, isFalse);
    expect(
      (await appLocator<ProgressRepository>().getProgress()).onboardingDone,
      isTrue,
    );

    // --- Missions: three orders in the panel; tapping it opens the orders
    // overlay (game paused), closing resumes.
    expect(game.cubit.state.missions, hasLength(3));
    expect(find.byType(MissionCard), findsNWidgets(3));
    await tester.tap(find.byKey(MissionsPanel.panelKey));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(MissionsOverlay), findsOneWidget);
    expect(game.cubit.state.status, GameStatus.paused);
    await tester.pump(const Duration(seconds: 2)); // screenshot window
    await tester.tap(find.byKey(MissionsOverlay.closeKey));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MissionsOverlay), findsNothing);
    expect(game.cubit.state.status, GameStatus.playing);
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
    expect(find.text(LocaleKeys.pause_title.tr()), findsOneWidget);
    expect(find.byType(ThemePicker), findsOneWidget);
    await tester.tap(find.text(LocaleKeys.pause_resume.tr()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(game.cubit.state.status, GameStatus.playing);
    debugPrint('SMOKE drops OK: score=${game.cubit.state.score} ${describe()}');

    // --- Bonuses: shake tosses every ball (3 charges); the bomb removes the
    // tapped ball (1 charge). Never read a removed ball's body afterwards.
    String live() => balls()
        .map((BallBody b) => 't${b.tier.number}@(${b.body.position.x.round()},'
            '${b.body.position.y.round()})')
        .join(' ');
    expect(game.cubit.state.shakes, GameRules.shakesPerGame);
    expect(game.cubit.state.bombs, GameRules.bombsPerGame);
    await tester.tap(find.byKey(BonusBar.shakeKey));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.cubit.state.armed, Bonus.shake);
    expect(find.byKey(GameForm.bonusHintKey), findsOneWidget);
    ShakeDetector.simulate();
    await tester.pump(const Duration(milliseconds: 50));
    expect(game.cubit.state.armed, isNull);
    expect(game.cubit.state.shakes, GameRules.shakesPerGame - 1);
    expect(
      balls().any((BallBody b) => b.body.linearVelocity.length > 100),
      isTrue,
      reason: 'shake should toss the balls',
    );
    await tester.pump(const Duration(seconds: 2));
    for (final BallBody b in balls()) {
      expect(b.body.position.x, inInclusiveRange(0, WasDropGame.worldWidth));
      expect(b.body.position.y, lessThanOrEqualTo(floor));
    }
    debugPrint('SMOKE shake OK: ${live()}');

    // Bomb: arm it, tap a resting ball on screen, it blows up; with no
    // charges left the button is disabled.
    final int countBefore = balls().length;
    final int mergesBeforeBomb = game.cubit.state.merges;
    final BallBody victim = balls().first;
    await tester.tap(find.byKey(BonusBar.bombKey));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.cubit.state.armed, Bonus.bomb);
    expect(find.byKey(GameForm.bonusHintKey), findsOneWidget);
    final Rect canvas = tester.getRect(gameFinder);
    final double scale = canvas.width / WasDropGame.worldWidth;
    await tester.tapAt(
      canvas.topLeft +
          Offset(
              victim.body.position.x * scale, victim.body.position.y * scale),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.cubit.state.armed, isNull);
    expect(game.cubit.state.bombs, GameRules.bombsPerGame - 1);
    expect(find.byKey(GameForm.bonusHintKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 700));
    expect(victim.isMounted, isFalse);
    // The blast can push two equal neighbours into a merge (−2 +1 each).
    expect(
      balls().length,
      countBefore - 1 - (game.cubit.state.merges - mergesBeforeBomb),
    );
    // With no charges left: with monetization the button offers the one
    // refill per game (premium, set in the settings step, gets it without
    // an ad); without monetization (release 1.0) it is simply disabled.
    final bool refills = AppConfig.monetizationEnabled;
    expect(game.cubit.state.canRefill(Bonus.bomb), refills);
    await tester.tap(find.byKey(BonusBar.bombKey));
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.cubit.state.armed, isNull);
    expect(game.cubit.state.bombs, refills ? GameRules.bombsPerGame : 0);
    expect(
      game.cubit.state.bombRefills,
      refills ? GameRules.refillsPerBonus - 1 : GameRules.refillsPerBonus,
    );
    expect(game.cubit.state.canRefill(Bonus.bomb), isFalse);
    debugPrint('SMOKE bomb OK: ${live()}');

    // Upgrade: arm it, tap a ball → it is replaced in place by the next tier
    // (which may immediately merge with an equal neighbour). A shake can
    // cascade-merge the pile into a single fruit that the bomb then removes,
    // so drop a fresh one when the jar is empty.
    if (balls().isEmpty) {
      await tester.tapAt(Offset(jar.left + jar.width * 0.5, jar.center.dy));
      await tester.pump(const Duration(seconds: 2));
    }
    final BallBody target =
        balls().firstWhere((BallBody b) => b.tier.next != null);
    final BallTier grown = target.tier.next!;
    final int countBeforeUpgrade = balls().length;
    await tester.tap(find.byKey(BonusBar.upgradeKey));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.cubit.state.armed, Bonus.upgrade);
    await tester.tapAt(
      canvas.topLeft +
          Offset(
              target.body.position.x * scale, target.body.position.y * scale),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.cubit.state.armed, isNull);
    expect(game.cubit.state.upgrades, GameRules.upgradesPerGame - 1);
    expect(target.isMounted, isFalse);
    expect(balls().length, lessThanOrEqualTo(countBeforeUpgrade));
    expect(
      balls().any((BallBody b) => b.tier.index >= grown.index),
      isTrue,
      reason: 'the tapped ball should have grown to t${grown.number}',
    );
    await tester.pump(const Duration(seconds: 1));
    debugPrint('SMOKE upgrade OK: ${live()}');

    // --- Save & resume: the snapshot survives a trip to the menu; the
    // resumed game opens paused with the same score and balls; a restart
    // clears it.
    final GameRepository gameRepo = appLocator<GameRepository>();
    await game.cubit.saveSnapshot(
      game.captureBalls(),
      jarId: game.jarShape.id,
    );
    final GameSnapshot? saved = await gameRepo.load();
    expect(saved, isNotNull);
    expect(saved!.balls.length, balls().length);
    expect(saved.score, game.cubit.state.score);
    await tester.tap(find.byKey(GameHud.pauseButtonKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(LocaleKeys.pause_menu.tr()));
    await tester.pump(const Duration(milliseconds: 1500));
    // The same «Continue» label may also sit on the garden card.
    expect(
      find.descendant(
        of: find.byKey(MenuScreen.playButtonKey),
        matching: find.text(LocaleKeys.menu_continue.tr()),
      ),
      findsOneWidget,
    );
    expect(find.byKey(MenuScreen.newGameButtonKey), findsOneWidget);
    await tester.tap(find.byKey(MenuScreen.playButtonKey));
    await tester.pump(const Duration(seconds: 2));
    final WasDropGame resumed = tester
        .widget<GameWidget<WasDropGame>>(find.byType(GameWidget<WasDropGame>))
        .game!;
    await tester.pump(const Duration(seconds: 1));
    expect(resumed.cubit.state.status, GameStatus.paused);
    expect(resumed.cubit.state.score, saved.score);
    expect(saved.shakes, GameRules.shakesPerGame - 1);
    expect(saved.bombs, refills ? GameRules.bombsPerGame : 0);
    expect(
      saved.bombRefills,
      refills ? GameRules.refillsPerBonus - 1 : GameRules.refillsPerBonus,
    );
    expect(saved.upgrades, GameRules.upgradesPerGame - 1);
    expect(saved.upgradeRefills, GameRules.refillsPerBonus);
    expect(resumed.cubit.state.shakes, saved.shakes);
    expect(resumed.cubit.state.bombs, saved.bombs);
    expect(resumed.cubit.state.bombRefills, saved.bombRefills);
    expect(
      resumed.world.children.whereType<BallBody>().length,
      saved.balls.length,
    );
    debugPrint(
        'SMOKE resumed: score=${saved.score} balls=${saved.balls.length}');
    await tester.tap(find.text(LocaleKeys.pause_resume.tr()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(resumed.cubit.state.status, GameStatus.playing);

    // --- Continue after game over: without an ad (premium was set in the
    // settings step; without monetization everyone gets it free) — the top
    // layer above the deadline is cleared, the game resumes and the one
    // continue per game is spent; the second game over offers no continue.
    // A refill on an exhausted bonus is free too.
    expect(resumed.cubit.adFree, isTrue);
    await resumed.cubit.gameOver();
    await tester.pump(const Duration(milliseconds: 600));
    expect(resumed.cubit.state.status, GameStatus.gameOver);
    expect(find.byKey(GameOverOverlay.continueKey), findsOneWidget);
    expect(find.byKey(GameOverOverlay.removeAdsKey), findsNothing);
    await tester.tap(find.byKey(GameOverOverlay.continueKey));
    await tester.pump(const Duration(milliseconds: 600));
    expect(resumed.cubit.state.status, GameStatus.playing);
    expect(resumed.cubit.state.continues, GameRules.continuesPerGame - 1);
    expect(resumed.overLineTime, 0);
    for (final BallBody b in resumed.liveBalls()) {
      expect(
        b.body.position.y - b.radius,
        greaterThanOrEqualTo(WasDropGame.deadlineY),
        reason: 'continue must clear every fruit above the deadline',
      );
    }
    expect(resumed.cubit.state.upgrades, 0);
    expect(resumed.cubit.state.canRefill(Bonus.upgrade), refills);
    await tester.tap(find.byKey(BonusBar.upgradeKey));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      resumed.cubit.state.upgrades,
      refills ? GameRules.upgradesPerGame : 0,
    );
    expect(
      resumed.cubit.state.upgradeRefills,
      refills ? GameRules.refillsPerBonus - 1 : GameRules.refillsPerBonus,
    );
    expect(resumed.cubit.state.armed, isNull);
    await resumed.cubit.gameOver();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(GameOverOverlay.continueKey), findsNothing);
    debugPrint('SMOKE continue OK');

    resumed.cubit.restart();
    resumed.reset();
    await tester.pump(const Duration(milliseconds: 500));
    expect(await gameRepo.load(), isNull);
    expect(resumed.cubit.state.continues, GameRules.continuesPerGame);
    debugPrint('SMOKE OK: resume flow finished');

    // --- Jar shapes: pick «Vase» in the jar picker (menu → jar button),
    // start a game — the engine builds the vase walls, a fruit dropped at
    // the edge of the narrow neck lands inside the jar, and the snapshot
    // remembers the jar.
    await tester.tap(find.byKey(GameHud.pauseButtonKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(LocaleKeys.pause_menu.tr()));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byKey(MenuScreen.jarButtonKey), findsOneWidget);
    await tester.tap(find.byKey(MenuScreen.jarButtonKey));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(JarsForm), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // screenshot window
    await tester.tap(find.byKey(JarsForm.cardKey('vase')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(appLocator<SettingsService>().value.jarId, 'vase');
    // A locked jar (below the fold — the grid builds lazily) cannot be
    // selected without stars.
    await tester.scrollUntilVisible(
      find.byKey(JarsForm.cardKey('hourglass')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(JarsForm.cardKey('hourglass')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(appLocator<SettingsService>().value.jarId, 'vase');
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(MenuScreen.playButtonKey));
    await tester.pump(const Duration(seconds: 2));
    final WasDropGame vaseGame = tester
        .widget<GameWidget<WasDropGame>>(find.byType(GameWidget<WasDropGame>))
        .game!;
    await tester.pump(const Duration(seconds: 1));
    expect(vaseGame.jarShape.id, 'vase');
    // The neck is narrower than the world: the hanging fruit is clamped to it.
    final (double neckL, double neckR) =
        vaseGame.jar.spanAt(WasDropGame.spawnY + r(BallTier.t1));
    expect(neckL, greaterThan(20));
    expect(neckR, lessThan(AppDimens.worldWidth - 20));
    final Rect vaseRect = tester.getRect(find.byType(GameWidget<WasDropGame>));
    // Tap at the very left edge of the canvas: the drop X is clamped into
    // the neck, the fruit slides down the widening wall and rests inside.
    await tester.tapAt(Offset(vaseRect.left + 2, vaseRect.top + 40));
    await tester.pump(const Duration(seconds: 3));
    final List<BallBody> vaseBalls =
        vaseGame.world.children.whereType<BallBody>().toList();
    expect(vaseBalls, hasLength(1));
    final BallBody vaseBall = vaseBalls.single;
    expect(vaseBall.body.position.x, greaterThan(vaseBall.radius - 3));
    expect(vaseBall.body.position.y,
        lessThanOrEqualTo(vaseGame.worldHeight - vaseBall.minExtent + 1.5));
    expect(vaseBall.body.linearVelocity.length, lessThan(40));
    await vaseGame.cubit.saveSnapshot(
      vaseGame.captureBalls(),
      jarId: vaseGame.jarShape.id,
    );
    expect((await gameRepo.load())!.jarId, 'vase');
    debugPrint('SMOKE jar OK: vase ball at '
        '${vaseBall.body.position.x.round()},${vaseBall.body.position.y.round()}');
    await tester.pump(const Duration(seconds: 2)); // screenshot window

    // --- Mission completion: feed merges until an order completes — the
    // toast pops over the jar, a star lands in the progress box, the order
    // is replaced and the reward is applied.
    final ProgressRepository progressRepo = appLocator<ProgressRepository>();
    final int starsBefore = (await progressRepo.getProgress()).stars;
    final int doneBefore = vaseGame.cubit.state.completedCount;
    final Mission scoreOrder = vaseGame.cubit.state.missions.firstWhere(
      (Mission m) => m.type == MissionType.score,
      orElse: () => vaseGame.cubit.state.missions.first,
    );
    for (int i = 0;
        i < 60 && vaseGame.cubit.state.completedCount == doneBefore;
        i++) {
      // A t9 merge: 512 points; a getFruit/collect order needs its tier.
      final BallTier? want = scoreOrder.tier;
      vaseGame.cubit.onMerge(
          want == null ? BallTier.t9 : BallTier.values[want.index - 1]);
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(vaseGame.cubit.state.completedCount, doneBefore + 1);
    expect(vaseGame.cubit.state.starsEarned, 1);
    expect(find.byType(MissionToast), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500)); // screenshot window
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byType(MissionToast), findsNothing);
    expect((await progressRepo.getProgress()).stars, starsBefore + 1);
    expect(vaseGame.cubit.state.missions, hasLength(3));
    debugPrint('SMOKE missions OK: stars=${starsBefore + 1}');

    // --- Modes. Time attack: the HUD shows the clock, it counts down, the
    // run is not saved. Daily: seeded queue, one attempt a day — after it
    // the menu button shows today's score and is disabled.
    await tester.tap(find.byKey(GameHud.pauseButtonKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(LocaleKeys.pause_menu.tr()));
    await tester.pump(const Duration(milliseconds: 1500));
    await gameRepo.clear();
    await tester.tap(find.byKey(MenuScreen.timedButtonKey));
    await tester.pump(const Duration(seconds: 2));
    final WasDropGame timedGame = tester
        .widget<GameWidget<WasDropGame>>(find.byType(GameWidget<WasDropGame>))
        .game!;
    expect(timedGame.cubit.mode, GameMode.timed);
    expect(find.byKey(GameHud.timerKey), findsOneWidget);
    final int t0 = timedGame.cubit.state.secondsLeft!;
    await tester.pump(const Duration(milliseconds: 2500));
    expect(timedGame.cubit.state.secondsLeft, lessThan(t0));
    await tester.pump(const Duration(seconds: 1)); // screenshot window
    await tester.tap(find.byKey(GameHud.pauseButtonKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(LocaleKeys.pause_menu.tr()));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(await gameRepo.load(), isNull, reason: 'timed runs are not saved');
    expect(find.text(LocaleKeys.menu_play.tr()), findsOneWidget);

    final int todaySeed = dailySeed();
    final ProgressModel beforeDaily = await progressRepo.getProgress();
    expect(beforeDaily.dailyPlayed(todaySeed), isFalse);
    await tester.tap(find.byKey(MenuScreen.dailyButtonKey));
    await tester.pump(const Duration(seconds: 2));
    final WasDropGame dailyGame = tester
        .widget<GameWidget<WasDropGame>>(find.byType(GameWidget<WasDropGame>))
        .game!;
    expect(dailyGame.cubit.mode, GameMode.daily);
    dailyGame.cubit.onMerge(BallTier.t2);
    await dailyGame.cubit.gameOver();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(GameOverOverlay.continueKey), findsNothing);
    expect(find.text(LocaleKeys.gameOver_dailyDone.tr()), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // screenshot window
    await tester.tap(find.text(LocaleKeys.gameOver_menu.tr()));
    await tester.pump(const Duration(milliseconds: 1500));
    final ProgressModel afterDaily = await progressRepo.getProgress();
    expect(afterDaily.dailyPlayed(todaySeed), isTrue);
    expect(afterDaily.dailyScore, greaterThan(0));
    expect(
      find.text(LocaleKeys.menu_dailyDone.tr(
        namedArgs: <String, String>{'score': '${afterDaily.dailyScore}'},
      )),
      findsOneWidget,
    );
    // Reset the day so the next run can play it again.
    await progressRepo.saveProgress(afterDaily.copyWith(dailyPlayedSeed: 0));
    debugPrint('SMOKE modes OK: daily=${afterDaily.dailyScore}');

    // --- Wonder Garden: the mode card opens the intro on the first visit;
    // the game runs in garden mode with a purple-ringed special fruit
    // showing up in the «next» slot within a few drops; the run is saved
    // under its own key and the menu card offers to continue it.
    await gameRepo.clear(mode: GameMode.garden);
    await progressRepo.saveProgress(
      (await progressRepo.getProgress()).copyWith(gardenIntroDone: false),
    );
    await tester.tap(find.byKey(MenuScreen.gardenButtonKey));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(GardenIntroOverlay), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // screenshot window
    await tester.tap(find.byKey(GardenIntroOverlay.okKey));
    await tester.pump(const Duration(milliseconds: 500));
    final WasDropGame gardenGame = tester
        .widget<GameWidget<WasDropGame>>(find.byType(GameWidget<WasDropGame>))
        .game!;
    expect(gardenGame.cubit.mode, GameMode.garden);
    expect(gardenGame.paused, isFalse);
    // Feed drops until a special fruit reaches the «next» slot.
    for (int i = 0; i < 30 && gardenGame.cubit.state.nextSpecial == null; i++) {
      gardenGame.cubit.onDropped();
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(gardenGame.cubit.state.nextSpecial, isNotNull);
    await tester.pump(const Duration(seconds: 2)); // screenshot window
    gardenGame.cubit.onMerge(BallTier.t2);
    await gardenGame.cubit.saveSnapshot(
      gardenGame.captureBalls(),
      jarId: gardenGame.jarShape.id,
    );
    expect(await gameRepo.load(mode: GameMode.garden), isNotNull);
    expect(await gameRepo.load(), isNull, reason: 'classic slot untouched');
    await tester.tap(find.byKey(GameHud.pauseButtonKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(LocaleKeys.pause_menu.tr()));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(
      find.descendant(
        of: find.byKey(MenuScreen.gardenButtonKey),
        matching: find.text(LocaleKeys.menu_continue.tr()),
      ),
      findsOneWidget,
      reason: 'the garden card offers to continue',
    );
    await gameRepo.clear(mode: GameMode.garden);
    debugPrint('SMOKE garden OK');
    await gameRepo.clear();
  });
}
