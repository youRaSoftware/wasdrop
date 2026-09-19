import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame/sprite.dart' show Sprite;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import 'fruit_sprites.dart';
import 'physics_tuning.dart';
import 'special_sprites.dart';

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

  /// Начальный угол, рад (восстановление сохранённой партии).
  final double initialAngle;

  final void Function(BallBody a, BallBody b) onMerge;

  /// Особый фрукт «Сада чудес»; у обычного — null ([tier] тогда значим).
  final SpecialKind? special;

  /// Особый фрукт коснулся [other] (Радужка, Льдинка) или сработал сам по
  /// себе (Пузырик лопнул — [other] null). Разбирает `WasDropGame`.
  final void Function(BallBody special, BallBody? other)? onSpecial;

  /// Сколько бросков фрукт заморожен льдинкой (не сливается).
  int frozen = 0;

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
    this.initialAngle = 0,
    this.popIn = false,
    this.special,
    this.onSpecial,
    this.frozen = 0,
  })  : initialVelocity = initialVelocity ?? Vector2.zero(),
        super(renderBody: false);

  /// Номинальный радиус: у особого — свой, у тира — из [AppDimens];
  /// у вытянутых фруктов это средний полугабарит.
  double get radius => special?.radius ?? AppDimens.ballRadii[tier.index];

  bool get isSpecial => special != null;
  bool get isFrozen => frozen > 0;

  /// Обычный фрукт, который может сливаться (не особый, не замороженный,
  /// не в процессе слияния).
  bool get canMerge => special == null && frozen == 0 && !merging;

  /// Наименьший полугабарит тела (у круга — [radius]).
  double get minExtent => _sprite?.minExtent(radius) ?? radius;

  SpecialSprites? get _specials {
    final Object owner = game;
    return owner is SpecialSpriteProvider ? owner.specialSprites : null;
  }

  bool get settled => body.linearVelocity.length < PhysicsTuning.settledSpeed;

  /// Рот открыт.
  bool get isSquished => _sinceSquish < faceDuration;

  FruitSprite? get _sprite {
    if (special != null) return null;
    final Object owner = game;
    return owner is FruitSpriteProvider ? owner.fruitSprites[tier] : null;
  }

  @override
  Future<void> onLoad() async {
    // userData = this → BodyComponent сам включит contact events на шейпе.
    bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      rotation: Rot.fromAngle(initialAngle),
      linearVelocity: initialVelocity.clone(),
      userData: this,
      angularDamping: PhysicsTuning.angularDamping,
      linearDamping: PhysicsTuning.linearDamping,
      sleepThreshold: PhysicsTuning.sleepThreshold,
    );
    shapeSpecs = <ShapeSpec>[
      ShapeSpec(
        // Особые фрукты — круги своего радиуса, форма по спрайту не нужна.
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
    if (other is BallBody && special == null && other.special == null) {
      if (other.tier == tier && canMerge && other.canMerge) {
        onMerge(this, other);
      } else {
        _impact(other);
      }
    } else if (other is BallBody && special != null) {
      switch (special!) {
        case SpecialKind.rainbow:
        case SpecialKind.ice:
          if (other.canMerge) onSpecial?.call(this, other);
        case SpecialKind.bubble:
          // Обычный фрукт — уносит его; особый/замороженный — лопается.
          onSpecial?.call(this, other.canMerge ? other : null);
        case SpecialKind.rotten:
          break;
      }
      _impact(other);
    } else {
      // Пузырик на дне или у стенки просто лопается.
      if (special == SpecialKind.bubble) onSpecial?.call(this, null);
      // Шар-шар: относительная скорость, чтобы «ойкнул» и тот, в кого
      // прилетели; стенки/дно: своя скорость.
      final double impact = other is BallBody
          ? (_lastVelocity - other._lastVelocity).length
          : _lastVelocity.length;
      if (impact > PhysicsTuning.squishSpeed) _squish();
    }
    super.beginContact(other, contact);
  }

  void _impact(BallBody other) {
    final double impact = (_lastVelocity - other._lastVelocity).length;
    if (impact > PhysicsTuning.squishSpeed) {
      _squish();
      other._squish();
    }
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

    final SpecialKind? kind = special;
    if (kind != null) {
      _renderSpecial(canvas, kind);
    } else {
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
      if (isFrozen) _renderIce(canvas);
    }
    canvas.restore();
  }

  /// Особый фрукт: спрайт по радиусу (тело — круг; спрайт чуть больше).
  void _renderSpecial(Canvas canvas, SpecialKind kind) {
    final FruitSprite? sprite = _specials?[kind];
    if (sprite == null) {
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()..color = specialColor(kind),
      );
      return;
    }
    sprite.render(
      canvas,
      center: Vector2.zero(),
      radius: radius,
      squished: isSquished,
    );
  }

  /// Корка льда поверх замороженного фрукта (в осях мира, без поворота).
  void _renderIce(Canvas canvas) {
    final Sprite? overlay = _specials?.iceOverlay;
    final double size = radius * 2 * PhysicsTuning.iceOverlayScale;
    canvas.save();
    canvas.rotate(-angle);
    if (overlay == null) {
      canvas.drawCircle(
        Offset.zero,
        size / 2,
        Paint()..color = specialColor(SpecialKind.ice).withValues(alpha: 0.5),
      );
    } else {
      overlay.render(
        canvas,
        position: Vector2(-size / 2, -size / 2),
        size: Vector2.all(size),
      );
    }
    canvas.restore();
  }

  /// Цвет особого фрукта (свечение в очереди, запасная отрисовка).
  static Color specialColor(SpecialKind kind) => switch (kind) {
        SpecialKind.rainbow => const Color(0xFFC973F0),
        SpecialKind.bubble => const Color(0xFF5FA8CE),
        SpecialKind.rotten => const Color(0xFF8FA23B),
        SpecialKind.ice => const Color(0xFF8FC8E6),
      };

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
