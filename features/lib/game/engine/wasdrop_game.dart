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
import 'fruit_sprites.dart';
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
/// Все числа физики (масштаб Box2D, гравитация, материалы, число шагов) —
/// в [PhysicsTuning]; здесь только правила игры.
class WasDropGame extends Forge2DGame
    with TapCallbacks, DragCallbacks
    implements FruitSpriteProvider {
  final GameCubit cubit;

  /// Настройки (линия прицела); движок читает их напрямую, без DI.
  final ValueListenable<SettingsModel> settings;

  /// Спрайты фруктов по тирам (грузятся один раз в [onLoad]).
  @override
  final FruitSprites fruitSprites = FruitSprites();

  WasDropGame({required this.cubit, required this.settings})
      : super(
          world: JarPhysicsWorld.standard(),
          lengthUnitsPerMeter: PhysicsTuning.unitsPerMeter,
        );

  static const double worldWidth = AppDimens.worldWidth;
  static const double deadlineY = AppDimens.deadlineTopOffset;
  static const double spawnY = AppDimens.ballSpawnY;
  static const Duration dropCooldown = Duration(milliseconds: 450);

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
    camera.viewfinder.anchor = Anchor.topLeft;
    _layoutWorld(size);
    world.add(_JarOverlay());
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
    );
  }

  // --- Ввод -----------------------------------------------------------------

  @override
  void onDragStart(DragStartEvent event) {
    _aim(event.canvasPosition);
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _aim(event.canvasEndPosition);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _drop();
    super.onDragEnd(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _aim(event.canvasPosition);
    _drop();
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
    if (!canDrop || paused || !isLoaded) return;
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
    if (next != null) {
      // Новый шар крупнее слившихся: если они лежали на дне или у стенки,
      // его круг в точке контакта уже пересекает пол/стенку, и Box2D
      // выталкивает его наружу заметные 100–200 мс («проваливается»).
      // Держим круг внутри стакана; соседей он расталкивает сам. Если
      // зажали — гасим составляющую скорости «в стену».
      final double r = AppDimens.ballRadii[next.index];
      // У вытянутых фруктов габарит больше номинального радиуса.
      final double e = fruitSprites[next]?.extent(r) ?? r;
      final double x = mid.x.clamp(e, worldWidth - e);
      final double y = math.min(mid.y, worldHeight - e);
      if (x > mid.x) velocity.x = math.max(velocity.x, 0);
      if (x < mid.x) velocity.x = math.min(velocity.x, 0);
      if (y < mid.y) velocity.y = math.min(velocity.y, 0);
      world.add(BallBody(
        tier: next,
        initialPosition: Vector2(x, y),
        initialVelocity: velocity,
        onMerge: merge,
        popIn: true,
      ));
    }
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

  @override
  void update(double dt) {
    super.update(dt);
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
    world.children.whereType<BallBody>().toList().forEach(
          (BallBody b) => b.removeFromParent(),
        );
    overLineTime = 0;
    canDrop = true;
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

    if (!g.canDrop || g.cubit.state.status != GameStatus.playing) return;

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
