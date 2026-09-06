import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

/// Физический шар. Рисуется вручную: радиальный градиент + эмодзи тира.
class BallBody extends BodyComponent with ContactCallbacks {
  final BallTier tier;
  final Vector2 initialPosition;
  final void Function(BallBody a, BallBody b) onMerge;
  bool merging = false;

  BallBody({
    required this.tier,
    required this.initialPosition,
    required this.onMerge,
  });

  double get radius => AppDimens.ballRadii[tier.index];

  bool get settled => body.linearVelocity.length < 8;

  @override
  Body createBody() {
    final BodyDef bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      userData: this,
    );
    final FixtureDef fixtureDef = FixtureDef(
      CircleShape()..radius = radius,
      density: 1,
      friction: 0.25,
      restitution: 0.15,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallBody && other.tier == tier) {
      onMerge(this, other);
    }
    super.beginContact(other, contact);
  }

  static final Map<BallTier, TextPainter> _emojiCache =
      <BallTier, TextPainter>{};

  @override
  void render(Canvas canvas) {
    final Color color = AppColors.tiers[tier.index];
    final Rect rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.12)!,
          ],
          stops: const <double>[0, 0.72, 1],
        ).createShader(rect),
    );
    final TextPainter tp = _emojiCache.putIfAbsent(tier, () {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: tier.emoji,
          style: TextStyle(fontSize: radius),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return painter;
    });
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}
