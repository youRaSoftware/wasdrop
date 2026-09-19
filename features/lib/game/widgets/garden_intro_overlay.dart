import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../engine/special_sprites.dart';

/// Справка «Сада чудес» при первом входе: четыре строки «спрайт → что
/// делает» и одна кнопка. Движок стоит, пока открыта.
class GardenIntroOverlay extends StatelessWidget {
  static const Key okKey = Key('garden_intro_ok');

  final VoidCallback onDone;

  const GardenIntroOverlay({required this.onDone, super.key});

  static Widget sprite(SpecialKind kind, double size) => Image.asset(
        'assets/images/${SpecialSprites.fileName(kind, 'idle')}',
        package: SpecialSprites.package,
        width: size,
        height: size,
      );

  @override
  Widget build(BuildContext context) {
    const List<(SpecialKind, String)> rows = <(SpecialKind, String)>[
      (SpecialKind.rainbow, LocaleKeys.garden_rainbow),
      (SpecialKind.bubble, LocaleKeys.garden_bubble),
      (SpecialKind.rotten, LocaleKeys.garden_rotten),
      (SpecialKind.ice, LocaleKeys.garden_ice),
    ];
    return AppOverlay(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Text(
              context.tr(LocaleKeys.garden_title),
              style: AppFonts.overlayTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(LocaleKeys.garden_intro),
            textAlign: TextAlign.center,
            style: AppFonts.best.copyWith(
              fontSize: 13,
              height: 1.3,
              color: AppColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          for (final (SpecialKind kind, String key) in rows) ...<Widget>[
            Row(
              children: <Widget>[
                sprite(kind, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(key),
                    style: AppFonts.best.copyWith(
                      fontSize: 13,
                      height: 1.25,
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          PrimaryButton(
            key: okKey,
            label: context.tr(LocaleKeys.garden_ok),
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}
