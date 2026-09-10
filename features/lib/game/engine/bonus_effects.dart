import 'dart:math' as math;

import 'package:core_ui/core_ui.dart';
import 'package:flame/components.dart' show Anchor, Component;
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import 'ball_body.dart';
import 'physics_tuning.dart';

/// Бомбочка на выбранном фрукте: [PhysicsTuning.bombFuse] секунд следует за
/// телом и слегка «дышит», потом удаляет себя и зовёт [onExplode]. Если
/// фрукт исчез раньше (рестарт), просто уходит.
class BombFuse extends Component {
  final BallBody target;
  final Sprite? sprite;
  final VoidCallback onExplode;
  double _t = 0;

  BombFuse({
    required this.target,
    required this.sprite,
    required this.onExplode,
  }) : super(priority: 20);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (!target.isMounted || target.isRemoving) {
      removeFromParent();
      return;
    }
    if (_t >= PhysicsTuning.bombFuse) {
      removeFromParent();
      onExplode();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!target.isMounted || target.isRemoving) return;
    final double pulse = 1 + 0.08 * math.sin(_t * 40);
    final double size = math.max(28, target.radius * 1.3) * pulse;
    final Vector2 center = target.body.position;
    final Sprite? s = sprite;
    if (s != null) {
      s.render(
        canvas,
        position: center,
        size: Vector2.all(size),
        anchor: Anchor.center,
      );
    } else {
      canvas.drawCircle(
        center.toOffset(),
        size / 2,
        Paint()..color = AppColors.textPrimary,
      );
    }
  }
}

/// Взрыв бомбочки: три кадра `boom_1..3` за [duration] секунд, облако чуть
/// растёт, последний кадр гаснет. Без спрайтов — процедурная вспышка.
class BoomEffect extends Component {
  static const double duration = 0.45;

  final Vector2 center;
  final double radius;
  final List<Sprite> frames;
  double _t = 0;

  BoomEffect({
    required Vector2 center,
    required this.radius,
    required this.frames,
  })  : center = center.clone(),
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
    final double grow = 1 + 0.4 * Curves.easeOutCubic.transform(p);
    final double side = math.max(70, radius * 3.2) * grow;
    if (frames.isEmpty) {
      canvas.drawCircle(
        center.toOffset(),
        side / 2,
        Paint()..color = AppColors.gold.withValues(alpha: 0.8 * (1 - p)),
      );
      return;
    }
    final int index = math.min(frames.length - 1, (p * frames.length).floor());
    // Последний кадр растворяется.
    final double alpha = index == frames.length - 1
        ? 1 - ((p * frames.length) - index).clamp(0.0, 1.0)
        : 1;
    frames[index].render(
      canvas,
      position: center,
      size: Vector2.all(side),
      anchor: Anchor.center,
      overridePaint: Paint()..color = AppColors.flash.withValues(alpha: alpha),
    );
  }
}
