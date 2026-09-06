---
name: create-widget
description: "WasDrop Flutter project skill for creating a NEW reusable UI widget in core_ui/lib/src/widgets/. Triggers when user asks to: create a widget, make a component, сделать виджет, создать компонент, build a reusable button/toggle/badge/panel/chip/overlay card — for the shared design system (variant 1a «тёплый фруктовый»). Creates: StatelessWidget or StatefulWidget in core_ui using AppColors / AppFonts / AppDimens, plus the barrel export. Do NOT trigger when user asks for a full feature with screens (use create-feature-ui or create-feature-full), for Hive/repository work, for Flame engine components, or to fix/modify an existing widget."
argument-hint: "[widget_name] [description]"
---

# Create Reusable Widget

Use when: creating a new reusable UI component in `core_ui/lib/src/widgets/`.

## REQUIRED READING — do this BEFORE generating any code

Read **`.claude/shared/wasdrop_ui_reference.md`** in full — design tokens (`AppColors`, `AppFonts`, `AppDimens`), the widget inventory, composition rules and code style. Do not paraphrase from memory; the file is the source of truth. For the visual spec of a specific element also check `.claude/my_docs/WASDROP.md` § 1 «Компоненты».

## Template

```
Create a reusable widget: {widget_name}
Description: {what it does, variants, where it's used (which mockup frame)}

Follow WasDrop widget patterns.
```

## Location

`core_ui/lib/src/widgets/{widget_name}.dart` — the folder is flat (4 widgets today). Only create a subfolder when 3+ related widgets justify it. Add an `export` line to `core_ui/lib/src/widgets/widgets.dart` (alphabetical).

Before creating, check the inventory in the UI reference § 1.5 and `features/lib/*/widgets/` — a private helper may already exist there (e.g. `_SecondaryButton` in `pause_overlay.dart`) and should be **promoted** rather than duplicated: move it to `core_ui`, make it public, replace the private copy with the import.

## Naming

- Descriptive noun, no `App` prefix (existing: `PrimaryButton`, `IconCircleButton`, `BallView`, `AppScaffold` is the one exception).
- Enums attached to the widget go in the same file, **before** the widget class.

## Widget structure

Fields before the constructor. Parameter order: required → non-nullable with default → nullable → `super.key`. Imports: `package:flutter/material.dart` + relative `../theme/app_colors.dart` / `app_fonts.dart` / `app_dimens.dart` (as the existing widgets do); `package:domain/domain.dart` only when a domain type (`BallTier`) is needed.

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Secondary action button from the pause / game-over overlays
/// (mockup frames 5–6): flat `secondarySurface` pill with `secondaryText` label.
class SecondaryButton extends StatelessWidget {
  // 1. Required
  final String label;
  final VoidCallback onPressed;

  // 2. Defaults
  final double height;
  final bool isDisabled;

  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.isDisabled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Text(
            label,
            style: AppFonts.button.copyWith(color: AppColors.secondaryText, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
```

## Design system rules

- Colors only from `AppColors`; if a color is missing, **add a constant** to `app_colors.dart` (with the hex from the spec) — never inline `Color(0xFF…)`.
- Text styles only via `AppFonts.x.copyWith(...)`; tabular digits for anything numeric.
- Shared sizes from `AppDimens` (`buttonHeight`, `iconButtonSize`, `panelRadius`, `panelPadding`, `minTapTarget`); one-off paddings may be inline.
- Tap targets ≥ 44 px (`AppDimens.minTapTarget`).
- No `flutter_screenutil`, no theme provider — values are plain `const`, so `const EdgeInsets.all(AppDimens.panelPadding)` is correct.

## Widget type

`StatelessWidget` by default. `StatefulWidget` only for an `AnimationController` (press-scale / flash), a controller the widget owns, or a transient local toggle that has no business in cubit state.

Interactive widgets are built on `AppPressable` (`core_ui/lib/src/widgets/app_pressable.dart`): it animates the press amount 0…1 and hands it to your `builder`, fires `ButtonFeedback.trigger()` (sound + haptic, gated by settings) and then `onPressed`. Do not write your own `GestureDetector` + `AnimationController` for a button, and never call `HapticFeedback` or audio from core_ui.

## Composition rules

- One public widget per file; small private helpers may be co-located.
- No widget-returning methods — inline or extract a class.
- `///` doc comment on every public widget naming the mockup element / frame.
- Interactive widgets that take `onPressed` support `isDisabled` (tap suppressed + visual feedback).

## After creation

```bash
flutter analyze core_ui
dart format core_ui/lib/src/widgets/
```

No codegen, no localization step (copy is passed in as `String` props — the widget never owns user-visible text).
