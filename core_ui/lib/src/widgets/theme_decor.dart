import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Статичный декор фона темы (ТЗ: звёзды, облака, лепестки) — рисуется один
/// раз под содержимым экрана, детерминированно (фиксированное зерно).
class ThemeDecorLayer extends StatelessWidget {
  final GameTheme theme;

  const ThemeDecorLayer({required this.theme, super.key});

  @override
  Widget build(BuildContext context) {
    if (theme.decor == ThemeDecor.none) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ThemeDecorPainter(theme.decor),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ThemeDecorPainter extends CustomPainter {
  final ThemeDecor decor;

  const _ThemeDecorPainter(this.decor);

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random random = math.Random(7);
    switch (decor) {
      case ThemeDecor.none:
        return;
      case ThemeDecor.stars:
        _stars(canvas, size, random);
      case ThemeDecor.clouds:
        _clouds(canvas, size, random);
      case ThemeDecor.petals:
        _petals(canvas, size, random);
    }
  }

  void _stars(Canvas canvas, Size size, math.Random random) {
    final Paint paint = Paint();
    for (int i = 0; i < 70; i++) {
      final Offset c = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final double r = 0.7 + random.nextDouble() * 1.3;
      paint.color = const Color(0xFFF2EFE6)
          .withValues(alpha: 0.35 + random.nextDouble() * 0.5);
      canvas.drawCircle(c, r, paint);
    }
    // Несколько крупных «искр».
    paint.color = const Color(0xFFF2EFE6).withValues(alpha: 0.75);
    for (int i = 0; i < 6; i++) {
      final Offset c = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * 0.7,
      );
      const double s = 4;
      canvas.drawLine(c - const Offset(s, 0), c + const Offset(s, 0),
          paint..strokeWidth = 1.2);
      canvas.drawLine(c - const Offset(0, s), c + const Offset(0, s), paint);
    }
  }

  void _clouds(Canvas canvas, Size size, math.Random random) {
    final Paint paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55);
    for (int i = 0; i < 6; i++) {
      final double cx = random.nextDouble() * size.width;
      final double cy = size.height * (0.06 + random.nextDouble() * 0.55);
      final double scale = 0.7 + random.nextDouble() * 0.8;
      final List<Offset> puffs = <Offset>[
        Offset(-26, 8),
        Offset(-8, -6),
        Offset(12, -2),
        Offset(30, 10),
      ];
      final List<double> radii = <double>[16, 22, 20, 15];
      for (int p = 0; p < puffs.length; p++) {
        canvas.drawCircle(
          Offset(cx, cy) + puffs[p] * scale,
          radii[p] * scale,
          paint,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy + 12 * scale),
            width: 80 * scale,
            height: 22 * scale,
          ),
          Radius.circular(11 * scale),
        ),
        paint,
      );
    }
  }

  void _petals(Canvas canvas, Size size, math.Random random) {
    final Paint paint = Paint();
    for (int i = 0; i < 22; i++) {
      final Offset c = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final double angle = random.nextDouble() * math.pi;
      final double scale = 0.7 + random.nextDouble() * 0.7;
      paint.color = const Color(0xFFF2A3BE)
          .withValues(alpha: 0.35 + random.nextDouble() * 0.35);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: 14 * scale, height: 7 * scale),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ThemeDecorPainter oldDelegate) =>
      oldDelegate.decor != decor;
}
