import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/game_theme.dart';
import 'app_pressable.dart';

/// Ряд кружков-превью тем (пауза, настройки): градиент фона темы, внутри —
/// «стакан» на обводке стенки; выбранная — кольцо `accent`; закрытая —
/// с замком и без реакции на тап. Ключ кружка — `Key('theme_<id>')`.
class ThemePicker extends StatelessWidget {
  static const double dotSize = 34;
  static const double gap = 8;

  final List<GameTheme> themes;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const ThemePicker({
    required this.themes,
    required this.selectedId,
    required this.onSelect,
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
            selected: themes[i].id == selectedId,
            onSelect: onSelect,
          ),
        ],
      ],
    );
  }
}

class _ThemeDot extends StatelessWidget {
  final GameTheme theme;
  final bool selected;
  final ValueChanged<String> onSelect;

  const _ThemeDot({
    required this.theme,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double size = ThemePicker.dotSize;

    return Semantics(
      label: theme.name,
      selected: selected,
      button: true,
      child: AppPressable(
        onPressed: theme.isLocked ? null : () => onSelect(theme.id),
        builder: (BuildContext context, double pressed, Widget? _) {
          return Transform.scale(
            scale: 1 - 0.08 * pressed,
            child: Container(
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
              child: theme.isLocked
                  ? Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: theme.hudText.withValues(alpha: 0.8),
                    )
                  : Container(
                      width: size * 0.44,
                      height: size * 0.44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.jarFill,
                        border: Border.all(color: theme.jarWall, width: 1.5),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
