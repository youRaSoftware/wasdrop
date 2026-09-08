import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';

import 'physics_tuning.dart';

/// Физический мир стакана (игра и сплеш): несколько шагов Box2D на кадр.
///
/// Box2D заводит контакт заранее только на спекулятивной дистанции
/// ([PhysicsTuning.speculativeDistance]), а непрерывную коллизию включает
/// лишь телам, которые за шаг проходят больше половины радиуса. Значит,
/// падающий шар не должен проходить за шаг больше этой дистанции — иначе
/// контакт с дном возникает уже внутри дна (вишня проваливалась на 16 %
/// диаметра и «всплывала»). Число шагов считается от длины кадра: при
/// 60 fps их 6, при лаге до 30 fps — 12, на 120 Гц — 3. Контактные события
/// раздаются после каждого шага, иначе Box2D их теряет.
class JarPhysicsWorld extends Forge2DWorld {
  JarPhysicsWorld({required super.gravity, required super.definition});

  /// Мир с гравитацией и допусками из [PhysicsTuning]. forge2d передаёт
  /// скорости `WorldDef` в Box2D без пересчёта из метров, поэтому
  /// «метровые» дефолты уже умножены на масштаб в [PhysicsTuning].
  factory JarPhysicsWorld.standard() {
    return JarPhysicsWorld(
      gravity: Vector2(0, PhysicsTuning.gravity),
      definition: WorldDef(
        maxContactPushSpeed: PhysicsTuning.maxContactPushSpeed,
        restitutionThreshold: PhysicsTuning.restitutionThreshold,
        hitEventThreshold: PhysicsTuning.hitEventThreshold,
        contactHertz: PhysicsTuning.contactHertz,
        contactDampingRatio: PhysicsTuning.contactDampingRatio,
        maximumLinearSpeed: PhysicsTuning.maxSpeed,
      ),
    );
  }

  /// Сколько шагов сделал последний кадр (для тестов).
  int lastSteps = 0;

  @override
  void update(double dt) {
    final double frameDt = math.min(dt, PhysicsTuning.maxFrameDt);
    final int steps =
        (frameDt * PhysicsTuning.maxSpeed / PhysicsTuning.speculativeDistance)
            .ceil()
            .clamp(1, PhysicsTuning.maxStepsPerFrame);
    lastSteps = steps;
    final double stepDt = frameDt / steps;
    for (int i = 0; i < steps; i++) {
      physicsWorld.step(stepDt, subStepCount: subStepCount);
      contactEventsDispatcher.dispatch(
        physicsWorld.contactEvents,
        physicsWorld.sensorEvents,
      );
    }
  }
}
