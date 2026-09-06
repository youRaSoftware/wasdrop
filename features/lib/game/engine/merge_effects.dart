import 'dart:math' as math;

import 'package:core_ui/core_ui.dart';
import 'package:flame/components.dart' show Component;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

/// Вспышка слияния (мокап, кадр 4): расширяющееся белое кольцо и радиальное
/// свечение цветом нового тира в точке контакта. Живёт [duration] секунд и
/// удаляет себя сама.
class MergeFlash extends Component {
  static const double duration = 0.45;

  final Vector2 center;
  final double radius;
  final Color color;
  double _t = 0;

  MergeFlash({
    required Vector2 center,
    required this.radius,
    required this.color,
  })  : center = center.clone(),
        super(priority: 20);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final double p = (_t / duration).clamp(0.0, 1.0);
    final double eased = Curves.easeOutCubic.transform(p);
    final double fade = 1 - p;
    final Offset c = center.toOffset();

    // Свечение.
    final double glowRadius = radius * (1.2 + 0.9 * eased);
    canvas.drawCircle(
      c,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.55 * fade),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: glowRadius)),
    );

    // Кольцо.
    canvas.drawCircle(
      c,
      radius * (0.5 + 1.1 * eased),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, 5 * fade)
        ..color = AppColors.flash.withValues(alpha: fade),
    );
  }
}

/// Всплывающее «+N» над точкой слияния: выскакивает с overshoot, уплывает
/// вверх и гаснет во второй половине жизни.
class ScorePopup extends Component {
  static const double duration = 0.9;
  static const double rise = 44;

  final Vector2 start;
  final TextPainter _painter;
  double _t = 0;

  ScorePopup({required String text, required Vector2 start})
      : start = start.clone(),
        _painter = TextPainter(
          text: TextSpan(
            text: text,
            style: AppFonts.score.copyWith(
              fontSize: 22,
              color: AppColors.scoreGain,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
        super(priority: 21);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final double p = (_t / duration).clamp(0.0, 1.0);
    final double y = start.y - rise * Curves.easeOutCubic.transform(p);
    final double scale =
        0.7 + 0.3 * Curves.easeOutBack.transform(math.min(1, p * 2.5));
    final double alpha = p < 0.55 ? 1 : 1 - (p - 0.55) / 0.45;

    final Rect bounds = Rect.fromCenter(
      center: Offset(start.x, y),
      width: _painter.width * 2,
      height: _painter.height * 2,
    );
    canvas.saveLayer(
      bounds,
      Paint()..color = AppColors.flash.withValues(alpha: alpha),
    );
    canvas.translate(start.x, y);
    canvas.scale(scale);
    _painter.paint(canvas, Offset(-_painter.width / 2, -_painter.height / 2));
    canvas.restore();
  }
}
