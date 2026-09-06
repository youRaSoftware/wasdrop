---
name: audit-section
description: "WasDrop Flutter project skill for a full pre-release audit of a feature across all layers: vertical analysis (Hive provider → RepositoryImpl → Domain Model → Cubit → State → Form/Widgets, plus the Flame/Forge2D engine for the game) PLUS horizontal analysis (duplicate logic, dead code, suboptimal patterns, architecture questions, spec conformance against .claude/my_docs/WASDROP.md). Triggers when user asks to: audit a section, аудит раздела / фичи, проверь перед релизом, pre-release check, полный аудит, проверь поток данных, check gameplay rules against the spec. User provides: feature path, spec/doc paths, optionally an output path."
argument-hint: "<section_name> — docs: <path_to_docs> feature: <path_to_feature> [output: <path_to_doc>]"
---

# Audit Section — Full Pre-Release Audit

Think like a senior engineer reviewing a game feature before store release.

**Two dimensions:**
1. **Vertical** (Steps 2–5) — trace the data and control chain through every layer and verify completeness, lifecycle safety and spec conformance.
2. **Horizontal** (Steps 6–9) — compare against sibling code and best practice: duplicates, dead code, suboptimal patterns, open architecture questions.

## Required inputs

1. **Section name** — e.g. "Game", "Menu", "Settings"
2. **Feature path** — e.g. `features/lib/game/`
3. **Documentation** — `.claude/my_docs/WASDROP.md` (always) + any feature doc from `analyze-feature`
4. **UI reference** — always `.claude/shared/wasdrop_ui_reference.md`
5. **Output path** (optional) — default `.claude/my_docs/{section_name}_audit.md`

Ask for missing inputs before starting.

## The WasDrop vertical chain

```
Hive Box<dynamic> → {Name}HiveProvider (typed getters, save) → {Name}RepositoryImpl → {Name}Repository (domain)
→ Cubit (constructor-injected repositories, _safeEmit) → Equatable State (part of)
→ Screen (BlocProvider) → Form (AppScaffold, BlocBuilder / context.watch) → widgets
[game only] WasDropGame (Forge2D) ⇄ GameCubit: engine calls onDropped / onMerge / gameOver; form sets paused / reset()
[config] AppConfig (flavor) read via appLocator
```

## Process

### Step 0: Parse arguments, read docs

Read all documentation and the UI reference. Build the expected behaviour: screens (WASDROP.md § 2), gameplay rules (§ 3: radii, weights 5:4:3:2:1, cooldown 450 ms, deadline 1.5 s, score `2^tier`, t11 jackpot), tokens (§ 1).

### Step 1: Collect files (up to 3 Explore agents in parallel)

- **Agent 1 — domain + data:** models, enums, repository interfaces, Hive providers, repository impls, `data_di.dart`, `storage_constants.dart`
- **Agent 2 — presentation:** cubit, state, screen, form, widgets, `app_router.dart`, `route_constants.dart`, `features.dart`, `core_ui` widgets used
- **Agent 3 — engine + siblings:** `features/lib/game/engine/*` (if the section is the game or interacts with it); sibling feature(s) for horizontal comparison (`menu` vs `game`; any other feature with a cubit)

### Step 2: Audit data layer

- **Provider:** every key has a typed getter with a default; `save()` writes every field; primitive values only; key strings consistent between getter and `save`
- **Repository impl:** maps EVERY model field both ways (a field missing from `save` is silently reset — CRITICAL); date/enum conversion is symmetric
- **Box names:** identical in `StorageConstants` and `DataDI.init()`; box opened before registration
- **DI:** provider + repository registered as lazy singletons; interface → impl; nothing resolved before `dataDI.init()` completes

### Step 3: Audit domain

- Model: `Equatable`, `.empty()`, `copyWith` covers all fields, `props` lists all fields (a missing prop suppresses rebuilds — MEDIUM)
- Business rules live on models / enums (`BallTier.mergeScore`, `next`), not duplicated in cubit or engine
- Repository interface: only methods that have callers (record extras for Step 7)

### Step 4: Audit Cubit / State / UI

