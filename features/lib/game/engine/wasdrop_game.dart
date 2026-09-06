import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import 'ball_body.dart';

/// Физическое ядро игры. Мир — AppDimens.worldWidth (360) в ширину,
/// камера растягивает его на весь GameWidget.
class WasDropGame extends Forge2DGame with TapCallbacks, DragCallbacks {
  final GameCubit cubit;

  WasDropGame({required this.cubit})
      : super(gravity: Vector2(0, 400), zoom: 1);

  static const double deadlineY = AppDimens.deadlineTopOffset;
  double _aimX = AppDimens.worldWidth / 2;
  bool _canDrop = true;
  double _overLineTime = 0;

  @override
  Color backgroundColor() => AppColors.jar;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize =
        Vector2(AppDimens.worldWidth, AppDimens.worldWidth * 440 / 310);
    camera.viewfinder.anchor = Anchor.topLeft;
    _addWalls();
  }

  void _addWalls() {
    final double w = AppDimens.worldWidth;
    final double h = AppDimens.worldWidth * 440 / 310;
    final List<List<Vector2>> edges = <List<Vector2>>[
      <Vector2>[Vector2(0, 0), Vector2(0, h)],
      <Vector2>[Vector2(w, 0), Vector2(w, h)],
      <Vector2>[Vector2(0, h), Vector2(w, h)],
    ];
    for (final List<Vector2> e in edges) {
      final Body body = world.createBody(BodyDef());
      body.createFixture(
        FixtureDef(EdgeShape()..set(e[0], e[1]), friction: 0.3),
      );
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _aimX = _clampAim(screenToWorld(event.canvasEndPosition).x);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _drop();
    super.onDragEnd(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _aimX = _clampAim(screenToWorld(event.canvasPosition).x);
    _drop();
    super.onTapUp(event);
  }

  double _clampAim(double x) {
    final double r = AppDimens.ballRadii[cubit.state.current.index];
    return x.clamp(r + 2, AppDimens.worldWidth - r - 2);
  }

  void _drop() {
    if (!_canDrop || paused) return;
    _canDrop = false;
    final BallTier tier = cubit.state.current;
    world.add(BallBody(
      tier: tier,
      initialPosition: Vector2(_aimX, AppDimens.ballRadii[tier.index] + 1),
      onMerge: _merge,
    ));
    cubit.onDropped();
    // Задержка перед следующим броском.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      _canDrop = true;
    });
  }

  /// Слияние: вызывается контактом двух шаров одного тира.
  void _merge(BallBody a, BallBody b) {
    if (a.isRemoved || b.isRemoved || a.merging || b.merging) return;
    a.merging = true;
    b.merging = true;
    final BallTier? next = a.tier.next;
    final Vector2 mid = (a.body.position + b.body.position) / 2;
    cubit.onMerge(a.tier);
    a.removeFromParent();
    b.removeFromParent();
    if (next != null) {
      world.add(BallBody(tier: next, initialPosition: mid, onMerge: _merge));
      // TODO: вспышка + всплывающий «+N» (см. мокап, кадр 4)
      // TODO: звук/хаптика по настройкам
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (paused || cubit.state.status != GameStatus.playing) return;
    // Проигрыш: покоящийся шар выше линии дольше 1.5 с.
    final bool overLine = world.children.whereType<BallBody>().any(
          (BallBody b) =>
              b.settled &&
              b.body.position.y -
                      AppDimens.ballRadii[b.tier.index] <
                  deadlineY,
        );
    _overLineTime = overLine ? _overLineTime + dt : 0;
    if (_overLineTime > 1.5) {
      _overLineTime = 0;
      cubit.gameOver();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Линия проигрыша.
    final Paint paint = Paint()
      ..color = _overLineTime > 0 ? AppColors.alert : AppColors.deadline
      ..strokeWidth = 2;
    final double y = camera.viewfinder.transform
        .globalToLocal(Vector2(0, deadlineY))
        .y;
    // TODO: пунктир вместо сплошной (см. мокап)
    canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
  }

  void reset() {
    world.children.whereType<BallBody>().toList().forEach(
          (BallBody b) => b.removeFromParent(),
        );
    _overLineTime = 0;
    _canDrop = true;
  }
}
