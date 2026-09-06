# WasDrop — UI / Architecture Reference

Single source of truth for design tokens, widget inventory, composition rules and code style. Read in full by the `create-feature-ui`, `create-feature-full`, `create-widget`, `analyze-feature` and `audit-section` skills before generating or reviewing code.

Product spec (screens, gameplay, mockup frames): `.claude/my_docs/WASDROP.md`. Mockups: `WasDrop Mockups.dc.html` in the design project (variant **1a «тёплый фруктовый»**).

---

## § 1 — Design System

There is **no token generator and no theme provider** — tokens are plain `static const` classes in `core_ui/lib/src/theme/`, re-exported by `package:core_ui/core_ui.dart`. No `flutter_screenutil`: sizes are logical pixels.

### 1.1 Colors — `AppColors` (`core_ui/lib/src/theme/app_colors.dart`)

| Group | Constants |
|---|---|
| Surfaces | `bgScreen` `#F7F2E7` (scaffold), `surface` `#FFFDF6` (panels, HUD chips), `secondarySurface` `#F1EADA` (secondary button), `jar` `#ECE5D6`, `jarWall` `#D9CFBB` |
| Text | `textPrimary` `#33291A`, `textSecondary` `#8A7D63`, `textTertiary` `#B3A88C`, `secondaryText` `#6B5F45` (secondary button label), `goldText` `#5C4703` |
| Lines | `stroke` `#E4DCC9` (2 px borders), `deadline` `#BDB29B` (game-over line, idle) |
| Accent | `accent` `#F76B15`, `accentTop` `#FF8A34` (gradient top), `accentShadow` `#D95806` (button "thick" shadow) |
| Semantic | `alert` `#E5484D` (deadline warning, DEV banner), `scoreGain` `#12A594` (`+N` popups), `goldTop` `#F8CF5B` → `gold` `#EFB008` (record badge gradient) |
| Effects / overlays | `flash` `#FFFFFF` (merge ring, ball highlight), `scrim` `#882B210E` (overlay dim), `panelShadow` `#2E2B210E` (panel / toggle knob shadow) |
| Tiers | `tiers` — `List<Color>` for `BallTier` 1–11, index = `tier.index` |

Ball fill (see `BallView`): `RadialGradient(center: Alignment(-0.3, -0.4))`, stops `0 / 0.72 / 1`: `lerp(color, white, .45)` → `color` → `lerp(color, black, .12)`; shadow `Color(0x3333291A)`, offset `(0, 3)`, blur 6.

**Rule:** never write `Color(0xFF…)` / `Colors.x` in `features/` — add a constant to `AppColors` and use it. The one remaining exception is `Colors.white` in `AppFonts.button` (known debt).

### 1.2 Typography — `AppFonts` (`core_ui/lib/src/theme/app_fonts.dart`)

Family **Archivo** (600 / 800 / 900, registered in the root `pubspec.yaml` from `core/resources/fonts/`). Digits always `FontFeature.tabularFigures()`.

| Style | Spec | Where |
|---|---|---|
| `title` | 46 / w900, `height: 1`, `textPrimary` | Menu logo («Was» dark + «Drop» in `accent` via `copyWith`) |
| `score` | 34 / w800, tabular, `textPrimary` | HUD score; game-over score uses `copyWith(fontSize: 44)` |
| `best` | 11 / w700, `letterSpacing: .66`, tabular, `textSecondary` | «РЕКОРД N», «🏆 рекорд N» chip |
| `button` | 17 / w800, white | `PrimaryButton`; secondary/text buttons `copyWith(color:, fontSize:)` |
| `overlayTitle` | 20 / w900, `letterSpacing: 1`, `textPrimary` | «ПАУЗА», «ИГРА ОКОНЧЕНА» |

`lightTheme` (`app_theme.dart`): Material 3, `fontFamily: Archivo`, `scaffoldBackgroundColor: bgScreen`, seed `accent`, `NoSplash`, fade-up (Android) / Cupertino (iOS) page transitions. Single light theme; `ThemeMode.light` is forced in `lib/app.dart`.

