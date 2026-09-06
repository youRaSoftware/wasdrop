---
name: create-feature-ui
description: "WasDrop Flutter project skill for creating a new UI feature (screen + cubit) without new persisted data. Triggers when user asks to: build a screen, create a feature, scaffold a feature, набросать экран, создать фичу, сделать UI, экран настроек, таблица рекордов — AND no new Hive box / repository is mentioned, or the data is mocked / hardcoded / on моках. Creates: state, cubit, screen, form, widgets, go_router route, features barrel export. Do NOT trigger when the feature needs a new repository or Hive storage (use create-feature-full), when the user asks for a single reusable widget (use create-widget), for Flame engine work, or to fix/refactor existing code."
argument-hint: "[feature_name] [description] [screens]"
---

# Create UI Feature (no new data layer)

Use when: the screen(s) only need existing repositories (`StatsRepository`, `SettingsRepository`), `AppConfig`, or mock data. When the real data lands, the cubit's `_init()` switches from mocks to a repository and everything else stays.

## REQUIRED READING — do this BEFORE generating any code

Read **`.claude/shared/wasdrop_ui_reference.md`** in full (tokens, widget inventory, composition rules, code style). For the screen's visual spec read the matching frame in `.claude/my_docs/WASDROP.md` § 2.

## Template

```
Create UI feature: {feature_name}
Description: {what it does}
Screens: {list of screens, mockup frame numbers}

Follow WasDrop UI feature patterns.
```

## 1. Folder

```
features/lib/{feature}/
├── cubit/
│   ├── {feature}_cubit.dart
│   └── {feature}_state.dart
├── screen/
│   ├── {feature}_screen.dart
│   └── {feature}_form.dart
└── widgets/                 # optional, flat, files prefixed {feature}_
```

Real reference: `features/lib/game/`.

## 2. State (`cubit/{feature}_state.dart`)

`part of` the cubit file. Single `Equatable` class, manual `copyWith`, all fields in `props`. Mutually exclusive modes → an enum next to the state (`GameStatus`); independent flags → booleans.

```dart
part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final bool isLoading;
  final SettingsModel settings;

  const SettingsState({
    this.isLoading = true,
    this.settings = const SettingsModel.empty(),
  });

  SettingsState copyWith({bool? isLoading, SettingsModel? settings}) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => <Object?>[isLoading, settings];
}
```

Domain models have `.empty()` — use it as the initial value instead of nullable fields.

## 3. Cubit (`cubit/{feature}_cubit.dart`)

Repositories are **constructor-injected** (resolved with `appLocator<X>()` at the `BlocProvider` create site, like `GameCubit`). Load in `_init()` from the constructor, or in a public `init()` called via `..init()` — pick one and be consistent within the feature. Guard emits after close.

```dart
import 'package:core/core.dart';
import 'package:domain/domain.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository settingsRepository;

  SettingsCubit({required this.settingsRepository}) : super(const SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    final SettingsModel settings = await settingsRepository.getSettings();
    _safeEmit(state.copyWith(isLoading: false, settings: settings));
  }

  Future<void> toggleSound(bool value) async {
    final SettingsModel updated = state.settings.copyWith(soundOn: value);
    _safeEmit(state.copyWith(settings: updated));
    await settingsRepository.saveSettings(updated);
  }

  void _safeEmit(SettingsState next) {
    if (isClosed) return;
    emit(next);
  }
}
```

Mock stage (no repository yet): keep the data as a `static const` list on the domain model or as a private const in the cubit, wrapped in `// --- MOCK: remove when <source> is ready ---` / `// --- END MOCK ---` markers.

Navigation: from widgets `context.goNamed('menu')`; from cubits `appLocator<AppRouter>().router.goNamed(...)`. Route names are the string names registered in `app_router.dart`; paths live in `RouterConstants`.

## 4. Screen (`screen/{feature}_screen.dart`)

Thin `BlocProvider` shell, plain `StatelessWidget`, no annotations.

```dart
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../cubit/settings_cubit.dart';
import 'settings_form.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (BuildContext context) => SettingsCubit(
        settingsRepository: appLocator<SettingsRepository>(),
      ),
      child: const SettingsForm(),
    );
  }
}
```

Route params (if any) are public final fields on the screen, forwarded into the cubit constructor.

## 5. Form (`screen/{feature}_form.dart`)

`AppScaffold(body: SafeArea(...))`, `BlocBuilder` (or `context.watch`) for state, tokens from `AppColors` / `AppFonts` / `AppDimens`, widgets from `core_ui` (`PrimaryButton`, `IconCircleButton`, `BallView`). Loading → keep the layout and hide values (the app has no loader widget yet; add one via `create-widget` if a real loading state is needed).

```dart
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../cubit/settings_cubit.dart';

class SettingsForm extends StatelessWidget {
  const SettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsCubit cubit = context.read<SettingsCubit>();

    return AppScaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (BuildContext context, SettingsState state) {
            return Column(
              children: <Widget>[
                const SizedBox(height: 16),
                const Text('НАСТРОЙКИ', style: AppFonts.overlayTitle),
                // ...toggles bound to state.settings, calling cubit.toggleSound etc.
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: PrimaryButton(
                    label: 'ГОТОВО',
                    onPressed: () => context.goNamed('menu'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

`StatefulWidget` form only when it owns a controller (`AnimationController`, `ScrollController`, a Flame game instance like `GameForm`).

## 6. Widgets (`widgets/`)

Extract when reused twice inside the feature, when the form grows past a screenful of distinct sections, or for overlay panels. Flat folder, `{feature}_{name}.dart`. Cross-feature → `core_ui` via `create-widget`. Children read the cubit with `context.read` / `context.watch`; presentational widgets take values + callbacks.

## 7. Route

1. `core/lib/constants/route_constants.dart` — `static const String settings = '/settings';`
2. `navigation/lib/src/app_router/app_router.dart` — `GoRoute(path: RouterConstants.settings, name: 'settings', pageBuilder: (context, state) => _fade(context, state, const SettingsScreen()))`. Use `RouterConstants` for the path (existing routes still inline `'/menu'` / `'/game'` — migrate them when touching the file).
3. `features/lib/features.dart` — export the screen.

Overlays shown on top of the game (pause, game over, future «settings» sheet) are **widgets inside `GameForm`**, not routes.

## 8. Copy

All user-visible text is a Russian literal in the widget (no localization layer). Uppercase labels are written uppercase. Cubits never produce UI text.

## After creation

```bash
flutter analyze features navigation core
dart format features/lib/{feature} navigation/lib core/lib/constants
```

No codegen. If a new `AppColors` / `AppDimens` constant was needed, add it to `core_ui` — never inline hex values or magic sizes that the spec names.
