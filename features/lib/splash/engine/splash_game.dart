import 'dart:math' as math;

import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' show Color;

import '../../game/engine/ball_body.dart';
import '../../game/engine/fruit_sprites.dart';
import '../../game/engine/jar_physics_world.dart';
import '../../game/engine/jar_walls.dart';
import '../../game/engine/physics_tuning.dart';

/// Сплеш (и живой фон меню): с неба сыплются фрукты и складываются в кучу у
/// нижнего края — тот же движок и те же тела, что в игре ([BallBody],
/// [FruitSprites]), но без слияний и стакана: стенки — края экрана. Фон
/// прозрачный, градиент темы рисует `AppScaffold`. На широких холстах мир
/// растягивается ([phoneCanvasWidth]), фруктов насыпается пропорционально.
class SplashGame extends Forge2DGame implements FruitSpriteProvider {
  static const int defaultFruitCount = 20;

  /// Пауза между появлениями фруктов, с.
  static const double defaultSpawnInterval = 0.11;

  /// Самый крупный тир в куче по умолчанию (t9 — персик).
  static const int defaultMaxTierIndex = 8;

  /// Ширина холста (pt), до которой мир равен игровому (360 ед.); шире —
  /// мир растягивается, чтобы фрукты на планшете были того же размера,
  /// что на телефоне, а не в 2.5 раза крупнее.
  static const double phoneCanvasWidth = 430;

  /// Толчок фрукта по тапу ([poke]): скорость вверх и вбок, вращение.
  static const double pokeLift = 520;
  static const double pokeSide = 160;
  static const double pokeSpin = 8;

  /// Сколько фруктов насыпать на ширину 360 ед. (масштабируется с миром).
  final int fruitCountPerPhone;
  final double spawnInterval;

  /// Самый крупный тир в куче (индекс в [BallTier.values]).
  final int maxTierIndex;

  @override
  final FruitSprites fruitSprites = FruitSprites.shared;

  final math.Random _random = math.Random();

  double worldWidth = AppDimens.worldWidth;
  double worldHeight = AppDimens.worldWidth * 2;
  int fruitCount = defaultFruitCount;
  Body? _walls;
  int _spawned = 0;
  double _sinceSpawn = 0;

  SplashGame({
    this.fruitCountPerPhone = defaultFruitCount,
    this.spawnInterval = defaultSpawnInterval,
    this.maxTierIndex = defaultMaxTierIndex,
  }) : super(
          world: JarPhysicsWorld.standard(),
          lengthUnitsPerMeter: PhysicsTuning.unitsPerMeter,
        );

  /// Сколько фруктов уже упало с неба (для тестов).
  int get spawned => _spawned;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    world.subStepCount = PhysicsTuning.subSteps;
    await fruitSprites.load(images);
    camera.viewfinder.anchor = Anchor.topLeft;
    _layout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout(size);
  }

  void _layout(Vector2 canvasSize) {
    if (canvasSize.x <= 0 || canvasSize.y <= 0) return;
    worldWidth =
        AppDimens.worldWidth * math.max(1, canvasSize.x / phoneCanvasWidth);
    fruitCount =
        (fruitCountPerPhone * worldWidth / AppDimens.worldWidth).round();
    worldHeight = worldWidth * canvasSize.y / canvasSize.x;
    camera.viewfinder.visibleGameSize = Vector2(worldWidth, worldHeight);
    final Body? oldWalls = _walls;
    if (oldWalls != null) world.destroyBody(oldWalls);
    _walls = buildJarWalls(world, width: worldWidth, height: worldHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || _spawned >= fruitCount) return;
    _sinceSpawn += dt;
    if (_sinceSpawn < spawnInterval) return;
    _sinceSpawn = 0;
    _spawned++;
    _spawnFruit();
  }

  void _spawnFruit() {
    // Мелкие фрукты чаще крупных, чтобы куча не переполнила экран.
    final int tierIndex =
        (math.pow(_random.nextDouble(), 1.6) * (maxTierIndex + 1)).floor();
    final BallTier tier = BallTier.values[tierIndex];
    final double r = AppDimens.ballRadii[tier.index];
    final BallBody ball = BallBody(
      tier: tier,
      initialPosition: Vector2(
        r + _random.nextDouble() * (worldWidth - 2 * r),
        -r - _random.nextDouble() * 120,
      ),
      initialVelocity: Vector2((_random.nextDouble() - 0.5) * 120, 0),
      onMerge: _ignoreMerge,
    );
    world.add(ball);
    // Лёгкое вращение, чтобы падали живее.
    ball.mounted.then((_) {
      if (ball.isMounted) {
        ball.body.angularVelocity = (_random.nextDouble() - 0.5) * 6;
      }
    });
  }

  static void _ignoreMerge(BallBody a, BallBody b) {}

  /// Подбрасывает фрукт под точкой [at] (мировые координаты): подскок,
  /// вращение и «ойк». Тапы принимает `MenuPileGame`; сама заставка тапы
  /// не перехватывает — иначе GameWidget отбирал бы их у «пропустить».
  void poke(Vector2 at) {
    if (!isLoaded) return;
    BallBody? hit;
    double best = double.infinity;
    for (final BallBody b in world.children.whereType<BallBody>()) {
      if (!b.isMounted) continue;
      final double d = b.body.position.distanceTo(at) - b.radius * 1.15;
      if (d < 0 && d < best) {
        best = d;
        hit = b;
      }
    }
    if (hit == null) return;
    final Vector2 dv = Vector2(
      (_random.nextDouble() - 0.5) * 2 * pokeSide,
      -pokeLift * (0.8 + 0.4 * _random.nextDouble()),
    );
    hit.body.applyLinearImpulse(dv * hit.body.mass);
    hit.body.applyAngularImpulse(
      (_random.nextDouble() - 0.5) * 2 * pokeSpin * hit.body.rotationalInertia,
    );
    hit.showSquishFace();
  }

  @override
  void onRemove() {
    super.onRemove();
    // Box2D держит ограниченное число миров и не освобождает их сам.
    world.physicsWorld.destroy();
  }
}