**Rule:** derive every text style from an `AppFonts` constant with `copyWith`; do not build `TextStyle(fontFamily: …)` from scratch in features. Emoji-only text (`'🔊'`, `tier.emoji`) may use a bare `TextStyle(fontSize:)`.

### 1.3 Dimensions — `AppDimens` (`core_ui/lib/src/theme/app_dimens.dart`)

Plain `static const double`:

| Constant | Value | Meaning |
|---|---|---|
| `worldWidth` | 360 | Physics world width; world height follows the jar widget aspect (`WasDropGame.worldHeight`) |
| `ballRadii` | 12 … 105 | Radius per tier (world units), index = `tier.index`; suika-like proportions |
| `ballSpawnY` | 44 | Centre of the hanging (not yet dropped) ball |
| `buttonHeight` / `buttonRadius` | 56 / 28 | Primary button (menu uses `height: 64`) |
| `iconButtonSize` | 52 | `IconCircleButton` |
| `panelRadius` / `panelPadding` | 24 / 24 | Overlay panels (width 280–288) |
| `jarWallWidth` | 5 | Jar border |
| `deadlineTopOffset` | 96 | Game-over line offset from jar top (world units), below the hanging t5 |
| `minTapTarget` | 44 | HUD buttons |

Spacing inside layouts is inline (`SizedBox(height: 12)`, `EdgeInsets.fromLTRB(20, 12, 20, 4)`) — acceptable for one-off layout; anything reused across 2+ files becomes an `AppDimens` constant. Values are `const`, so `const EdgeInsets.all(AppDimens.panelPadding)` is fine.

### 1.4 Icons & images

No asset pipeline yet: icons are emoji (`'🔊'`, `'⚙️'`, `'🏆'`) or `Icons.*` (`Icons.pause`). Tier markers are `BallTier.emoji` (🍒🍓🍊🍋🍏🥝🫐🍇🍑🍈🍉) with the digit `tier.number` as fallback (`BallView(showEmoji: false)`). If raster/SVG assets land, put them under `core/resources/` and add an `AppImage`-style wrapper to `core_ui` before using them in features.

### 1.5 Widget inventory — `core_ui/lib/src/widgets/` (barrel `widgets.dart`)

| Widget | File | API |
|---|---|---|
| `AppPressable` | `app_pressable.dart` | `builder(context, pressed, child)`, `onPressed`, `child`, `duration`, `feedback` — base of every button: animates the press amount 0…1 (110 ms in, easeOutBack out), calls `ButtonFeedback.trigger()` then `onPressed`; `onPressed == null` = disabled |
| `AppScaffold` | `app_scaffold.dart` | `body` — `Scaffold` with `bgScreen`; no app bar (screens draw their own HUD/header) |
| `PrimaryButton` | `primary_button.dart` | `label`, `onPressed`, `height = 56` — `accentTop → accent` gradient, `accentShadow` depth `AppDimens.buttonShadowDepth`; on press it sinks by the shadow depth and scales to 98 % |
| `SecondaryButton` | `secondary_button.dart` | `label`, `onPressed`, `height = 52`, `outlined = false` — `secondarySurface` pill / 2 px `stroke` outline («▶ Продолжить за рекламу»); darkens + 97 % on press |
| `AppTextButton` | `app_text_button.dart` | `label`, `onPressed` — «В меню»-style text action, ≥ 44 px tap target, fades on press |
| `IconCircleButton` | `icon_circle_button.dart` | `child`, `onPressed`, `size = 52` — circle, `surface` fill, 2 px `stroke` border; 90 % on press (HUD pause uses `size: 44`) |
| `AppToggleRow` | `app_toggle_row.dart` | `label`, `value`, `onChanged` — settings row with an animated 52×30 pill (`accent` on / `stroke` off); the whole row is the tap target |
| `AppOverlay` | `app_overlay.dart` | `child`, `width = 288` — `scrim` dim + `surface` panel (radius 24, padding 24) that fades / floats / pops in over 280 ms |
| `BallView` | `ball_view.dart` | `tier`, `diameter`, `showEmoji = true` — static ball for HUD / menu (in-game balls are drawn by the engine) |

