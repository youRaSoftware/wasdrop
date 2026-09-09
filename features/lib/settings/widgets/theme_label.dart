import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/widgets.dart';

const Map<String, String> _themeKeys = <String, String>{
  'cream': LocaleKeys.themes_cream,
  'sunset': LocaleKeys.themes_sunset,
  'mint': LocaleKeys.themes_mint,
  'night': LocaleKeys.themes_night,
  'rose': LocaleKeys.themes_rose,
  'sky': LocaleKeys.themes_sky,
};

/// Локализованное название темы-обоев (`themes.<id>`); неизвестный id —
/// сам id. Через [context], чтобы виджет перестраивался при смене языка.
String themeLabel(BuildContext context, GameTheme theme) {
  final String? key = _themeKeys[theme.id];
  return key == null ? theme.id : context.tr(key);
}