#### 4.1 Spec conformance
- Screen contains every element of the mockup frame (HUD: score, record, next ball, pause; overlays: buttons, badge, divider, ad button, toggles)
- Gameplay constants match § 3 (radii list, tier weights, cooldown, deadline offset 38 and 1.5 s, score formula)
- Tokens: colors via `AppColors`, text via `AppFonts.copyWith`, sizes via `AppDimens` where a constant exists; hardcoded hex in features = LOW (existing scrims are known debt — list, don't duplicate)
- Tap targets ≥ 44

#### 4.2 Cubit
- Async work after `close()` guarded (`isClosed` check) — `GameCubit._init()` / `gameOver()` await the repository, then emit → must be guarded (MEDIUM)
- Every state transition reachable from UI / engine; no method both public and unused
- Persisted writes: best score saved on game over; `gamesPlayed` incremented once per game (double increment on `continueAfterAd` → restart? check)
- Randomness: `_rollTier` weights sum to the `nextInt` bound (15) — off-by-one = wrong distribution (MEDIUM)

#### 4.3 State
- Single `Equatable` in `part of` file; enum for exclusive modes; `copyWith` complete; `props` complete

#### 4.4 Engine (game section)
- `paused` honoured by physics stepping and input; `reset()` clears bodies and internal timers (`_overLineTime`, `_canDrop`)
- Drop cooldown enforced; aim clamped to `[radius, worldWidth - radius]`
- Merge: contact of two equal tiers spawns tier+1 at the midpoint exactly once (no double-merge on the same contact pair), calls `cubit.onMerge(tier)` once; t11 + t11 handled per spec
- Deadline: only **resting** balls above `deadlineY` count; timer resets when clear; `gameOver()` called once
- Engine never reads Hive or navigates; cubit never touches Flame types
- Leaks: `GameForm` disposes / detaches the game; no `Timer`s left running after `gameOver`

#### 4.5 Form / widgets
- Screen = thin `BlocProvider`; form owns layout; overlays rendered by `state.status`, not by navigation
- `context.watch` in a widget that rebuilds heavily (HUD) is fine; whole-form `context.watch` while the game runs = check for jank (LOW)
- One public widget per file; private helpers not duplicated across files (`_SecondaryButton` vs `core_ui`)

#### 4.6 Routing
- Route in `RouterConstants` + `GoRoute` with matching name; `goNamed` targets exist; leaving `/game` disposes the cubit and the game (no physics running in background)

### Step 5: Config & flavor
- Flavor-dependent behaviour goes through `AppConfig` (`isDev`, `useTestAds`), never `kDebugMode`
- Nothing dev-only (DEV banner, test ads) can leak into prod

### Step 6: Horizontal — duplicate logic
Compare against siblings: repeated overlay panel decoration (pause vs game over), repeated button styles, repeated repository/provider boilerplate. Output:

| File | Duplicated block | Boilerplate % | Recommendation |
|---|---|---|---|

### Step 7: Horizontal — dead / useless logic
- Repository methods with 0 callers; cubit methods unreferenced from UI/engine; empty stubs (`continueAfterAd` is a **known stub**, list under "Stubs", not "dead")
- Model fields carried through provider → model but never displayed or used (`gamesPlayed`?)
- Constants defined but unused (`StorageConstants` vs literal box names)

### Step 8: Horizontal — suboptimal logic
- Sequential awaits with no dependency (`Future.wait`)
- Reading the repository twice in one flow (`gameOver()` re-reads stats the cubit already holds)
- Per-frame allocations in engine `update()` / `render()`; per-contact logging
- Rebuild scope: `BlocBuilder` without `buildWhen` where the state has 5+ fields and the widget uses 1–2 (VERY LOW)
- `setState`-driven screens that should be cubits (`MenuScreen`)

### Step 9: Horizontal — questions for the team
Collect ambiguities as specific questions (architecture intent, performance intent, dead-code safety, pattern deviation, spec gaps like the t11 jackpot bonus). Present them **before** the issues table.

### Step 10: Compile the report

```markdown
# Audit: {SECTION_NAME}

**Date:** {date}
**Feature:** {FEATURE_PATH}
**Documentation:** {DOC_PATHS}
**Siblings compared:** {list}

## A. What works correctly
## B. Issues found
### CRITICAL / MEDIUM / LOW / VERY LOW
- **File:** path:lines
- **Issue:** …
- **Fix:** …
- **Why:** …
### RECOMMENDATION (technical debt)
- **File / Pattern / Suggestion / Impact**
## C. What is NOT an issue (false alarms dismissed)
## D. Fix summary table
| # | Severity | File | Issue | Fix |
## E. Implementation status
- Data layer / Domain / Cubit-State / Engine / UI / Routing / Spec conformance
## F. Horizontal analysis
### F.1 Duplicate logic  ### F.2 Dead logic  ### F.3 Suboptimal logic
## G. Questions for the team
| # | Category | Question | Context |
```

Severity:
- **CRITICAL** — data loss in provider/impl mapping, missing DI registration, crash (emit after close, null route), physics running after leaving the screen, double merge / double game over
- **MEDIUM** — wrong gameplay constant vs spec, wrong tier distribution, missing spec element, error swallowed, `props` incomplete
- **LOW** — UX polish, sequential awaits, hardcoded tokens, redundant re-reads
- **VERY LOW** — style, rebuild scope, naming
- **RECOMMENDATION** — duplication, promotable private widgets, `setState` screens

### Step 11: Save

Write to the output path (default `.claude/my_docs/{section_name}_audit.md`). If a feature doc exists in `.claude/my_docs/`, append an "Audit {date}" status section to it.