**Feedback hook.** `ButtonFeedback.onPressed` (`core_ui/lib/src/feedback/button_feedback.dart`) is a static callback every `AppPressable` fires on tap; the app wires it to `AudioService.tap` (sound + haptic, both gated by `SettingsModel`) in `lib/main_common.dart`. Never call `HapticFeedback` or play audio from `core_ui` directly — build on `AppPressable` and the feedback comes for free.

Feature-local widgets today: `features/lib/game/widgets/` → `GameHud`, `PauseOverlay` (buttons + `AppToggleRow`s bound to `AudioService.settings`), `GameOverOverlay`. Still inline and promotable when a second consumer appears: the gold `RecordBadge` chip (game-over overlay) and the «next ball» circle (HUD).

---

## § 2 — Composition Rules

### 2.1 Screen → Form split

A feature screen is two files: the **Screen** is a thin `BlocProvider` shell, the **Form** owns layout.

```dart
// features/lib/game/screen/game_screen.dart (real code)
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GameCubit>(
      lazy: false,
      create: (BuildContext context) => GameCubit(
        statsRepository: appLocator<StatsRepository>(),
      ),
      child: const GameForm(),
    );
  }
}
```

`MenuScreen` is the exception (a `StatefulWidget` calling the repository directly, with an `AnimationController` for the staggered entrance and a `ValueListenableBuilder` on `AudioService.settings` for the 🔊/🔇 button) — treat it as debt, not a pattern; new screens get a cubit.

### 2.2 One public widget per file

File name = snake_case of the widget. Small private helper widgets may live below the public one in the same file (`_SecondaryButton` in `pause_overlay.dart`). Once a helper is needed from a second file — promote it to its own public file (feature `widgets/` or `core_ui`).

### 2.3 No widget-returning methods

`Widget _buildHeader()` / `List<Widget> _items()` are forbidden. Inline the subtree in `build()` (local `final`s, `if (...) ...<Widget>[...]` spreads) or extract a widget class.

### 2.4 Where extracted widgets live

- Feature-local → `features/lib/{feature}/widgets/{feature}_{name}.dart` (flat folder, files prefixed with the feature name: `game_hud.dart`, `game_over_overlay.dart`).
- Shared / design-system → `core_ui/lib/src/widgets/{name}.dart` + export in `widgets.dart`; `///` doc comment describing the mockup element.

### 2.5 Child widgets and cubit access

Children under the same `BlocProvider` read the cubit themselves: `context.read<GameCubit>()` for callbacks, `context.watch<GameCubit>().state` (or `BlocBuilder`) for rebuilds — see `GameHud`. Pure presentational widgets take plain values + callbacks (`GameOverOverlay(score:, bestScore:, isNewRecord:, onRestart:, …)`), never the cubit.

### 2.6 Feature folder layout

```
features/lib/{feature}/
├── cubit/
│   ├── {feature}_cubit.dart
│   └── {feature}_state.dart        # part of '{feature}_cubit.dart'
├── screen/
│   ├── {feature}_screen.dart       # BlocProvider shell
│   └── {feature}_form.dart         # layout
├── widgets/                        # optional, flat
└── engine/                         # game only: Flame / Forge2D code
```

Export the screen from `features/lib/features.dart` — `navigation/` imports screens only through this barrel.

### 2.7 Game engine boundary

