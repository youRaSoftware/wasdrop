import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Секция настроек: заголовок капсом (как «РЕКОРД» в HUD) и карточка
/// `surface` с обводкой 2 px `stroke`, в которой лежат строки.
class SettingsSection extends StatelessWidget {
  static const double radius = 20;

  final String title;
  final List<Widget> children;

  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final GameTheme theme = AppThemeScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: AppFonts.best.copyWith(color: theme.hudTextSecondary),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.stroke, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}
