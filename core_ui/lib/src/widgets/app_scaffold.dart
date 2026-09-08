import 'package:flutter/material.dart';

import '../theme/app_theme_scope.dart';
import '../theme/game_theme.dart';
import 'theme_decor.dart';

/// Экран приложения: фон — градиент текущей темы (`AppThemeScope`) со
/// статичным декором под содержимым. Без app bar — экраны рисуют свой HUD.
class AppScaffold extends StatelessWidget {
  final Widget body;

  const AppScaffold({required this.body, super.key});

  @override
  Widget build(BuildContext context) {
    final GameTheme theme = AppThemeScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(decoration: BoxDecoration(gradient: theme.background)),
          ThemeDecorLayer(theme: theme),
          body,
        ],
      ),
    );
  }
}
