---
name: create-feature-full
description: "WasDrop Flutter project skill for creating a complete feature end to end: domain model + repository interface + Hive provider + repository impl + DI registration + cubit/state + screen/form + route. Triggers when user asks to: сделать полную фичу, фичу от и до, фичу целиком, create a full feature, build a feature end to end, add persisted data / сохранять на устройстве / новый Hive-бокс — AND names data that must be stored (fields, box) AND mentions screens/UI. Do NOT trigger when only UI with existing repositories or mocks is needed (use create-feature-ui), for a single reusable widget (use create-widget), or when only the data layer is needed because screens exist (follow this skill's Data Layer section manually)."
argument-hint: "[feature_name] [stored fields] [screens]"
---

# Create Full Feature (Data Layer + UI)

Use when: both persisted data (a Hive box / new repository) and UI screens need to be created together.

## REQUIRED READING — do this BEFORE generating any code

Read **`.claude/shared/wasdrop_ui_reference.md`** in full — § 4.2–4.5 describe the exact model / repository / provider / DI / cubit shapes used here. Screen spec: `.claude/my_docs/WASDROP.md`.

## Template

```
Create full feature: {feature_name}
Data: {fields to persist, e.g. "daily best per date: Map<String,int>", box name}
Screens: {list of screens, mockup frame numbers}

Follow WasDrop full feature patterns.
```

## How WasDrop stores data

There is **no network**. All persistence is local Hive (`hive` + `hive_flutter`, untyped `Box<dynamic>` with primitive values — no adapters, no codegen today):

```
Hive Box<dynamic>  →  {Name}HiveProvider (data/lib/providers/local/)   — typed getters + save()
                   →  {Name}RepositoryImpl (data/lib/repositories/)    — provider ↔ domain model
                   →  {Name}Repository interface (domain/lib/repositories/)
                   →  Cubit (constructor-injected repository)  →  Equatable State  →  Screen (BlocProvider) → Form
```

Existing pairs: `StatsHiveProvider` / `StatsRepositoryImpl` (`statsBox`), `SettingsHiveProvider` / `SettingsRepositoryImpl` (`settingsBox`). Copy their shape.

Prefer **one box per aggregate** (stats, settings, …) with string keys per field. Only reach for `TypeAdapter`s / `hive_generator` when a list of structured records must be stored — then add `build_runner` to `data/pubspec.yaml` (`script/prebuild_script.sh` will pick it up automatically) and document it in CLAUDE.md.

## Creation order

1. Domain model — `domain/lib/models/{name}_model.dart` + export in `domain/lib/domain.dart`
2. Repository interface — `domain/lib/repositories/{name}_repository.dart` + export
3. Box name — `core/lib/constants/storage_constants.dart` (and the same literal in `DataDI.init()`, see § 4.3 of the reference)
4. Hive provider — `data/lib/providers/local/{name}_hive_provider.dart` + export in `local_providers.dart`
5. Repository impl — `data/lib/repositories/{name}_repository_impl.dart` + export in `repositories.dart`
6. DI — `data/lib/di/data_di.dart`: open the box, register provider + repository
7. State, Cubit, Screen, Form, widgets — as in `create-feature-ui` §§ 2–6
8. Route + barrel — `RouterConstants`, `app_router.dart`, `features.dart`

---

## Data layer

### Domain model (`domain/lib/models/{name}_model.dart`)

Plain `Equatable`, `.empty()`, manual `copyWith`, all fields in `props` (no freezed):

```dart
import 'package:equatable/equatable.dart';

class DailyStatsModel extends Equatable {
  final int todayBest;
  final int streakDays;
  final DateTime? lastPlayedAt;

  const DailyStatsModel({
    required this.todayBest,
    required this.streakDays,
    this.lastPlayedAt,
  });

  const DailyStatsModel.empty() : this(todayBest: 0, streakDays: 0);

  DailyStatsModel copyWith({int? todayBest, int? streakDays, DateTime? lastPlayedAt}) {
    return DailyStatsModel(
      todayBest: todayBest ?? this.todayBest,
      streakDays: streakDays ?? this.streakDays,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[todayBest, streakDays, lastPlayedAt];
}
```

Business rules (e.g. "is the streak still alive") are getters on the model, not in the cubit.