`features/lib/game/engine/wasdrop_game.dart` (`WasDropGame extends Forge2DGame`) owns physics, input (drag = aim, release / tap = drop) and rendering of balls (`BallBody`). It talks to the cubit through explicit calls only: `cubit.onDropped()`, `cubit.onMerge(tier)`, `cubit.gameOver()`, and reads `cubit.state.current` for the hanging ball. Jar decorations (dashed deadline, hanging ball, dashed aim line via `world.castRayClosest`) are drawn by the private `_JarOverlay` world component (priority 10, world units) — never in screen space. Merge effects live in `engine/merge_effects.dart` (`MergeFlash` priority 20, `ScorePopup` priority 21): self-removing world components driven by `update(dt)`; the merged ball itself pops in via `BallBody(popIn: true)`. The Form sets `_game.paused` from `state.status` and calls `_game.reset()` on restart. Keep UI (overlays, HUD) in Flutter widgets, not in Flame components.

---

## § 3 — Text & Localization

There is **no localization layer** — all UI copy is Russian string literals in widgets (`'ИГРАТЬ'`, `'ПАУЗА'`, `'РЕКОРД $n'`, `'В меню'`). Rules until `easy_localization` (or similar) is introduced:

- Keep copy in the widget that renders it; cubits/engine never produce user-visible text.
- Uppercase labels are written uppercase in the literal (no `toUpperCase()`), matching the mockups.
- Numbers are formatted by plain interpolation (`'$score'`); scores are ints.
- Code comments may be Russian or English — keep each file consistent; identifiers are English.

---

## § 4 — Code Style

### 4.1 Hard rules

- Lints: `package:flutter_lints/flutter.yaml` (root `analysis_options.yaml`, `*.g.dart` excluded). Formatter: default `dart format` (80 columns) — run it before committing.
- **Explicit types** — `final GameCubit cubit = …`, `<Widget>[…]`, `(BuildContext context, GoRouterState state) =>`. The codebase is written this way even though the lint doesn't enforce it.
- **Named parameters** for widgets and models; `required` first, then defaults, then nullable, then `super.key` (see `BallView`, `GameOverOverlay`).
- Fields **before** the constructor; `const` constructors everywhere possible.
- **Imports:** relative inside a package (`'../cubit/game_cubit.dart'`), package imports across packages (`package:core/core.dart`, `package:core_ui/core_ui.dart`, `package:domain/domain.dart`). `package:core/core.dart` re-exports flutter_bloc, equatable, get_it, go_router, `navigation`, `appLocator`, `AppConfig`, `RouterConstants`, `StorageConstants` — one import covers them.
- File suffixes: `*_model.dart`, `*_repository.dart` / `*_repository_impl.dart`, `*_hive_provider.dart`, `*_cubit.dart`, `*_state.dart`, `*_screen.dart`, `*_form.dart`.

### 4.2 Domain models — plain `Equatable` (no freezed)

```dart
class GameStatsModel extends Equatable {
  final int bestScore;
  final int gamesPlayed;

  const GameStatsModel({required this.bestScore, required this.gamesPlayed});

  const GameStatsModel.empty() : this(bestScore: 0, gamesPlayed: 0);

  GameStatsModel copyWith({int? bestScore, int? gamesPlayed}) { … }

  @override
  List<Object?> get props => <Object?>[bestScore, gamesPlayed];
}
```

Every model has `.empty()` (the "no data yet" value) and a manual `copyWith`. Enums with behaviour live in `domain/lib/enums/` (`BallTier`: `number`, `mergeScore`, `emoji`, `next`). Export from `domain/lib/domain.dart`.

### 4.3 Repositories — interface in `domain`, Hive impl in `data`

```dart
// domain/lib/repositories/stats_repository.dart
abstract interface class StatsRepository {
  Future<GameStatsModel> getStats();
  Future<void> saveStats(GameStatsModel stats);
}

// data/lib/providers/local/stats_hive_provider.dart — thin wrapper over one Box<dynamic>
class StatsHiveProvider {
  final Box<dynamic> _box;
  StatsHiveProvider(this._box);
  int get bestScore => (_box.get('bestScore') as int?) ?? 0;
  Future<void> save({required int bestScore, required int gamesPlayed}) => _box.putAll(…);
}

// data/lib/repositories/stats_repository_impl.dart — maps provider ↔ model
class StatsRepositoryImpl implements StatsRepository { … }
```

