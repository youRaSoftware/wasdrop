import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:domain/domain.dart';
import 'package:flame/cache.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart'
    show Circle, Polygon, ShapeGeometry;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

/// Кто умеет отдать спрайты фруктов (реализует `WasDropGame`); нужен, чтобы
/// `BallBody` и оверлей не зависели от класса игры напрямую.
abstract interface class FruitSpriteProvider {
  FruitSprites get fruitSprites;
}

/// Пара спрайтов одного тира («рот закрыт» / «рот открыт») плюс физическая
/// форма тела, измеренная по альфа-каналу при загрузке (ТЗ § 1): круглые
/// фрукты — круг, вытянутые и с носиками (виноград, лимон, клубника) —
/// скруглённый многоугольник до 8 вершин. Стебель и листик выступают
/// за форму — это норма.
class FruitSprite {
  final Sprite idle;
  final Sprite squish;

  /// Сколько пикселей исходника приходится на номинальный радиус тира
  /// (`AppDimens.ballRadii`): масштаб отрисовки и формы.
  final double fitRadiusPx;

  /// Точка исходника (px), которая совмещается с началом координат тела.
  final Vector2 bodyCenter;

  /// Вершины многоугольника (px, относительно [bodyCenter]); null — круг.
  final List<Vector2>? hull;

  /// Радиус скругления многоугольника (px).
  final double roundingPx;

  /// Наибольшее и наименьшее расстояние от [bodyCenter] до границы тела (px).
  final double maxExtentPx;
  final double minExtentPx;

  const FruitSprite({
    required this.idle,
    required this.squish,
    required this.fitRadiusPx,
    required this.bodyCenter,
    required this.hull,
    required this.roundingPx,
    required this.maxExtentPx,
    required this.minExtentPx,
  });

  bool get isPolygon => hull != null;

  /// Мировых единиц в пикселе исходника при номинальном радиусе [radius].
  double scale(double radius) => radius / fitRadiusPx;

  /// Физическая форма тела для номинального радиуса [radius]
  /// (в локальных координатах тела, спрайт стоит прямо).
  ShapeGeometry shape(double radius) {
    final List<Vector2>? hull = this.hull;
    if (hull == null) return Circle(radius: radius);
    final double k = scale(radius);
    return Polygon(
      hull.map((Vector2 v) => v * k).toList(),
      radius: roundingPx * k,
    );
  }

  /// Наибольший габарит тела от его начала координат (мировые единицы).
  double extent(double radius) =>
      hull == null ? radius : maxExtentPx * scale(radius);

  /// Наименьший габарит тела от его начала координат (мировые единицы).
  double minExtent(double radius) =>
      hull == null ? radius : minExtentPx * scale(radius);

  /// Рисует фрукт так, чтобы его тело совпало с формой номинального радиуса
  /// [radius] с началом координат [center] (в координатах [canvas]).
  void render(
    ui.Canvas canvas, {
    required Vector2 center,
    required double radius,
    bool squished = false,
  }) {
    final Sprite sprite = squished ? squish : idle;
    final double k = scale(radius);
    sprite.render(
      canvas,
      position: center - bodyCenter * k,
      size: sprite.srcSize * k,
    );
  }
}

/// Кэш спрайтов по тирам. Файлы: `features/assets/images/fruits/t{N}_idle.png`
/// и `t{N}_squish.png` (N = 1…11). Загружается один раз в `WasDropGame.onLoad`;
/// если у тира нет своей графики — вызывающий код рисует градиент + эмодзи.
class FruitSprites {
  static const String package = 'features';
  static const String folder = 'fruits';

  /// Порог альфы, с которого пиксель считается телом фрукта. Высокий,
  /// чтобы не считать телом полупрозрачный ореол после удаления фона.
  static const int _alphaThreshold = 200;

  /// Строки не уже этой доли самой широкой — контур для подгонки круга
  /// (отсекает стебель, листик и макушку).
  static const double _circleRowFraction = 0.6;

  /// Строки не уже этой доли самой широкой — верх тела для многоугольника
  /// (отсекает только тонкий стебель).
  static const double _bodyRowFraction = 0.2;

  /// Если контур отклоняется от круга не больше этой доли радиуса —
  /// тело круглое.
  static const double _circleTolerance = 0.05;

  /// Направлений, по которым сравнивается опорная функция силуэта и формы.
  static const int _directions = 72;

  /// Вершин многоугольника (лимит Box2D — 8).
  static const int _vertices = 8;

  final Map<BallTier, FruitSprite> _byTier = <BallTier, FruitSprite>{};

  /// Тиры, у которых есть собственные (не подставленные) спрайты.
  final Set<BallTier> ownArt = <BallTier>{};

  FruitSprite? operator [](BallTier tier) => _byTier[tier];

  bool get isEmpty => _byTier.isEmpty;

  static String fileName(BallTier tier, String state) =>
      '$folder/t${tier.number}_$state.png';