### Repository interface (`domain/lib/repositories/{name}_repository.dart`)

```dart
import '../models/daily_stats_model.dart';

abstract interface class DailyStatsRepository {
  Future<DailyStatsModel> getDailyStats();
  Future<void> saveDailyStats(DailyStatsModel stats);
}
```

`Future` getters + `save`. Add `Stream<T> watch…()` (backed by `box.watch()`) only when two screens must observe the same value live.

### Hive provider (`data/lib/providers/local/{name}_hive_provider.dart`)

Thin wrapper over one `Box<dynamic>`; typed getters with defaults, one `save()` doing `putAll`. Store only primitives (`int`, `bool`, `String`, `double`, ISO-8601 strings for dates).

```dart
import 'package:hive/hive.dart';

class DailyStatsHiveProvider {
  final Box<dynamic> _box;

  DailyStatsHiveProvider(this._box);

  int get todayBest => (_box.get('todayBest') as int?) ?? 0;
  int get streakDays => (_box.get('streakDays') as int?) ?? 0;
  String? get lastPlayedAt => _box.get('lastPlayedAt') as String?;

  Future<void> save({required int todayBest, required int streakDays, String? lastPlayedAt}) async {
    await _box.putAll(<String, Object?>{
      'todayBest': todayBest,
      'streakDays': streakDays,
      'lastPlayedAt': lastPlayedAt,
    });
  }
}
```

Export from `data/lib/providers/local/local_providers.dart`.

### Repository impl (`data/lib/repositories/{name}_repository_impl.dart`)

Maps provider ↔ model; date parsing lives here.

```dart
import 'package:domain/domain.dart';

import '../providers/local/daily_stats_hive_provider.dart';

class DailyStatsRepositoryImpl implements DailyStatsRepository {
  final DailyStatsHiveProvider _provider;

  DailyStatsRepositoryImpl(this._provider);

  @override
  Future<DailyStatsModel> getDailyStats() async {
    final String? raw = _provider.lastPlayedAt;
    return DailyStatsModel(
      todayBest: _provider.todayBest,
      streakDays: _provider.streakDays,
      lastPlayedAt: raw == null ? null : DateTime.tryParse(raw),
    );
  }

  @override
  Future<void> saveDailyStats(DailyStatsModel stats) {
    return _provider.save(
      todayBest: stats.todayBest,
      streakDays: stats.streakDays,
      lastPlayedAt: stats.lastPlayedAt?.toIso8601String(),
    );
  }
}
```

Export from `data/lib/repositories/repositories.dart`.

### DI (`data/lib/di/data_di.dart`)

```dart
final Box<dynamic> dailyStatsBox = await Hive.openBox<dynamic>('dailyStatsBox');

locator.registerLazySingleton<DailyStatsHiveProvider>(
  () => DailyStatsHiveProvider(dailyStatsBox),
);
locator.registerLazySingleton<DailyStatsRepository>(
  () => DailyStatsRepositoryImpl(locator<DailyStatsHiveProvider>()),
);
```

Also add `static const String dailyStatsBox = 'dailyStatsBox';` to `StorageConstants`. Missing registration = crash on first `appLocator<X>()`.

---

## Presentation layer

Follow `create-feature-ui` §§ 2–7 exactly: `part of` state, constructor-injected repository, `_safeEmit`, thin screen, `AppScaffold` form, flat `widgets/`, route constant + `GoRoute` + barrel export.

Cubit rules specific to persisted data:
- Optimistic update: emit the new state first, then `await repository.save(...)`; on failure re-read from the repository and emit.
- Never read Hive from widgets — only through the cubit.
- If the game engine must react (e.g. new best mid-game), the cubit exposes a method the engine calls (`onMerge`, `gameOver` pattern in `GameCubit`), never the reverse.

---

## After creation

```bash
flutter analyze
dart format domain/lib data/lib core/lib features/lib/{feature} navigation/lib
```

Only if `TypeAdapter`s were introduced: `cd data && dart run build_runner build --delete-conflicting-outputs` (or `script/prebuild_script.sh`).

Then update `.claude/plans/plan.md` (tick the item) and add a user-facing line to `.claude/changelog/CHANGELOG.md` under `[Unreleased]`.
