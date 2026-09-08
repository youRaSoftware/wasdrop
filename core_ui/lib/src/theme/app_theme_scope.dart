import 'package:flutter/widgets.dart';

import 'game_theme.dart';

/// Текущая тема-обои для поддерева. Ставится один раз в `lib/app.dart`
/// (из `SettingsService.settings`), читается `AppScaffold`, HUD, меню и
/// стаканом через [AppThemeScope.of]. core_ui о DI не знает.
class AppThemeScope extends InheritedWidget {
  final GameTheme theme;

  const AppThemeScope({
    required this.theme,
    required super.child,
    super.key,
  });

  static GameTheme of(BuildContext context) {
    final AppThemeScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    return scope?.theme ?? GameThemes.cream;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) =>
      oldWidget.theme.id != theme.id;
}
