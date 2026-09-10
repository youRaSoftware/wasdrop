import 'dart:async';
import 'dart:math' as math;

import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame/components.dart' show Anchor, Component, HasGameReference;
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import 'ball_body.dart';
import 'bonus_effects.dart';
import 'fruit_sprites.dart';
import 'fx_sprites.dart';
import 'jar_physics_world.dart';
import 'jar_walls.dart';
import 'merge_effects.dart';
import 'physics_tuning.dart';

/// Физическое ядро игры. Мир — [AppDimens.worldWidth] (360) в ширину, высота
/// берётся из пропорции виджета стакана, так что физическое дно совпадает
/// с видимым дном.
///
/// Управление как в suika: текущий шар висит вверху и едет за пальцем
/// (драг), отпускание или тап — бросок; следующий появляется через
/// кулдаун 450 мс.
///
/// Бонусы: [shake] подбрасывает все фрукты (заряды считает кубит); при
/// взведённой бомбочке или увеличении ([pickMode]) тап по фрукту — взрыв
/// или рост на уровень ([pickAt]), а тап мимо — отмена.
///
/// Все числа физики (масштаб Box2D, гравитация, материалы, число шагов) —
/// в [PhysicsTuning]; здесь только правила игры.
class WasDropGame extends Forge2DGame
    with TapCallbacks, DragCallbacks
    implements FruitSpriteProvider {
  final GameCubit cubit;

  /// Настройки (линия прицела); движок читает их напрямую, без DI.
  final ValueListenable<SettingsModel> settings;

  /// Сохранённая партия — шары восстанавливаются в [onLoad].
  final GameSnapshot? resumeFrom;

  /// Спрайты фруктов по тирам (грузятся один раз в [onLoad]).
  @override
  final FruitSprites fruitSprites = FruitSprites();

  /// Спрайты бонусов: бомбочка и кадры взрыва.
  final FxSprites fxSprites = FxSprites();

  final math.Random _random = math.Random();

  WasDropGame({required this.cubit, required this.settings, this.resumeFrom})
      : super(
          world: JarPhysicsWorld.standard(),
          lengthUnitsPerMeter: PhysicsTuning.unitsPerMeter,
        );

  static const double worldWidth = AppDimens.worldWidth;
  static const double deadlineY = AppDimens.deadlineTopOffset;
  static const double spawnY = AppDimens.ballSpawnY;
  static const Duration dropCooldown = Duration(milliseconds: 450);

  /// Насколько боковые стенки продолжаются выше верха стакана: подброшенный
  /// встряской фрукт не должен перелететь через них.
  static const double wallTopMargin = 300;

  /// Высота мира в мировых единицах — пересчитывается от размера виджета.
  double worldHeight = worldWidth * 440 / 310;

  /// X подвешенного шара (мировые единицы), уже ограниченный стенками.
  double get aimX => _clampAim(_aimX);
  double _aimX = worldWidth / 2;

  /// Можно ли бросать (false во время кулдауна — превью скрыто).
  bool canDrop = true;

  /// Сколько секунд покоящийся шар держится выше линии проигрыша.
  double overLineTime = 0;

  /// Сколько шагов Box2D сделал последний кадр (для тестов).
  int get lastPhysicsSteps => (world as JarPhysicsWorld).lastSteps;

  /// Кулдаун встряски ещё не истёк.
  bool get canShake => _shakeCooldownLeft <= 0;
  double _shakeCooldownLeft = 0;

  /// Осталось дрожать камере (после встряски).
  double _cameraShakeLeft = 0;

  /// Режим выбора фрукта: взведена бомбочка или увеличение.
  bool get pickMode =>
      cubit.state.armed == Bonus.bomb || cubit.state.armed == Bonus.upgrade;

  Body? _walls;

  /// Фон не рисуем: стакан (заливка и стенки темы, часто полупрозрачные)
  /// красит `GameForm` под холстом.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    assert(
      (Tolerances.speculativeDistance - PhysicsTuning.speculativeDistance)
              .abs() <
          1e-6,
      'PhysicsTuning.speculativeDistance разошлась с Box2D: '
      '${Tolerances.speculativeDistance}',
    );
    world.subStepCount = PhysicsTuning.subSteps;
    await fruitSprites.load(images);
    await fxSprites.load(images);
    camera.viewfinder.anchor = Anchor.topLeft;
    _layoutWorld(size);
    final GameSnapshot? snapshot = resumeFrom;
    if (snapshot != null) _restore(snapshot);
    world.add(_JarOverlay());
  }

  /// Расставляет шары сохранённой партии: X как был, Y — от дна (высота
  /// мира зависит от экрана), угол и скорость — как в момент сохранения.
  void _restore(GameSnapshot snapshot) {
    for (final BallSnapshot b in snapshot.balls) {
      final double r = AppDimens.ballRadii[b.tier.index];
      world.add(BallBody(
        tier: b.tier,
        initialPosition: Vector2(
          b.x.clamp(r, worldWidth - r),
          math.max(r, worldHeight - b.bottomOffset),
        ),
        initialAngle: b.angle,
        initialVelocity: Vector2(b.vx, b.vy),
        onMerge: merge,
      ));
    }
  }

  /// Снимок шаров для сохранения партии (смонтированные, не сливающиеся).
  List<BallSnapshot> captureBalls() {
    return world.children
        .whereType<BallBody>()
        .where((BallBody b) => b.isMounted && !b.merging)
        .map(
          (BallBody b) => BallSnapshot(
            tier: b.tier,
            x: b.body.position.x,
            bottomOffset: worldHeight - b.body.position.y,
            angle: b.body.angle,
            vx: b.body.linearVelocity.x,
            vy: b.body.linearVelocity.y,
          ),
        )
        .toList();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layoutWorld(size);
  }

  /// Подгоняет высоту мира под пропорцию холста и пересобирает стенки.
  void _layoutWorld(Vector2 canvasSize) {
    if (canvasSize.x <= 0 || canvasSize.y <= 0) return;
    worldHeight = worldWidth * canvasSize.y / canvasSize.x;
    camera.viewfinder.visibleGameSize = Vector2(worldWidth, worldHeight);

    final Body? oldWalls = _walls;
    if (oldWalls != null) world.destroyBody(oldWalls);
    // Скосы под визуальное скругление углов (AppDimens.jarInnerCornerRadius
    // px → мировые единицы).
    _walls = buildJarWalls(
      world,
      width: worldWidth,
      height: worldHeight,
      chamfer: AppDimens.jarInnerCornerRadius * worldWidth / canvasSize.x,
      topMargin: wallTopMargin,
    );
  }

  // --- Ввод -----------------------------------------------------------------

  // В режиме выбора любое касание — выбор фрукта (тап и начало драга
  // взаимоисключающи: жест-арена отдаёт касание одному из них).

  @override
  void onDragStart(DragStartEvent event) {
    if (pickMode) {
      pickAt(screenToWorld(event.canvasPosition));
    } else {
      _aim(event.canvasPosition);
    }
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!pickMode) _aim(event.canvasEndPosition);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!pickMode) _drop();
    super.onDragEnd(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (pickMode) {
      pickAt(screenToWorld(event.canvasPosition));
    } else {
      _aim(event.canvasPosition);
      _drop();
    }
    super.onTapUp(event);
  }

  void _aim(Vector2 canvasPosition) {
    _aimX = screenToWorld(canvasPosition).x;
  }

  double _clampAim(double x) {
    final double r = AppDimens.ballRadii[cubit.state.current.index];
    return x.clamp(
      r + AppDimens.jarWallWidth,
      worldWidth - r - AppDimens.jarWallWidth,
    );
  }

  void _drop() {
    if (!canDrop || paused || !isLoaded || pickMode) return;
    if (cubit.state.status != GameStatus.playing) return;
    canDrop = false;
    final BallTier tier = cubit.state.current;
    world.add(BallBody(
      tier: tier,
      initialPosition: Vector2(aimX, spawnY),
      onMerge: merge,
    ));
    cubit.onDropped();
    Future<void>.delayed(dropCooldown, () {
      canDrop = true;
    });
  }

  // --- Правила ---------------------------------------------------------------

  /// Слияние двух шаров одного тира: вызывается из [BallBody], когда круги
  /// реально коснулись (публичный, чтобы integration-тест мог создать шары
  /// напрямую).
  void merge(BallBody a, BallBody b) {
    if (a.isRemoving || b.isRemoving || a.merging || b.merging) return;
    a.merging = true;
    b.merging = true;
    // Кадр перед исчезновением — оба с открытым ртом (ТЗ § 3).
    a.showSquishFace();
    b.showSquishFace();
    final BallTier? next = a.tier.next;
    final Vector2 mid = (a.body.position + b.body.position) / 2;
    // Импульс родителей — снять до удаления тел. Новый шар получает
    // взвешенную по массе скорость (≈ 80 % импульса: его масса ≈ 1.6
    // массы родителя), с потолком, чтобы слившийся на лету арбуз
    // не влетал в кучу и не давал ложный проигрыш.
    final double massA = a.body.mass;
    final double massB = b.body.mass;
    final Vector2 velocity =
        (a.body.linearVelocity * massA + b.body.linearVelocity * massB) /
            (massA + massB);
    if (velocity.length > PhysicsTuning.mergeMaxSpeed) {
      velocity.length = PhysicsTuning.mergeMaxSpeed;
    }
    cubit.onMerge(a.tier);
    a.removeFromParent();
    b.removeFromParent();
    if (next != null) _spawnInside(next, mid, velocity);
    // Вспышка + всплывающее «+N» (мокап, кадр 4). Для джекпота t11+t11
    // шара нет — эффект рисуем по размеру исчезнувших шаров.
    final BallTier effectTier = next ?? a.tier;
    final double effectRadius = AppDimens.ballRadii[effectTier.index];
    world.addAll(<Component>[
      MergeFlash(
        center: mid,
        radius: effectRadius,
        color: AppColors.tiers[effectTier.index],
      ),
      ScorePopup(
        text: '+${a.tier.mergeScore}',
        start: Vector2(mid.x, mid.y - effectRadius - 6),
      ),
    ]);
  }

  /// Рождает шар тира [tier] с «попом» около [at]. Шар крупнее того, что
  /// было на этом месте: если оно лежало на дне или у стенки, его круг уже
  /// пересекает пол/стенку, и Box2D выталкивал бы его наружу заметные
  /// 100–200 мс («проваливается»). Держим габарит внутри стакана (соседей
  /// он расталкивает сам); если зажали — гасим составляющую [velocity]
  /// «в стену».
  void _spawnInside(
    BallTier tier,
    Vector2 at,
    Vector2 velocity, {
    double angle = 0,
  }) {
    final double r = AppDimens.ballRadii[tier.index];
    // У вытянутых фруктов габарит больше номинального радиуса.
    final double e = fruitSprites[tier]?.extent(r) ?? r;
    final double x = at.x.clamp(e, worldWidth - e);
    final double y = math.min(at.y, worldHeight - e);
    if (x > at.x) velocity.x = math.max(velocity.x, 0);
    if (x < at.x) velocity.x = math.min(velocity.x, 0);
    if (y < at.y) velocity.y = math.min(velocity.y, 0);
    world.add(BallBody(
      tier: tier,
      initialPosition: Vector2(x, y),
      initialVelocity: velocity,
      initialAngle: angle,
      onMerge: merge,
      popIn: true,
    ));
  }

  // --- Бонусы ----------------------------------------------------------------

  /// Живые фрукты: смонтированы, не сливаются и не взрываются.
  Iterable<BallBody> _liveBalls() => world.children.whereType<BallBody>().where(
        (BallBody b) => b.isMounted && !b.isRemoving && !b.merging,
      );

  /// Бонус «Встряхнуть»: каждый фрукт получает прирост скорости вверх
  /// (глубже — сильнее: у линии проигрыша лететь некуда) и случайный вбок,
  /// случайное вращение и «ойкает»; стакан вздрагивает. Заряды и статус
  /// партии проверяет кубит, здесь — только кулдаун.
  void shake() {
    if (!isLoaded || !canShake) return;
    _shakeCooldownLeft = PhysicsTuning.shakeCooldown;
    _cameraShakeLeft = PhysicsTuning.shakeCameraDuration;
    final double span = math.max(1, worldHeight - deadlineY);
    for (final BallBody b in _liveBalls()) {
      final double depth =
          ((b.body.position.y - deadlineY) / span).clamp(0.0, 1.0);
      final double lift = PhysicsTuning.shakeTopFactor +
          (1 - PhysicsTuning.shakeTopFactor) * depth;
      // Своя доля подскока у каждого фрукта — куча рассыпается, а не
      // подпрыгивает строем.
      final double share = PhysicsTuning.shakeLiftJitter +
          (1 - PhysicsTuning.shakeLiftJitter) * _random.nextDouble();
      final Vector2 dv = Vector2(
        _signedRandom() * PhysicsTuning.shakeSideSpeed,
        -PhysicsTuning.shakeLiftSpeed * lift * share,
      );
      b.body.applyLinearImpulse(dv * b.body.mass);
      b.body.applyAngularImpulse(
        _signedRandom() * PhysicsTuning.shakeSpin * b.body.rotationalInertia,
      );
      b.showSquishFace();
    }
  }

  double _signedRandom() => _random.nextDouble() * 2 - 1;

  /// Режим выбора: тап в мировой точке [point] по фрукту — взрыв или рост
  /// (что взведено); тап мимо снимает режим.
  void pickAt(Vector2 point) {
    if (!pickMode) return;
    BallBody? hit;
    double best = double.infinity;
    for (final BallBody b in _liveBalls()) {
      final double d = b.body.position.distanceTo(point);
      final double reach =
          (fruitSprites[b.tier]?.extent(b.radius) ?? b.radius) + 6;
      if (d <= reach && d < best) {
        best = d;
        hit = b;
      }
    }
    if (hit == null) {
      cubit.disarmBonus();
      return;
    }
    if (cubit.state.armed == Bonus.bomb) {
      explode(hit);
    } else {
      upgrade(hit);
    }
  }

  /// Бустер «Увеличить»: фрукт [b] на месте становится следующим по цепочке
  /// (с «попом» и вспышкой слияния, без очков); арбузу расти некуда — он
  /// только «ойкает», режим остаётся. Публичный для тестов.
  void upgrade(BallBody b) {
    if (!b.isMounted || b.isRemoving || b.merging) return;
    final BallTier? next = b.tier.next;
    if (next == null) {
      b.showSquishFace();
      return;
    }
    cubit.useUpgrade(next);
    b.merging = true;
    final Vector2 at = b.body.position.clone();
    final Vector2 velocity = b.body.linearVelocity.clone();
    final double angle = b.body.angle;
    b.removeFromParent();
    _spawnInside(next, at, velocity, angle: angle);
    world.add(MergeFlash(
      center: at,
      radius: AppDimens.ballRadii[next.index],
      color: AppColors.tiers[next.index],
    ));
  }

  /// Взрыв фрукта [b]: заряд списывается сразу, фрукт помечен исчезающим
  /// (не сливается, не попадает в снимок), на нём тлеет бомбочка, после
  /// фитиля — кадры взрыва и толчок соседей. Публичный для тестов.
  void explode(BallBody b) {
    if (!b.isMounted || b.isRemoving || b.merging) return;
    cubit.useBomb();
    b.merging = true;
    b.showSquishFace();
    world.add(BombFuse(
      target: b,
      sprite: fxSprites.bomb,
      onExplode: () => _detonate(b),
    ));
  }

  void _detonate(BallBody b) {
    if (!b.isMounted || b.isRemoving) return;
    final Vector2 center = b.body.position.clone();
    final double r = b.radius;
    b.removeFromParent();
    final double reach = PhysicsTuning.bombPushRadius * r;
    for (final BallBody other in _liveBalls()) {
      final Vector2 delta = other.body.position - center;
      final double d = delta.length;
      if (d <= 0 || d > reach + other.radius) continue;
      final double falloff = (1 - (d - r) / reach).clamp(0.2, 1.0);
      final Vector2 dv = delta / d * (PhysicsTuning.bombPushSpeed * falloff);
      other.body.applyLinearImpulse(dv * other.body.mass);
      other.showSquishFace();
    }
    world.add(BoomEffect(center: center, radius: r, frames: fxSprites.boom));
  }

  void _updateShake(double dt) {
    if (_shakeCooldownLeft > 0) _shakeCooldownLeft -= dt;
    if (_cameraShakeLeft <= 0) return;
    _cameraShakeLeft = math.max(0, _cameraShakeLeft - dt);
    if (_cameraShakeLeft == 0) {
      camera.viewfinder.position = Vector2.zero();
      return;
    }
    // Затухающая дрожь: амплитуда пропорциональна остатку времени.
    final double a = PhysicsTuning.shakeCameraAmplitude *
        _cameraShakeLeft /
        PhysicsTuning.shakeCameraDuration;
    camera.viewfinder.position = Vector2(
      a * math.sin(_cameraShakeLeft * 90),
      a * 0.5 * math.cos(_cameraShakeLeft * 70),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateShake(dt);
    if (paused || cubit.state.status != GameStatus.playing) return;
    // Проигрыш: покоящийся шар выше линии дольше 1.5 с.
    final bool overLine = world.children.whereType<BallBody>().any(
          (BallBody b) =>
              b.isMounted &&
              b.settled &&
              b.body.position.y - AppDimens.ballRadii[b.tier.index] < deadlineY,
        );
    overLineTime = overLine ? overLineTime + dt : 0;
    if (overLineTime > 1.5) {
      overLineTime = 0;
      cubit.gameOver();
    }
  }

  void reset() {
    world.children
        .where(
            (Component c) => c is BallBody || c is BombFuse || c is BoomEffect)
        .toList()
        .forEach((Component c) => c.removeFromParent());
    overLineTime = 0;
    canDrop = true;
    _shakeCooldownLeft = 0;
    _cameraShakeLeft = 0;
    camera.viewfinder.position = Vector2.zero();
  }

  @override
  void onRemove() {
    super.onRemove();
    // Box2D держит ограниченное число миров и не освобождает их сам.
    world.physicsWorld.destroy();
  }
}

