import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flame_forge2d/flame_forge2d.dart' show Vector2;

/// Геометрия стакана в конкретных единицах (мировых или экранных):
/// контур [JarShape] умножен на [width] × [height]. Общая для физики
/// ([buildJarWalls]) и отрисовки (`JarPainter`), чтобы стенка Box2D и
/// нарисованная стенка совпадали.
class JarGeometry {
  final JarShape shape;
  final double width;
  final double height;

  JarGeometry(this.shape, {required this.width, required this.height});

  Vector2 _scale(JarPoint p) => Vector2(p.x * width, p.y * height);

  /// Внутренний контур: верх левой стенки → дно → верх правой стенки.
  List<Vector2> get wall => shape.wall.map(_scale).toList();

  List<List<Vector2>> get extras =>
      shape.extras.map((List<JarPoint> e) => e.map(_scale).toList()).toList();

  /// Левая и правая внутренние границы на высоте [y].
  (double, double) spanAt(double y) {
    final (double l, double r) = shape.spanAt(y / height);
    return (l * width, r * width);
  }

  /// Зажимает X центра тела полугабарита [extent] внутрь стакана на
  /// высоте [y]; если стакан на этой высоте уже тела — середина просвета.
  double clampX(double x, double y, double extent) {
    final (double l, double r) = spanAt(y);
    if (r - l <= 2 * extent) return (l + r) / 2;
    return x.clamp(l + extent, r - extent);
  }

  /// Контур [wall], продолженный вверх на [topMargin] у обоих концов —
  /// стенки над стаканом, чтобы подброшенный фрукт не вылетел.
  List<Vector2> wallWithMargin(double topMargin) {
    final List<Vector2> w = wall;
    return <Vector2>[
      Vector2(w.first.x, w.first.y - topMargin),
      ...w,
      Vector2(w.last.x, w.last.y - topMargin),
    ];
  }

  /// Смещает открытую полилинию [points] наружу (от интерьера стакана,
  /// который лежит справа от направления обхода) на [distance]: в вершинах
  /// — точка пересечения смещённых линий (миттер), обрезанная до
  /// 3 × [distance] на острых углах. Точек столько же, сколько в исходной,
  /// так что отрезок i исходной и отрезок i смещённой образуют
  /// четырёхугольник без щелей по внутренней кромке.
  static List<Vector2> offsetOutward(List<Vector2> points, double distance) {
    final int n = points.length;
    if (n < 2) return List<Vector2>.from(points);
    Vector2 normalOf(int i) {
      final Vector2 d = points[i + 1] - points[i];
      final double len = d.length;
      if (len < 1e-9) return Vector2(0, -1);
      // Интерьер справа от обхода → наружу = влево: (-dy, dx).
      return Vector2(-d.y / len, d.x / len);
    }

    final List<Vector2> out = <Vector2>[];
    for (int i = 0; i < n; i++) {
      final Vector2 nPrev = normalOf(i == 0 ? 0 : i - 1);
      final Vector2 nNext = normalOf(i == n - 1 ? n - 2 : i);
      final Vector2 bis = nPrev + nNext;
      final double bl = bis.length;
      if (bl < 1e-6) {
        out.add(points[i] + nNext * distance);
        continue;
      }
      bis.scale(1 / bl);
      // Длина миттера: d / cos(θ/2), где cos(θ/2) = bis · n.
      final double cosHalf = bis.dot(nNext);
      final double miter = distance / math.max(cosHalf, 1 / 3);
      out.add(points[i] + bis * miter);
    }
    return out;
  }
}
