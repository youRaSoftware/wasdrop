import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../game/engine/fruit_assets.dart';
import '../../game/widgets/jar_painter.dart';
import 'jar_label.dart';

/// Карточка стакана в пикере: миниатюра формы с тремя фруктами на дне,
/// название; закрытый — приглушён, с замком и ценой в звёздах; «скоро» —
/// без цены; выбранный — акцентная рамка.
class JarCard extends StatelessWidget {
  static const double previewWidth = 92;
  static const double previewHeight = 132;

  final JarShape jar;
  final bool selected;
  final bool unlocked;
  final VoidCallback onTap;

  const JarCard({
    required this.jar,
    required this.selected,
    required this.unlocked,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final GameTheme theme = AppThemeScope.of(context);
    return AppPressable(
      onPressed: onTap,
      builder: (BuildContext context, double pressed, Widget? _) {
        return Transform.scale(
          scale: 1 - 0.04 * pressed,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.panelRadius),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.stroke,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Opacity(
                  opacity: unlocked ? 1 : 0.45,
                  child: _Preview(jar: jar, theme: theme),
                ),
                const SizedBox(height: 10),
                Text(
                  jarLabel(context, jar),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.button.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                _Status(jar: jar, unlocked: unlocked),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Status extends StatelessWidget {
  final JarShape jar;
  final bool unlocked;

  const _Status({required this.jar, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppFonts.best.copyWith(
      color: AppColors.textSecondary,
      letterSpacing: 0,
    );
    if (jar.comingSoon) {
      return Text(context.tr(LocaleKeys.jars_comingSoon), style: style);
    }
    if (unlocked) {
      return const SizedBox(height: 14);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.lock_rounded,
            size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          context.tr(
            LocaleKeys.jars_locked,
            namedArgs: <String, String>{'n': '${jar.starsToUnlock}'},
          ),
          style: style,
        ),
      ],
    );
  }
}

/// Миниатюра: стакан тем же painter, что в игре, и три мелких фрукта у дна.
class _Preview extends StatelessWidget {
  final JarShape jar;
  final GameTheme theme;

  const _Preview({required this.jar, required this.theme});

  @override
  Widget build(BuildContext context) {
    const Size size = Size(JarCard.previewWidth, JarCard.previewHeight);
    const double wall = 3;
    final Rect inner = JarPainter.innerRect(size, wall);
    // Три фрукта у дна: по ширине просвета на своей высоте; в узком дне
    // (колба) средний поднимается выше и ложится на два нижних.
    const List<BallTier> tiers = <BallTier>[
      BallTier.t2,
      BallTier.t3,
      BallTier.t1,
    ];
    const double d = 22;
    final (double bl, double br) = jar.spanAt(1 - d / 2 / inner.height);
    final bool narrow = (br - bl) * inner.width < 3.2 * d;
    final List<Widget> fruits = <Widget>[];
    for (int i = 0; i < tiers.length; i++) {
      final double lift = i == 1 ? (narrow ? d * 0.8 : 6) : 0;
      final double ny = 1 - (d / 2 + lift) / inner.height;
      final (double l, double r) = jar.spanAt(ny);
      final double span = (r - l) * inner.width;
      final double left = inner.left + l * inner.width;
      final double cx = narrow && i != 1
          ? left + (i == 0 ? d / 2 : span - d / 2)
          : left + span * (0.25 + 0.25 * i);
      final double cy = inner.top + inner.height * ny;
      fruits.add(Positioned(
        left: cx - d / 2,
        top: cy - d / 2,
        child: BallView(
          tier: tiers[i],
          diameter: d,
          image: FruitAssets.idle(tiers[i]),
        ),
      ));
    }
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: JarPainter(
                shape: jar,
                fill: theme.jarFill.a < 1 ? AppColors.jar : theme.jarFill,
                wall: theme.jarWall,
                wallWidth: wall,
              ),
            ),
          ),
          ...fruits,
        ],
      ),
    );
  }
}