/// Декорации стакана поверх шаров (мировые координаты): пунктирная линия
/// проигрыша, подвешенный текущий шар и пунктир прицела до первого
/// препятствия (рейкаст вниз; отключается в настройках).
class _JarOverlay extends Component with HasGameReference<WasDropGame> {
  _JarOverlay() : super(priority: 10);

  @override
  void render(Canvas canvas) {
    final WasDropGame g = game;
    final GameTheme theme = GameThemes.byId(g.settings.value.themeId);

    // Режим выбора фрукта: стакан приглушён, подвешенный фрукт и прицел
    // скрыты (бомбочка и взрыв рисуются выше — priority 20+).
    if (g.pickMode) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, WasDropGame.worldWidth, g.worldHeight),
        Paint()..color = AppColors.scrim.withValues(alpha: 0.18),
      );
    }

    final Paint deadlinePaint = Paint()
      ..color = g.overLineTime > 0 ? theme.deadlineAlert : theme.deadline
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    _dashedLine(
      canvas,
      Offset(0, WasDropGame.deadlineY),
      Offset(WasDropGame.worldWidth, WasDropGame.deadlineY),
      dash: 9,
      gap: 7,
      paint: deadlinePaint,
    );

    if (!g.canDrop || g.pickMode) return;
    if (g.cubit.state.status != GameStatus.playing) return;

    final BallTier tier = g.cubit.state.current;
    final double r = AppDimens.ballRadii[tier.index];
    final double x = g.aimX;
    final Vector2 origin = Vector2(x, WasDropGame.spawnY + r);

    if (g.settings.value.aimLineOn) {
      final RayHit? hit = g.world.castRayClosest(
        origin,
        Vector2(0, g.worldHeight - origin.y),
      );
      final double endY = hit?.point.y ?? g.worldHeight;

      final Paint aimPaint = Paint()
        ..color = theme.hudTextTertiary
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      _dashedLine(
        canvas,
        Offset(x, origin.y + 6),
        Offset(x, endY - 2),
        dash: 6,
        gap: 6,
        paint: aimPaint,
      );
    }

    final FruitSprite? sprite = g.fruitSprites[tier];
    if (sprite != null) {
      sprite.render(canvas, center: Vector2(x, WasDropGame.spawnY), radius: r);
    } else {
      BallBody.paintBall(canvas, Offset(x, WasDropGame.spawnY), r, tier);
    }
  }

  void _dashedLine(
    Canvas canvas,
    Offset from,
    Offset to, {
    required double dash,
    required double gap,
    required Paint paint,
  }) {
    final Offset delta = to - from;
    final double length = delta.distance;
    if (length <= 0) return;
    final Offset dir = delta / length;
    double t = 0;
    while (t < length) {
      final double end = math.min(t + dash, length);
      canvas.drawLine(from + dir * t, from + dir * end, paint);
      t += dash + gap;
    }
  }
}
