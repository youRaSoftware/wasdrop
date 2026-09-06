import 'dart:async';
import 'dart:math' as math;

import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame/components.dart' show Anchor, Component, HasGameReference;
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import 'ball_body.dart';
import 'merge_effects.dart';

/// Физическое ядро игры. Мир — [AppDimens.worldWidth] (360) в ширину, высота
/// берётся из пропорции виджета стакана, так что физическое дно совпадает
/// с видимым дном.
///
/// Управление как в suika: текущий шар висит вверху и едет за пальцем
/// (драг), отпускание или тап — бросок; следующий появляется через
/// кулдаун 450 мс.
///
/// Forge2D (Box2D v3) настроен на тела 0.1–10 м, поэтому мировые единицы
/// объявлены как «36 единиц = 1 метр»: стакан ≈ 10 м в ширину, шары 0.7–5.8 м.
class WasDropGame extends Forge2DGame with TapCallbacks, DragCallbacks {
  final GameCubit cubit;

  WasDropGame({required this.cubit})
      : super(gravity: Vector2(0, 400), lengthUnitsPerMeter: 36);

  static const double worldWidth = AppDimens.worldWidth;
  static const double deadlineY = AppDimens.deadlineTopOffset;
  static const double spawnY = AppDimens.ballSpawnY;
  static const Duration dropCooldown = Duration(milliseconds: 450);

  /// Толщина невидимых стенок стакана (мировые единицы).
  static const double _wallThickness = 40;

  /// Высота мира в мировых единицах — пересчитывается от размера виджета.
  double worldHeight = worldWidth * 440 / 310;

  /// X подвешенного шара (мировые единицы), уже ограниченный стенками.
  double get aimX => _clampAim(_aimX);
  double _aimX = worldWidth / 2;

  /// Можно ли бросать (false во время кулдауна — превью скрыто).
  bool canDrop = true;

  /// Сколько секунд покоящийся шар держится выше линии проигрыша.
  double overLineTime = 0;

  Body? _walls;

  @override
  Color backgroundColor() => AppColors.jar;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Больше подшагов — устойчивее стопка шаров и меньше проникновений
    // при ударах падающего шара по лежащим.
    world.subStepCount = 8;
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

    // Стенки — толстые коробки за пределами видимой области, а не тонкие
    // отрезки: шар, вдавленный ударом сверху в тонкий Segment, проходил
    // сквозь него (центр пересекал линию — и его выталкивало вниз).
    // У коробки центр остаётся внутри, и солвер возвращает шар в стакан.
    final double w = worldWidth;
    final double h = worldHeight;
    const double t = _wallThickness;
    final List<List<Vector2>> boxes = <List<Vector2>>[
      _rect(-t, -t, 0, h + t), // левая
      _rect(w, -t, w + t, h + t), // правая
      _rect(-t, h, w + t, h + t), // дно
    ];
    final Body walls = world.createBody(BodyDef(type: BodyType.static));
    for (final List<Vector2> corners in boxes) {
      walls.createShape(
        Polygon(corners),
        ShapeDef(material: SurfaceMaterial(friction: 0.3)),
      );
    }
    _walls = walls;
  }

  static List<Vector2> _rect(double x1, double y1, double x2, double y2) {
    return <Vector2>[
      Vector2(x1, y1),
      Vector2(x2, y1),
      Vector2(x2, y2),
      Vector2(x1, y2),
    ];
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

  /// Слияние: вызывается контактом двух шаров одного тира
  /// (публичный, чтобы integration-тест мог создать шары напрямую).
  void merge(BallBody a, BallBody b) {
    if (a.isRemoving || b.isRemoving || a.merging || b.merging) return;
    a.merging = true;
    b.merging = true;
    final BallTier? next = a.tier.next;
    final Vector2 mid = (a.body.position + b.body.position) / 2;
    cubit.onMerge(a.tier);
    a.removeFromParent();
    b.removeFromParent();
    if (next != null) {
      world.add(BallBody(
        tier: next,
        initialPosition: mid,
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
    // TODO: звук/хаптика по настройкам
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
/// препятствия (рейкаст вниз).
class _JarOverlay extends Component with HasGameReference<WasDropGame> {
  _JarOverlay() : super(priority: 10);

  @override
  void render(Canvas canvas) {
    final WasDropGame g = game;

    final Paint deadlinePaint = Paint()
      ..color = g.overLineTime > 0 ? AppColors.alert : AppColors.deadline
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
    final RayHit? hit = g.world.castRayClosest(
      origin,
      Vector2(0, g.worldHeight - origin.y),
    );
    final double endY = hit?.point.y ?? g.worldHeight;

    final Paint aimPaint = Paint()
      ..color = AppColors.textTertiary
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

    BallBody.paintBall(canvas, Offset(x, WasDropGame.spawnY), r, tier);
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
