import 'package:flame_forge2d/flame_forge2d.dart';

import 'physics_tuning.dart';

/// Маркер `userData` статического тела стенок и дна стакана.
///
/// Forge2D вызывает `beginContact` только для тел с непустым `userData`,
/// поэтому без маркера шар не узнал бы об ударе о дно и не «ойкал» бы.
class JarWalls {
  const JarWalls();
}

/// Строит статическое тело стенок и дна для мира [width] × [height]
/// (игра — стакан, сплеш — края экрана) и возвращает его; при ресайзе
/// старое тело уничтожается снаружи и строится новое.
///
/// Стенки — толстые коробки за пределами видимой области, а не тонкие
/// отрезки: шар, вдавленный ударом сверху в тонкий Segment, проходил сквозь
/// него (центр пересекал линию — и его выталкивало вниз). У коробки центр
/// остаётся внутри, и солвер возвращает шар в стакан. [chamfer] > 0 —
/// 45° скосы в нижних углах под визуальное скругление стакана: прямой
/// физический угол давал бы фрукту закатиться под скругление и обрезаться.
Body buildJarWalls(
  Forge2DWorld world, {
  required double width,
  required double height,
  double chamfer = 0,
  double thickness = 40,
}) {
  final double w = width;
  final double h = height;
  final double t = thickness;
  List<Vector2> rect(double x1, double y1, double x2, double y2) => <Vector2>[
        Vector2(x1, y1),
        Vector2(x2, y1),
        Vector2(x2, y2),
        Vector2(x1, y2),
      ];
  final List<List<Vector2>> boxes = <List<Vector2>>[
    rect(-t, -t, 0, h + t), // левая
    rect(w, -t, w + t, h + t), // правая
    rect(-t, h, w + t, h + t), // дно
  ];
  if (chamfer > 0) {
    boxes.addAll(<List<Vector2>>[
      <Vector2>[Vector2(0, h - chamfer), Vector2(chamfer, h), Vector2(0, h)],
      <Vector2>[
        Vector2(w, h - chamfer),
        Vector2(w, h),
        Vector2(w - chamfer, h),
      ],
    ]);
  }
  final Body walls = world.createBody(
    BodyDef(type: BodyType.static, userData: const JarWalls()),
  );
  for (final List<Vector2> corners in boxes) {
    walls.createShape(
      Polygon(corners),
      ShapeDef(
        material: SurfaceMaterial(friction: PhysicsTuning.wallFriction),
      ),
    );
  }
  return walls;
}
