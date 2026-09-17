// Стенки стакана по контуру (JarGeometry → цепочка коробок Box2D): в каждом
// стакане фрукты, брошенные по всей ширине горла, засыпают ВНУТРИ контура
// (не проваливаются сквозь дно и наклонные стенки, не залипают в швах
// между коробками) и не заходят в полку.
import 'dart:math' as math;

import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:features/game/engine/ball_body.dart';
import 'package:features/game/engine/jar_geometry.dart';
import 'package:features/game/engine/jar_physics_world.dart';
import 'package:features/game/engine/jar_walls.dart';
import 'package:flame/components.dart' hide World;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';

const double worldW = 360;
const double worldH = 540;

class _JarGame extends Forge2DGame {
  final JarShape shape;
  late final JarGeometry jar =
      JarGeometry(shape, width: worldW, height: worldH);

  _JarGame(this.shape) : super(world: JarPhysicsWorld.standard());

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.visibleGameSize = Vector2(worldW, worldH);
    buildJarWalls(world, jar, topMargin: 300);
  }
}

/// Расстояние от точки до отрезка.
double _distToSegment(Vector2 p, Vector2 a, Vector2 b) {
  final Vector2 ab = b - a;
  final double len2 = ab.length2;
  if (len2 < 1e-9) return (p - a).length;
  final double t = ((p - a).dot(ab) / len2).clamp(0.0, 1.0);
  return (p - (a + ab * t)).length;
}

double _distToPolyline(Vector2 p, List<Vector2> pts, {bool closed = false}) {
  double best = double.infinity;
  final int n = closed ? pts.length : pts.length - 1;
  for (int i = 0; i < n; i++) {
    best = math.min(best, _distToSegment(p, pts[i], pts[(i + 1) % pts.length]));
  }
  return best;
}

bool _inside(Vector2 p, List<Vector2> poly) {
  bool inside = false;
  for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final Vector2 a = poly[i];
    final Vector2 b = poly[j];
    if ((a.y > p.y) != (b.y > p.y) &&
        p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offsetOutward: внешняя кромка классики лежит снаружи', () {
    final JarGeometry jar =
        JarGeometry(JarShapes.byId('classic'), width: worldW, height: worldH);
    final List<Vector2> inner = jar.wallWithMargin(100);
    final List<Vector2> outer = JarGeometry.offsetOutward(inner, 40);
    expect(outer.length, inner.length);
    expect(outer.first.x, closeTo(-40, 1e-6));
    expect(outer.last.x, closeTo(worldW + 40, 1e-6));
    // Дно: смещено вниз ровно на толщину.
    final int mid = inner.length ~/ 2;
    expect(outer[mid].y, greaterThan(inner[mid].y + 30));
  });

  test('spanAt: горло вазы уже мира, у классики — вся ширина', () {
    final JarShape vase = JarShapes.byId('vase');
    final (double l, double r) = vase.spanAt(0.01);
    expect(l, greaterThan(0.1));
    expect(r, lessThan(0.9));
    final (double l2, double r2) = vase.spanAt(0.9);
    expect(l2, closeTo(0, 1e-3));
    expect(r2, closeTo(1, 1e-3));
    final (double cl, double cr) = JarShapes.byId('classic').spanAt(0.5);
    expect(cl, 0);
    expect(cr, 1);
    final (double hl, double hr) = JarShapes.byId('hourglass').spanAt(0.51);
    expect(hr - hl, lessThan(0.55));
  });

  for (final JarShape shape
      in JarShapes.all.where((JarShape s) => !s.comingSoon)) {
    test('стакан «${shape.id}»: фрукты засыпают внутри контура', () async {
      final _JarGame game = _JarGame(shape);
      game.onGameResize(Vector2(worldW, worldH));
      // ignore: invalid_use_of_internal_member
      await game.load();
      // ignore: invalid_use_of_internal_member
      game.mount();
      game.update(0);
      await Future<void>.delayed(Duration.zero);

      final List<BallBody> balls = <BallBody>[];
      const List<BallTier> tiers = <BallTier>[
        BallTier.t1,
        BallTier.t3,
        BallTier.t2,
        BallTier.t5,
        BallTier.t1,
      ];
      int frame = 0;
      int dropped = 0;
      final int drops = 7 * tiers.length;
      while (frame < 60 * 16) {
        if (frame % 24 == 0 && dropped < drops) {
          final BallTier tier = tiers[dropped % tiers.length];
          final double r = AppDimens.ballRadii[tier.index];
          final double y = AppDimens.ballSpawnY;
          final (double l, double rr) = game.jar.spanAt(y + r);
          final double x = l + (rr - l) * ((dropped ~/ tiers.length) + 0.5) / 7;
          final BallBody b = BallBody(
            tier: tier,
            initialPosition: Vector2(game.jar.clampX(x, y + r, r), y),
            onMerge: (_, __) {},
          );
          balls.add(b);
          game.world.add(b);
          dropped++;
        }
        game.update(1 / 60);
        await Future<void>.delayed(Duration.zero);
        frame++;
      }

      final List<Vector2> wall = game.jar.wallWithMargin(300);
      final List<Vector2> poly = <Vector2>[...wall]; // замкнётся по верху
      final List<String> problems = <String>[];
      for (final BallBody b in balls) {
        final Vector2 p = b.body.position;
        final double r = b.radius;
        final double speed = b.body.linearVelocity.length;
        if (speed > 40) {
          problems.add(
              '${b.tier.name} at ${p.x.round()},${p.y.round()} still moving $speed');
        }
        if (!_inside(p, poly)) {
          problems.add(
              '${b.tier.name} centre outside at ${p.x.round()},${p.y.round()}');
          continue;
        }
        // Круг не должен пересекать стенку глубже допуска Box2D (~2.4 ед.
        // спекулятивной дистанции + люфт).
        final double d = _distToPolyline(p, wall);
        if (d < r - 3) {
          problems.add(
              '${b.tier.name} sunk ${(r - d).toStringAsFixed(1)} into wall at ${p.x.round()},${p.y.round()}');
        }
        for (final List<Vector2> extra in game.jar.extras) {
          final double de = _distToPolyline(p, extra, closed: true);
          if (_inside(p, extra) || de < r - 3) {
            problems.add(
                '${b.tier.name} inside extra at ${p.x.round()},${p.y.round()}');
          }
        }
      }
      game.world.physicsWorld.destroy();
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }
}
