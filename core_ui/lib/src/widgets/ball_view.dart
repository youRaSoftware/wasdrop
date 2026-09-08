import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Статичный шар для HUD/меню (в игре шары рисует движок). С [image]
/// показывает спрайт фрукта (кадр 512×512, тело ≈ 70 % кадра, поэтому кадр
/// рисуется крупнее [diameter]); без него — градиентный круг с эмодзи.
class BallView extends StatelessWidget {
  /// Во сколько раз кадр спрайта больше тела фрукта.
  static const double spriteFrameScale = 1.4;

  final BallTier tier;
  final double diameter;
  final bool showEmoji;
  final ImageProvider? image;

  const BallView({
    required this.tier,
    required this.diameter,
    this.showEmoji = true,
    this.image,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = this.image;
    if (image != null) {
      final double frame = diameter * spriteFrameScale;
      return SizedBox(
        width: diameter,
        height: diameter,
        child: OverflowBox(
          maxWidth: frame,
          maxHeight: frame,
          child: Image(
            image: image,
            width: frame,
            height: frame,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    }

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