Box names: `StorageConstants` (`core/lib/constants/storage_constants.dart`) — note `data` cannot import `core` (core depends on data), so `DataDI.init()` repeats the literals; keep both in sync.

### 4.4 DI — `DataDI.init()` + `setupAppScope(flavor)`

`data/lib/di/data_di.dart` opens the Hive boxes and registers providers + repositories as lazy singletons on `GetIt.instance`. `core/lib/di/app_di.dart` → `setupAppScope(Flavor)` registers `AppConfig`, calls `dataDI.init()` and `setupNavigationDependencies()` (registers `AppRouter`). Read anything via `appLocator<T>()`.

### 4.5 Cubit + State

```dart
class GameCubit extends Cubit<GameState> {
  final StatsRepository statsRepository;

  GameCubit({required this.statsRepository}) : super(const GameState(…)) {
    _init();
  }
  …
}

// game_state.dart
part of 'game_cubit.dart';

enum GameStatus { playing, paused, gameOver }

class GameState extends Equatable {
  final int score;
  final GameStatus status;
  …
  GameState copyWith({…}) { … }
  @override
  List<Object?> get props => <Object?>[…];
}
```

- Repositories are **constructor-injected** (resolved with `appLocator<X>()` at the `BlocProvider` create site) — this makes cubits testable with fakes.
- State: one `Equatable` class in a `part of` file, manual `copyWith`, all fields in `props`. A status enum (`GameStatus`) is used for mutually exclusive screen modes; booleans (`isNewRecord`) for independent flags.
- Async work started from the constructor (`_init()`) must guard `emit` after `close()` — add `if (isClosed) return;` before emitting in async callbacks.
- Navigation from widgets: `context.goNamed('menu')` (route names `'menu'` / `'game'`, paths in `RouterConstants`). From cubits: `appLocator<AppRouter>().router.goNamed(…)`.

### 4.6 Navigation — go_router, no codegen

`navigation/lib/src/app_router/app_router.dart`: `AppRouter` wraps a `GoRouter` (`initialLocation: '/menu'`, global `navigatorKey`, `_fade` custom transition 400 ms). Add a route = add a constant to `RouterConstants` (`core/lib/constants/route_constants.dart`) + a `GoRoute(path:, name:, pageBuilder: _fade(…))` + export the screen from `features.dart`. Overlays (pause, game over) are widgets inside `GameForm`, **not** routes.

### 4.7 Audio & haptics — `AudioService`

`core/lib/services/audio_service.dart`, registered in `appLocator` by `setupAppScope`. Holds `settings` (`ValueNotifier<SettingsModel>`) and persists it via `SettingsRepository`; `setSoundOn` / `setHapticsOn` are what toggles call. Game events go through the cubit (`GameCubit` takes `audio` in its constructor): `drop()`, `merge(tier)`, `gameOver(isRecord:)`; button taps arrive via `ButtonFeedback`. Music: `FlameAudio.bgm` loop started in `init()` when sound is on. Assets: `core/resources/audio/` (placeholders from `script/gen_placeholder_audio.py`; keep file names when replacing). Engine code never touches audio.

### 4.8 Flavors

`Flavor { dev, prod }` + `AppConfig` in `core/lib/config/app_config.dart`; `lib/main.dart` reads `--dart-define=environment` (fallback: native `appFlavor`). `AppConfig.isDev` drives the «DEV» `Banner` in `lib/app.dart` and `useTestAds`. Feature code reads `appLocator<AppConfig>()`; never branch on `kDebugMode` for environment-specific behaviour.

### 4.9 Static analysis + formatting

```bash
flutter analyze
dart format core core_ui data domain features lib navigation
```

No codegen today (`script/prebuild_script.sh` runs `build_runner` only in packages that declare it).
