import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import 'fruit_sprites.dart';
import 'physics_tuning.dart';

/// Физический фрукт. Форма тела берётся из спрайта (см. [FruitSprite.shape]:
/// круг или скруглённый многоугольник для вытянутых фруктов); если для
/// тира нет графики — круг номинального радиуса, радиальный градиент +
/// эмодзи. Параметры тела и материала — в [PhysicsTuning].
///
/// Реакция на удар (ТЗ § 3): при контакте на скорости выше
/// [PhysicsTuning.squishSpeed] фрукт «ойкает» — открывает рот на
/// [faceDuration] и сплющивается (1.12 × 0.88 → 1.0 за [squashDuration],
/// easeOutBack); повтор не чаще [squishDebounce].
///
/// Слияние — по контакту Box2D с шаром того же тира (он возникает на
/// спекулятивной дистанции, 2.4 ед. до касания, — под выступом спрайта
/// это незаметно).
class BallBody extends BodyComponent with ContactCallbacks {
  /// Длительность «попа» при появлении шара из слияния.
  static const double popDuration = 0.28;

  static const double squashDuration = 0.25;
  static const double faceDuration = 0.30;
  static const double squishDebounce = 0.40;

  final BallTier tier;
  final Vector2 initialPosition;

  /// Начальная скорость (шар из слияния наследует импульс родителей).
  final Vector2 initialVelocity;

  final void Function(BallBody a, BallBody b) onMerge;

  /// Анимировать появление (шар родился из слияния).
  final bool popIn;

  bool merging = false;
  double _age = 0;

  /// Скорость с прошлого кадра — «до удара» в момент `beginContact`.
  final Vector2 _lastVelocity = Vector2.zero();

  /// Сколько секунд прошло с последнего «ойка» (∞ — ещё не было).
  double _sinceSquish = double.infinity;

  /// Сколько раз шар «ойкнул» (для тестов).
  int squishCount = 0;

  BallBody({
    required this.tier,
    required this.initialPosition,
    required this.onMerge,
    Vector2? initialVelocity,
    this.popIn = false,
  })  : initialVelocity = initialVelocity ?? Vector2.zero(),
        super(renderBody: false);

  /// Номинальный радиус тира; у вытянутых фруктов это средний полугабарит.
  double get radius => AppDimens.ballRadii[tier.index];

  /// Наименьший полугабарит тела (у круга — [radius]).
  double get minExtent => _sprite?.minExtent(radius) ?? radius;

  bool get settled => body.linearVelocity.length < PhysicsTuning.settledSpeed;

  /// Рот открыт.
  bool get isSquished => _sinceSquish < faceDuration;

  FruitSprite? get _sprite {
    final Object owner = game;
    return owner is FruitSpriteProvider ? owner.fruitSprites[tier] : null;
  }

  @override
  Future<void> onLoad() async {
    // userData = this → BodyComponent сам включит contact events на шейпе.
    bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      linearVelocity: initialVelocity.clone(),
      userData: this,
      angularDamping: PhysicsTuning.angularDamping,
      linearDamping: PhysicsTuning.linearDamping,
      sleepThreshold: PhysicsTuning.sleepThreshold,
    );
    shapeSpecs = <ShapeSpec>[
      ShapeSpec(
        _sprite?.shape(radius) ?? Circle(radius: radius),
        ShapeDef(
          density: PhysicsTuning.fruitDensity,
          material: SurfaceMaterial(
            friction: PhysicsTuning.fruitFriction,
            restitution: PhysicsTuning.fruitRestitution,
            rollingResistance: PhysicsTuning.fruitRollingResistance,
          ),
        ),
      ),
    ];
    // Иначе шар, рождённый на скорости, в первом кадре не «ойкнет»
    // и даст удар 0 партнёру.
    _lastVelocity.setFrom(initialVelocity);
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_sinceSquish.isFinite) _sinceSquish += dt;
    // Дочерние update идут после шагов физики, так что к следующему
    // контакту здесь лежит скорость «до удара».
    _lastVelocity.setFrom(body.linearVelocity);
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallBody && other.tier == tier) {
      onMerge(this, other);
    } else {
      // Шар-шар: относительная скорость, чтобы «ойкнул» и тот, в кого
      // прилетели; стенки/дно: своя скорость.
      final double impact = other is BallBody
          ? (_lastVelocity - other._lastVelocity).length
          : _lastVelocity.length;
      if (impact > PhysicsTuning.squishSpeed) _squish();
    }
    super.beginContact(other, contact);
  }

  void _squish() {
    if (_sinceSquish < squishDebounce) return;
    _sinceSquish = 0;
    squishCount++;
  }

  /// Открыть рот без сплющивания — кадр перед исчезновением при слиянии.
  void showSquishFace() {
    _sinceSquish = 0;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    // Сплющивание — в мировых осях (по вертикали) от нижней точки шара,
    // чтобы фрукт приплющивался о поверхность, а не подпрыгивал; поворот
    // тела на время масштабирования снимается.
    if (_sinceSquish < squashDuration) {
      final double t =
          Curves.easeOutBack.transform(_sinceSquish / squashDuration);
      final double sx = 1.12 + (1 - 1.12) * t;
      final double sy = 0.88 + (1 - 0.88) * t;
      canvas.rotate(-angle);
      canvas.translate(0, radius);
      canvas.scale(sx, sy);
      canvas.translate(0, -radius);
      canvas.rotate(angle);
    }
    if (popIn && _age < popDuration) {
      final double scale =
          0.55 + 0.45 * Curves.easeOutBack.transform(_age / popDuration);
      canvas.scale(scale);
    }

    final FruitSprite? sprite = _sprite;
    if (sprite != null) {
      sprite.render(
        canvas,
        center: Vector2.zero(),
        radius: radius,
        squished: isSquished,
      );
    } else {
      paintBall(canvas, Offset.zero, radius, tier);
    }
    canvas.restore();
  }

  static final Map<BallTier, TextPainter> _emojiCache =
      <BallTier, TextPainter>{};

  /// Запасная отрисовка шара тира [tier] с центром [center]: радиальный
  /// градиент + эмодзи. Используется, когда для тира нет спрайта.
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
