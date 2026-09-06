import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

/// Физический шар. Рисуется вручную: радиальный градиент + эмодзи тира.
class BallBody extends BodyComponent with ContactCallbacks {
  /// Длительность «попа» при появлении шара из слияния.
  static const double popDuration = 0.28;

  final BallTier tier;
  final Vector2 initialPosition;
  final void Function(BallBody a, BallBody b) onMerge;

  /// Анимировать появление (шар родился из слияния).
  final bool popIn;

  bool merging = false;
  double _age = 0;

  BallBody({
    required this.tier,
    required this.initialPosition,
    required this.onMerge,
    this.popIn = false,
  }) : super(renderBody: false);

  double get radius => AppDimens.ballRadii[tier.index];

  bool get settled => body.linearVelocity.length < 8;

  @override
  Future<void> onLoad() async {
    // userData = this → BodyComponent сам включит contact events на шейпе.
    bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      userData: this,
      // Гасим вращение: без этого шары катаются по дну до стенок.
      angularDamping: 1,
      linearDamping: 0.05,
    );
    shapeSpecs = <ShapeSpec>[
      ShapeSpec(
        Circle(radius: radius),
        ShapeDef(
          density: 1,
          material: SurfaceMaterial(
            friction: 0.25,
            restitution: 0.15,
            rollingResistance: 0.2,
          ),
        ),
      ),
    ];
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallBody && other.tier == tier) {
      onMerge(this, other);
    }
    super.beginContact(other, contact);
  }

  @override
  void render(Canvas canvas) {
    if (popIn && _age < popDuration) {
      final double scale =
          0.55 + 0.45 * Curves.easeOutBack.transform(_age / popDuration);
      canvas.save();
      canvas.scale(scale);
      paintBall(canvas, Offset.zero, radius, tier);
      canvas.restore();
      return;
    }
    paintBall(canvas, Offset.zero, radius, tier);
  }

  static final Map<BallTier, TextPainter> _emojiCache =
      <BallTier, TextPainter>{};

  /// Отрисовка шара тира [tier] с центром [center] — общая для физических
  /// шаров и подвешенного шара-превью.
  static void paintBall(
    Canvas canvas,
    Offset center,
    double radius,
    BallTier tier,
  ) {
    final Color color = AppColors.tiers[tier.index];
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: <Color>[
            Color.lerp(color, AppColors.flash, 0.45)!,
            color,
            Color.lerp(color, AppColors.textPrimary, 0.12)!,
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
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