  Future<void> load(Images images) async {
    final Set<String> manifest =
        (await AssetManifest.loadFromAssetBundle(rootBundle))
            .listAssets()
            .toSet();
    bool exists(String file) =>
        manifest.contains('packages/$package/${images.prefix}$file');

    for (final BallTier tier in BallTier.values) {
      final String idleFile = fileName(tier, 'idle');
      final String squishFile = fileName(tier, 'squish');
      if (!exists(idleFile)) continue;

      final ui.Image idle = await images.load(idleFile, package: package);
      final ui.Image squish = exists(squishFile)
          ? await images.load(squishFile, package: package)
          : idle;
      final _BodyFit fit = await _measureBody(idle);
      _byTier[tier] = FruitSprite(
        idle: Sprite(idle),
        squish: Sprite(squish),
        fitRadiusPx: fit.radiusPx,
        bodyCenter: fit.center,
        hull: fit.hull,
        roundingPx: fit.roundingPx,
        maxExtentPx: fit.maxExtentPx,
        minExtentPx: fit.minExtentPx,
      );
      ownArt.add(tier);
    }
  }

  /// Находит тело фрукта по альфа-каналу и подбирает физическую форму.
  ///
  /// В каждой строке берётся самый длинный непрозрачный отрезок (чтобы
  /// торчащий вбок листик не считался телом). Сначала подгоняется круг:
  /// контур — края строк шире [_circleRowFraction] от самой широкой (без
  /// стебля и макушки), круг прижат к нижней точке силуэта (центр =
  /// низ − r, чтобы фрукт стоял на дне), X центра — середина самой широкой
  /// строки, радиус — методом наименьших квадратов. Если контур отклоняется
  /// от круга не больше [_circleTolerance] — тело круглое (у круглых
  /// фруктов 0.7–3.8 %).
  ///
  /// Иначе (виноград, лимон, клубника: 8–12 %) строится скруглённый
  /// многоугольник: тело — строки от первой шире [_bodyRowFraction] до
  /// низа; в [_vertices] направлениях берутся опорные точки силуэта,
  /// сдвигаются внутрь на радиус скругления ρ и образуют выпуклую оболочку;
  /// форма Box2D = оболочка ⊕ круг ρ. ρ перебирается как доля наименьшего
  /// полугабарита, выбирается по наименьшему расхождению опорных функций
  /// силуэта и формы в [_directions] направлениях (остаток 2–3 %). Нижняя
  /// опорная точка совпадает с низом силуэта — фрукт стоит на дне.
  /// Под фруктом в PNG не должно быть теней — они стали бы «низом».
  static Future<_BodyFit> _measureBody(ui.Image image) async {
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final int w = image.width;
    final int h = image.height;
    final _BodyFit fallback = _BodyFit.circle(
      radiusPx: w * 0.475,
      center: Vector2(w / 2, h / 2),
    );
    if (data == null) return fallback;

    // Самый длинный непрозрачный отрезок в каждой строке: [start, end).
    final List<int> runStart = List<int>.filled(h, -1);
    final List<int> runEnd = List<int>.filled(h, -1);
    int maxWidth = 0;
    double widestCenter = w / 2;
    int bottom = -1;
    for (int y = 0; y < h; y++) {
      int start = -1;
      for (int x = 0; x <= w; x++) {
        final bool opaque =
            x < w && data.getUint8((y * w + x) * 4 + 3) > _alphaThreshold;
        if (opaque && start < 0) start = x;
        if (!opaque && start >= 0) {
          if (x - start > runEnd[y] - runStart[y]) {
            runStart[y] = start;
            runEnd[y] = x;
          }
          start = -1;
        }
      }
      if (runStart[y] < 0) continue;
      bottom = y;
      final int width = runEnd[y] - runStart[y];
      if (width > maxWidth) {
        maxWidth = width;
        widestCenter = (runStart[y] + runEnd[y]) / 2;
      }
    }
    if (maxWidth == 0 || bottom < 0) return fallback;
    final double bottomEdge = bottom + 1.0;

    // --- Круг ---------------------------------------------------------
    final List<Vector2> circleContour = <Vector2>[];
    final int minCircleWidth = (maxWidth * _circleRowFraction).round();
    for (int y = 0; y < h; y++) {
      if (runStart[y] < 0 || runEnd[y] - runStart[y] < minCircleWidth) {
        continue;
      }
      circleContour.add(Vector2(runStart[y].toDouble(), y + 0.5));
      circleContour.add(Vector2(runEnd[y].toDouble(), y + 0.5));
    }
    if (circleContour.length < 6) return fallback;
    double circleRadius = maxWidth / 2;
    double circleCost = double.infinity;
    for (double r = maxWidth * 0.35; r <= maxWidth * 0.65; r += 0.5) {
      final double cy = bottomEdge - r;
      double cost = 0;
      for (final Vector2 p in circleContour) {
        final double dx = p.x - widestCenter;
        final double dy = p.y - cy;
        final double d = math.sqrt(dx * dx + dy * dy) - r;
        cost += d * d;
      }
      if (cost < circleCost) {
        circleCost = cost;
        circleRadius = r;
      }
    }
    final _BodyFit circle = _BodyFit.circle(
      radiusPx: circleRadius,
      center: Vector2(widestCenter, bottomEdge - circleRadius),
    );
    final double circleRms =
        math.sqrt(circleCost / circleContour.length) / circleRadius;
    if (circleRms <= _circleTolerance) return circle;

    // --- Скруглённый многоугольник --------------------------------------
    final int minBodyWidth = (maxWidth * _bodyRowFraction).round();
    int top = -1;
    for (int y = 0; y < h; y++) {
      if (runStart[y] >= 0 && runEnd[y] - runStart[y] >= minBodyWidth) {
        top = y;
        break;
      }
    }
    if (top < 0) return circle;
    final List<Vector2> contour = <Vector2>[];
    double minX = w.toDouble();
    double maxX = 0;
    for (int y = top; y <= bottom; y++) {
      if (runStart[y] < 0) continue;
      contour.add(Vector2(runStart[y].toDouble(), y + 0.5));
      contour.add(Vector2(runEnd[y].toDouble(), y + 0.5));
      minX = math.min(minX, runStart[y].toDouble());
      maxX = math.max(maxX, runEnd[y].toDouble());
    }
    final Vector2 center = Vector2((minX + maxX) / 2, (top + bottomEdge) / 2);

    // Опорная функция силуэта: наибольшая проекция контура на направление.
    Vector2 direction(int k, int count) {
      final double a = 2 * math.pi * k / count;
      return Vector2(math.cos(a), math.sin(a));
    }

    final List<Vector2> dirs = List<Vector2>.generate(
      _directions,
      (int k) => direction(k, _directions),
    );
    final List<double> support = List<double>.filled(_directions, 0);
    for (int k = 0; k < _directions; k++) {
      double best = double.negativeInfinity;
      for (final Vector2 p in contour) {
        best = math.max(best, (p - center).dot(dirs[k]));
      }
      support[k] = best;
    }
    final double minSupport = support.reduce(math.min);
    final double maxSupport = support.reduce(math.max);
    final double meanSupport =
        support.reduce((double a, double b) => a + b) / _directions;
    if (minSupport <= 0) return circle;

    final List<Vector2> anchors = <Vector2>[];
    for (int k = 0; k < _vertices; k++) {
      final Vector2 d = direction(k, _vertices);
      Vector2? best;
      double bestDot = double.negativeInfinity;
      for (final Vector2 p in contour) {
        final double dot = (p - center).dot(d);
        if (dot > bestDot) {
          bestDot = dot;
          best = p;
        }
      }
      anchors.add(best! - center);
    }

    List<Vector2>? bestHull;
    double bestRounding = 0;
    double bestError = double.infinity;
    for (double f = 0.4; f <= 0.8; f += 0.1) {
      final double rounding = f * minSupport;
      final List<Vector2> hull = _convexHull(<Vector2>[
        for (int k = 0; k < _vertices; k++)
          anchors[k] - direction(k, _vertices) * rounding,
      ]);
      if (hull.length < 3) continue;
      double error = 0;
      for (int k = 0; k < _directions; k++) {
        double hp = double.negativeInfinity;
        for (final Vector2 v in hull) {
          hp = math.max(hp, v.dot(dirs[k]));
        }
        final double rel = (hp + rounding - support[k]) / support[k];
        error += rel * rel;
      }
      if (error < bestError) {
        bestError = error;
        bestHull = hull;
        bestRounding = rounding;
      }
    }
    if (bestHull == null) return circle;
    return _BodyFit(
      radiusPx: meanSupport,
      center: center,
      hull: bestHull,
      roundingPx: bestRounding,
      maxExtentPx: maxSupport,
      minExtentPx: minSupport,
    );
  }

