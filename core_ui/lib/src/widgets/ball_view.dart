import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Статичный шар для HUD/меню (в игре шары рисует движок).
class BallView extends StatelessWidget {
  final BallTier tier;
  final double diameter;
  final bool showEmoji;

  const BallView({
    required this.tier,
    required this.diameter,
    this.showEmoji = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.tiers[tier.index];

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.12)!,
          ],
          stops: const <double>[0, 0.72, 1],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x3333291A),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        showEmoji ? tier.emoji : '${tier.number}',
        style: TextStyle(fontSize: diameter * (showEmoji ? 0.5 : 0.42)),
      ),
    );
  }
}
