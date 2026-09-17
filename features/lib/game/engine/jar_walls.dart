import 'package:flame_forge2d/flame_forge2d.dart';

import 'jar_geometry.dart';
import 'physics_tuning.dart';

/// Маркер `userData` статического тела стенок и дна стакана.
///
/// Forge2D вызывает `beginContact` только для тел с непустым `userData`,
/// поэтому без маркера шар не узнал бы об ударе о дно и не «ойкал» бы.
class JarWalls {
  const JarWalls();
}

/// Строит статическое тело стенок и дна по контуру [jar] и возвращает
/// его; при ресайзе старое тело уничтожается снаружи и строится новое.
///
/// Стенка — цепочка толстых четырёхугольников (по одному на отрезок
/// контура, [thickness] наружу), а не тонкие отрезки: шар, вдавленный
/// ударом в тонкий Segment, проходил сквозь него (центр пересекал линию —
/// и его выталкивало не в ту сторону). Внешняя кромка построена миттером
/// ([JarGeometry.offsetOutward]), так что соседние коробки стыкуются без
/// щелей по внутренней кромке; небольшой [Polygon.radius] сглаживает
/// стыки, чтобы катящийся фрукт не цеплялся за вершины дискретизированных
/// дуг. [topMargin] — насколько боковые стенки продолжаются выше верха
/// (игра передаёт большой запас: подброшенный встряской фрукт не должен
/// перелететь через стенку); по умолчанию — на толщину стенки. [extras]
/// (полка) — отдельные выпуклые многоугольники.
Body buildJarWalls(
  Forge2DWorld world,
  JarGeometry jar, {
  double thickness = 40,
  double? topMargin,
}) {
  final double t = thickness;
  final List<Vector2> inner = jar.wallWithMargin(topMargin ?? thickness);
  final List<Vector2> outer = JarGeometry.offsetOutward(inner, t);

  final Body walls = world.createBody(
    BodyDef(type: BodyType.static, userData: const JarWalls()),
  );
  final ShapeDef material = ShapeDef(
    material: SurfaceMaterial(friction: PhysicsTuning.wallFriction),
  );
  for (int i = 0; i < inner.length - 1; i++) {
    final List<Vector2> quad = <Vector2>[
      inner[i],
      inner[i + 1],
      outer[i + 1],
      outer[i],
    ];
    if (_area(quad) < 1e-3) continue;
    walls.createShape(
      Polygon(quad, radius: PhysicsTuning.wallJointRadius),
      material,
    );
  }
  for (final List<Vector2> extra in jar.extras) {
    if (extra.length < 3) continue;
    // Выпуклая оболочка (Polygon её строит сам); скруглённые торцы
    // полки заданы точками контура, ≤ 8 вершин Box2D — прореживаем.
    final List<Vector2> pts = extra.length <= 8 ? extra : _thin(extra, 8);
    walls.createShape(Polygon(pts, radius: 1), material);
  }
  return walls;
}

double _area(List<Vector2> p) {
  double a = 0;
  for (int i = 0; i < p.length; i++) {
    final Vector2 u = p[i];
    final Vector2 v = p[(i + 1) % p.length];
    a += u.x * v.y - v.x * u.y;
  }
  return a.abs() / 2;
}

List<Vector2> _thin(List<Vector2> pts, int max) {
  final List<Vector2> out = <Vector2>[];
  for (int i = 0; i < max; i++) {
    out.add(pts[(i * pts.length / max).floor()]);
  }
  return out;
}