  /// Выпуклая оболочка (monotone chain), против часовой стрелки в
  /// экранных координатах; коллинеарные точки отбрасываются.
  static List<Vector2> _convexHull(List<Vector2> points) {
    final List<Vector2> sorted = points.toList()
      ..sort((Vector2 a, Vector2 b) =>
          a.x != b.x ? a.x.compareTo(b.x) : a.y.compareTo(b.y));
    if (sorted.length < 3) return sorted;
    double cross(Vector2 o, Vector2 a, Vector2 b) =>
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
    final List<Vector2> lower = <Vector2>[];
    for (final Vector2 p in sorted) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final List<Vector2> upper = <Vector2>[];
    for (final Vector2 p in sorted.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }
    lower.removeLast();
    upper.removeLast();
    return lower..addAll(upper);
  }
}

class _BodyFit {
  final double radiusPx;
  final Vector2 center;
  final List<Vector2>? hull;
  final double roundingPx;
  final double maxExtentPx;
  final double minExtentPx;

  const _BodyFit({
    required this.radiusPx,
    required this.center,
    required this.hull,
    required this.roundingPx,
    required this.maxExtentPx,
    required this.minExtentPx,
  });

  _BodyFit.circle({required double radiusPx, required Vector2 center})
      : this(
          radiusPx: radiusPx,
          center: center,
          hull: null,
          roundingPx: 0,
          maxExtentPx: radiusPx,
          minExtentPx: radiusPx,
        );
}
