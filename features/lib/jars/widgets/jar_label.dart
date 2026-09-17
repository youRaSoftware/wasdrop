import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

const Map<String, String> _jarKeys = <String, String>{
  'classic': LocaleKeys.jars_classic,
  'vase': LocaleKeys.jars_vase,
  'bowl': LocaleKeys.jars_bowl,
  'shelf': LocaleKeys.jars_shelf,
  'flask': LocaleKeys.jars_flask,
  'slope': LocaleKeys.jars_slope,
  'hourglass': LocaleKeys.jars_hourglass,
  'swing': LocaleKeys.jars_swing,
};

/// Локализованное название стакана (`jars.<id>`); неизвестный id — сам id.
String jarLabel(BuildContext context, JarShape jar) {
  final String? key = _jarKeys[jar.id];
  return key == null ? jar.id : context.tr(key);
}
