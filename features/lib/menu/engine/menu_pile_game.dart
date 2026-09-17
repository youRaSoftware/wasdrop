import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../game/engine/ball_body.dart';
import '../../game/engine/jar_walls.dart';
import '../../game/engine/physics_tuning.dart';
import '../../splash/engine/splash_game.dart';

/// Куча фруктов в меню: заставка, которая быстро насыпает фрукты и даёт
/// подбросить любой из них тапом, а по наклону телефона пересыпает кучу
/// ([setTilt]: перевернул — все упали к верху экрана). Кладётся под
/// интерфейс меню, тапы по кнопкам до неё не доходят.
class MenuPileGame extends SplashGame with TapCallbacks {
  /// Слабее этого наклон не считается (телефон лежит) — гравитация
  /// остаётся прежней.
  static const double minTilt = 2.5;

  MenuPileGame({
    required super.fruitCountPerPhone,
    required super.spawnInterval,
    required super.maxTierIndex,
  });

  /// Потолок над экраном, чтобы перевёрнутая куча не улетела; строится,
  /// когда все фрукты насыпались и оказались внутри экрана.
  Body? _ceiling;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    poke(screenToWorld(event.canvasPosition));
  }

  /// Наклон в осях экрана (м/с², см. `TiltDetector`): гравитация мира
  /// поворачивается вслед, спящие фрукты будятся.
  void setTilt(double x, double y) {
    if (!isLoaded) return;
    final double len = math.sqrt(x * x + y * y);
    if (len < minTilt) return;
    final Vector2 g = Vector2(x / len, y / len) * PhysicsTuning.gravity;
    if ((world.physicsWorld.gravity - g).length < 1) return;
    world.physicsWorld.gravity = g;
    for (final BallBody b in world.children.whereType<BallBody>()) {
      if (b.isMounted) b.body.isAwake = true;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final Body? old = _ceiling;
    if (old != null) {
      world.destroyBody(old);
      _ceiling = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_ceiling != null || !isLoaded || spawned < fruitCount) return;
    final Iterable<BallBody> balls = world.children.whereType<BallBody>();
    if (balls
        .any((BallBody b) => !b.isMounted || b.body.position.y < b.radius)) {
      return;
    }
    const double t = 40;
    _ceiling = world.createBody(
      BodyDef(type: BodyType.static, userData: const JarWalls()),
    )..createShape(
        Polygon(<Vector2>[
          Vector2(-t, -t),
          Vector2(worldWidth + t, -t),
          Vector2(worldWidth + t, 0),
          Vector2(-t, 0),
        ]),
        ShapeDef(
          material: SurfaceMaterial(friction: PhysicsTuning.wallFriction),
        ),
      );
  }
}
