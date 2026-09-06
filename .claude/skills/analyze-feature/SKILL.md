---
name: analyze-feature
description: "WasDrop Flutter project skill for deep-diving into an existing feature and producing a comprehensive architecture document. Triggers when user asks to: analyze a feature, проанализируй фичу, document feature architecture, создай документацию по фиче, опиши архитектуру, сделай полное описание фичи, describe what's implemented, what's the current state of X, расскажи что сделано в игре / меню / движке, restore context, нужен контекст по фиче. The output is a markdown file saved to .claude/my_docs/{feature_name}.md that serves as a complete context restoration document. Also trigger on phrases like 'что там с игрой?', 'напомни, как устроен движок', 'что сейчас в меню?'."
argument-hint: "[feature_name]"
---

# Analyze Feature — Generate Architecture Document

Produces a markdown document describing every layer of an existing feature so that work can resume in a fresh session without re-reading the code.

## Process

### Step 1: Identify the scope

- Feature root in `features/lib/` (`game/`, `menu/`, …); for `game` also `engine/` (Flame / Forge2D)
- Domain: `domain/lib/models/`, `domain/lib/enums/`, `domain/lib/repositories/`
- Data: `data/lib/providers/local/`, `data/lib/repositories/`, `data/lib/di/data_di.dart`
- Shared UI in `core_ui/lib/src/` (cross-check names against `.claude/shared/wasdrop_ui_reference.md`)
- Spec: `.claude/my_docs/WASDROP.md` (which frames / rules the feature implements)

### Step 2: Scan bottom-up

**Domain:** every model field with type and default, `.empty()` values, `copyWith`, getters with business logic; enums (`BallTier`: `mergeScore`, `emoji`, `next`); repository interfaces (method signatures).

**Data:** Hive provider keys and defaults, repository impl mapping, box name (both `StorageConstants` and the literal in `DataDI.init()`), DI registration.

**Presentation:** state fields / enum / `copyWith` / `props`; cubit constructor deps, every public method (trigger → effect), async guards; screen (`BlocProvider`, `lazy`), form layout (top → bottom, which core_ui widgets), each widget in `widgets/` (props, layout, private helpers).

**Engine (game only):** `WasDropGame` — world size, gravity, walls, input handling (drag / tap), drop cooldown, deadline logic, cubit calls (`onDropped`, `onMerge`, `gameOver`), `reset()`, `paused` handling; `BallBody` — radius from `AppDimens.ballRadii`, fixture params, rendering, merge detection.

**Navigation:** route path in `RouterConstants`, `GoRoute` + name in `app_router.dart`, transition, who navigates here (`goNamed` calls).

**Config:** anything read from `AppConfig` (flavor-dependent behaviour).

### Step 3: Write the document

Adapt the template — include only sections that exist. Match the level of detail of existing docs in `.claude/my_docs/`.

```markdown
# {Feature Name} — Full Architecture & Mechanics

## Overview
What it does, key capabilities, entry points (routes / buttons that lead here), spec frames covered.

## 1. Domain Layer
### Models — file, fields (type, default), .empty(), getters
### Enums
### Repository interfaces

## 2. Data Layer
### Hive providers — box name, keys, defaults
### Repository implementations — mapping notes
### DI registration

## 3. State
File, fields, enum, copyWith, props.

## 4. Cubit
Constructor deps, lifecycle (constructor _init / init()), methods table: Method | Trigger | Effect.
Emit-after-close guards.

## 5. Engine (game only)
World, bodies, input, cooldowns, deadline, cubit callbacks, reset/pause.

## 6. Screen & Navigation
Screen file, BlocProvider setup, route constant + GoRoute + name, transition, entry points.

## 7. Form
Layout top → bottom, core_ui widgets used, controllers owned, overlays and their conditions.

## 8. Widgets
Per widget: file, Stateless/Stateful (why), props, layout, private helpers.

## 9. User Flow
Step-by-step flows (→), one per scenario (play → merge → game over → restart, pause, …).

## 10. Key File Index
Tables: Domain | Data | Presentation | Engine | Navigation — file | purpose.

## 11. Config & Stubs
Flavor-dependent behaviour (AppConfig), mocks, TODO stubs (e.g. continueAfterAd).

## 12. Not Yet Implemented
TODOs from code and spec gaps (strike through items done since).
```

### Step 4: Save

Write to `.claude/my_docs/{feature_name}.md` (snake_case: `game.md`, `menu.md`, `game_engine.md`).

## Guidelines

- Full paths from the project root for every file.
- List every field and prop — no "several fields".
- Spatial layout descriptions (top / bottom / left / right, sizes, colors by `AppColors` name).
- Don't skip DI, barrel exports, route names, box keys — those are what people forget.
- Comments in the doc may be Russian (project docs are Russian); identifiers stay verbatim.
