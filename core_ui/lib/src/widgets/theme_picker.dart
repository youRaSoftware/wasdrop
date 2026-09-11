import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/game_theme.dart';
import 'app_pressable.dart';

/// Ряд кружков-превью тем (пауза, настройки): градиент фона темы, внутри —
/// «стакан» на обводке стенки; выбранная — кольцо `accent`. Темы из
/// [lockedIds] рисуются с замком-бейджем, тап по ним зовёт [onLockedTap]
/// (paywall), а не [onSelect]. Ключ кружка — `Key('theme_<id>')`.
class ThemePicker extends StatelessWidget {
  static const double dotSize = 34;
  static const double gap = 8;

  final List<GameTheme> themes;
  final String selectedId;
  final ValueChanged<String> onSelect;

  /// Локализованное имя темы для доступности (core_ui переводов не знает).
  final String Function(GameTheme theme) labelOf;

  /// Темы, недоступные без премиума.
  final Set<String> lockedIds;
  final VoidCallback? onLockedTap;

  const ThemePicker({
    required this.themes,
    required this.selectedId,
    required this.onSelect,
    required this.labelOf,
    this.lockedIds = const <String>{},
    this.onLockedTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < themes.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: gap),
          _ThemeDot(
            key: Key('theme_${themes[i].id}'),
            theme: themes[i],
            label: labelOf(themes[i]),
            selected: themes[i].id == selectedId,
            locked: lockedIds.contains(themes[i].id),
            onPressed: lockedIds.contains(themes[i].id)
                ? onLockedTap
                : () => onSelect(themes[i].id),
          ),
        ],
      ],
    );
  }
}

class _ThemeDot extends StatelessWidget {
  static const double badgeSize = 16;

  final GameTheme theme;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback? onPressed;

  const _ThemeDot({
    required this.theme,
    required this.label,
    required this.selected,
    required this.locked,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double size = ThemePicker.dotSize;

    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: AppPressable(
        onPressed: onPressed,
        builder: (BuildContext context, double pressed, Widget? _) {
          return Transform.scale(
            scale: 1 - 0.08 * pressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: theme.background,
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.stroke,
                        width: selected ? 2.5 : 1.5,
                      ),
                      boxShadow: selected
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: AppColors.panelShadow,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Container(
                      width: size * 0.44,
                      height: size * 0.44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.jarFill,
                        border: Border.all(color: theme.jarWall, width: 1.5),
                      ),
                    ),
                  ),
                  if (locked)
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: badgeSize,
                        height: badgeSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.stroke, width: 1),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
