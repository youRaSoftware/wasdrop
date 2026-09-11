import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG-иконки из `core_ui/assets/icons/` (24×24, штрих `textPrimary`
/// 1.8 px, заливки из палитры; `shake` и `bomb` — кнопки бонусов). Многоцветные, поэтому не перекрашиваются —
/// ставить на светлые подложки (`surface`, кнопки).
enum AppIcons {
  trophy('trophy'),
  soundOn('sound_on'),
  soundOff('sound_off'),
  settings('settings'),
  pause('pause'),
  restart('restart'),
  menuHome('menu_home'),
  adPlay('ad_play'),
  shake('shake'),
  bomb('bomb'),
  upgrade('upgrade'),
  crown('crown');

  final String file;

  const AppIcons(this.file);

  String get asset => 'assets/icons/$file.svg';
}

class AppIcon extends StatelessWidget {
  final AppIcons icon;
  final double size;

  const AppIcon(this.icon, {this.size = 24, super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.asset,
      package: 'core_ui',
      width: size,
      height: size,
    );
  }
}
