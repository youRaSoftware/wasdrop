import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../game/engine/fruit_assets.dart';

/// Цепочка слияний: 11 фруктов по росту с названиями, горизонтальный
/// скролл. Шары стоят на одной линии, между ними шевроны.
class FruitChain extends StatelessWidget {
  static const double minDiameter = 28;
  static const double maxDiameter = 64;

  const FruitChain({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle caption = AppFonts.best.copyWith(
      fontSize: 10,
      letterSpacing: 0,
      color: AppColors.textSecondary,
    );

    // Кадр спрайта выступает за рамку BallView на (spriteFrameScale − 1) / 2
    // диаметра с каждой стороны; без запаса скролл обрезал бы арбуз в конце
    // (и вишню в начале) и макушки самых крупных фруктов.
    const double overflow = (BallView.spriteFrameScale - 1) / 2 * maxDiameter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(overflow, overflow, overflow, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final BallTier tier in BallTier.values) ...<Widget>[
            if (tier != BallTier.t1)
              const Padding(
                padding: EdgeInsets.only(bottom: 22),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BallView(
                  tier: tier,
                  diameter: minDiameter +
                      (maxDiameter - minDiameter) *
                          tier.index /
                          (BallTier.values.length - 1),
                  image: FruitAssets.idle(tier),
                ),
                const SizedBox(height: 6),
                Text(tier.title, style: caption),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
