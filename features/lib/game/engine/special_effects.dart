import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'dart:math' as math;

import 'package:domain/domain.dart';

import 'fruit_sprites.dart';
import 'physics_tuning.dart';

/// Одноразовый спрайт-эффект «Сада чудес» (брызги лопнувшего пузырика,
/// осколки льда): растёт 1 → 1.4 и растворяется за [duration].
class SpecialBurst extends PositionComponent {
  static const double duration = 0.3;

  final Sprite? sprite;
  final double radius;
  final Color fallback;
  double _t = 0;

  SpecialBurst({
    required Vector2 center,
    required this.radius,
    required this.sprite,
    required this.fallback,
  }) : super(position: center, anchor: Anchor.center, priority: 21);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final double p = (_t / duration).clamp(0.0, 1.0);
    final double scale = 1 + 0.4 * Curves.easeOutCubic.transform(p);
    final double size = radius * 2 * PhysicsTuning.specialBurstScale * scale;
    final Sprite? s = sprite;
    if (s == null) {
      canvas.drawCircle(
        Offset.zero,
        size / 2,
        Paint()..color = fallback.withValues(alpha: 1 - p),
      );
      return;
    }
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, 1 - p));
    s.render(
      canvas,
      position: Vector2(-size / 2, -size / 2),
      size: Vector2.all(size),
    );
    canvas.restore();
  }
}

/// Пузырик с фруктом внутри всплывает из стакана: покачиваясь поднимается
/// со скоростью [PhysicsTuning.bubbleRise] за [SpecialKind.bubbleCarrySeconds]
/// и лопается ([onPopped]) выше верха мира. Физики у него уже нет.
class BubbleCarry extends PositionComponent {
  final FruitSprite? bubble;
  final FruitSprite? fruit;
  final BallTier tier;
  final double bubbleRadius;
  final double fruitRadius;
  final Color fallback;
  final void Function(Vector2 at) onPopped;
  final double _x0;
  double _t = 0;

  BubbleCarry({
    required Vector2 start,
    required this.bubble,
    required this.fruit,
    required this.tier,
    required this.bubbleRadius,
    required this.fruitRadius,
    required this.fallback,
    required this.onPopped,
  })  : _x0 = start.x,
        super(position: start, anchor: Anchor.center, priority: 21);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= PhysicsTuning.bubbleRise * dt;
    position.x = _x0 + PhysicsTuning.bubbleSway * math.sin(_t * 6);
    if (_t >= SpecialKind.bubbleCarrySeconds) {
      onPopped(position.clone());
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final FruitSprite? f = fruit;
    if (f != null) {
      f.render(canvas, center: Vector2.zero(), radius: fruitRadius);
    }
    final FruitSprite? b = bubble;
    if (b == null) {
      canvas.drawCircle(
        Offset.zero,
        bubbleRadius,
        Paint()..color = fallback.withValues(alpha: 0.35),
      );
      return;
    }
    // Пузырь полупрозрачный поверх фрукта.
    canvas.saveLayer(
        null, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.85));
    b.render(canvas, center: Vector2.zero(), radius: bubbleRadius);
    canvas.restore();
  }
}
