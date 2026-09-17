import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame_forge2d/flame_forge2d.dart' show Vector2;
import 'package:flutter/material.dart';

import '../engine/jar_geometry.dart';

/// Стакан по контуру [JarShape]: заливка внутренней области и стенка
/// толщиной [wallWidth] снаружи контура (внешняя кромка — тем же миттером,
/// что и коробки физики, так что нарисованная стенка совпадает с
/// физической). Внутренняя область = размер виджета минус стенка слева,
/// справа и снизу; сверху стакан открыт. Тот же painter рисует миниатюры
/// в пикере стаканов.
class JarPainter extends CustomPainter {
  final JarShape shape;
  final Color fill;
  final Color wall;
  final double wallWidth;

  /// Что рисовать: в игре заливка лежит под холстом, а стенка — поверх.
  final JarLayer layer;

  const JarPainter({
    required this.shape,
    required this.fill,
    required this.wall,
    this.wallWidth = AppDimens.jarWallWidth,
    this.layer = JarLayer.all,
  });

  /// Внутренняя область стакана в координатах виджета размера [size].
  static Rect innerRect(Size size, double wallWidth) => Rect.fromLTWH(
        wallWidth,
        0,
        size.width - 2 * wallWidth,
        size.height - wallWidth,
      );

  /// Путь внутреннего контура (замкнут по верхнему краю) в координатах
  /// виджета — им же обрезается холст игры.
  static Path innerPath(JarShape shape, Size size, double wallWidth) {
    final Rect r = innerRect(size, wallWidth);
    final JarGeometry g = JarGeometry(shape, width: r.width, height: r.height);
    return _polygon(g.wall, r.topLeft)..close();
  }

  static Path _polygon(List<Vector2> pts, Offset origin) {
    final Path path = Path();
    for (int i = 0; i < pts.length; i++) {
      final Offset p = origin + Offset(pts[i].x, pts[i].y);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Стенка над верхом виджета не рисуется (она нужна только для
    // ровного торца у наклонных стенок).
    canvas.clipRect(Offset.zero & size);
    final Rect r = innerRect(size, wallWidth);
    final JarGeometry g = JarGeometry(shape, width: r.width, height: r.height);
    // Стенка продолжается выше верха виджета (обрезается холстом), чтобы
    // у наклонных стенок верхний торец был ровным.
    final List<Vector2> inner = g.wallWithMargin(wallWidth * 4);
    final List<Vector2> outer = JarGeometry.offsetOutward(inner, wallWidth);
    final Paint wallPaint = Paint()..color = wall;
    final Path ring = _polygon(outer, r.topLeft);
    for (final Vector2 p in inner.reversed) {
      ring.lineTo(r.left + p.x, r.top + p.y);
    }
    ring.close();
    if (layer != JarLayer.wall) {
      canvas.drawPath(
        _polygon(g.wall, r.topLeft)..close(),
        Paint()..color = fill,
      );
    }
    if (layer != JarLayer.fill) {
      canvas.drawPath(ring, wallPaint);
      // Полка / платформа — поверх заливки.
      for (final List<Vector2> extra in g.extras) {
        canvas.drawPath(_polygon(extra, r.topLeft)..close(), wallPaint);
      }
    }
  }

  @override
  bool shouldRepaint(JarPainter old) =>
      old.shape != shape ||
      old.fill != fill ||
      old.wall != wall ||
      old.wallWidth != wallWidth ||
      old.layer != layer;
}

enum JarLayer { all, fill, wall }
