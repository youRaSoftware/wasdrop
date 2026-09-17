import 'package:equatable/equatable.dart';

part 'jar_shape_data.dart';

/// Точка контура стакана в нормированных координатах внутренней области:
/// x 0…1 слева направо, y 0…1 сверху вниз (1 — дно).
class JarPoint extends Equatable {
  final double x;
  final double y;

  const JarPoint(this.x, this.y);

  @override
  List<Object?> get props => <Object?>[x, y];
}

/// Форма стакана. Контур [wall] — внутренняя поверхность стенки от верха
/// левой стенки вниз по дну до верха правой стенки (открытый сверху);
/// [extras] — замкнутые препятствия внутри (полка, платформа). Мировые
/// координаты получаются умножением на ширину и высоту мира, экранные —
/// на размер холста: формы слегка растягиваются по высоте вместе со
/// стаканом (пропорция 1.5–1.7).
///
/// Контуры сгенерированы из SVG Claude Design (`.claude/my_docs/jars/`)
/// скриптом `script/svg_jar_to_dart.py`.
class JarShape extends Equatable {
  final String id;

  /// Сколько звёзд заказов нужно, чтобы открыть (0 — открыт сразу).
  final int starsToUnlock;

  /// Показывается в списке, но недоступен («скоро»).
  final bool comingSoon;

  final List<JarPoint> wall;
  final List<List<JarPoint>> extras;

  /// Ось качающейся платформы («Качели»), null — платформа неподвижна.
  final JarPoint? pivot;

  const JarShape({
    required this.id,
    required this.wall,
    this.starsToUnlock = 0,
    this.comingSoon = false,
    this.extras = const <List<JarPoint>>[],
    this.pivot,
  });

  /// Прямоугольник без скруглений (сплеш и меню: стенки — края экрана).
  static const JarShape rectangle = JarShape(
    id: 'rectangle',
    wall: <JarPoint>[
      JarPoint(0, 0),
      JarPoint(0, 1),
      JarPoint(1, 1),
      JarPoint(1, 0),
    ],
  );

  bool get isLockedByStars => starsToUnlock > 0;

  /// Доступен при [stars] звёздах.
  bool isUnlocked(int stars) => !comingSoon && stars >= starsToUnlock;

  /// Левая и правая внутренние границы на высоте [ny] (0…1): пересечение
  /// горизонтали с контуром; выше контура (или вне его) — вся ширина.
  (double, double) spanAt(double ny) {
    double left = double.infinity;
    double right = double.negativeInfinity;
    for (int i = 0; i < wall.length - 1; i++) {
      final JarPoint a = wall[i];
      final JarPoint b = wall[i + 1];
      final double lo = a.y < b.y ? a.y : b.y;
      final double hi = a.y < b.y ? b.y : a.y;
      if (ny < lo || ny > hi) continue;
      final double x = (b.y - a.y).abs() < 1e-9
          ? (a.x < b.x ? a.x : b.x)
          : a.x + (b.x - a.x) * (ny - a.y) / (b.y - a.y);
      final double x2 = (b.y - a.y).abs() < 1e-9 ? (a.x < b.x ? b.x : a.x) : x;
      if (x < left) left = x;
      if (x2 > right) right = x2;
    }
    if (left == double.infinity || right <= left) return (0, 1);
    return (left, right);
  }

  @override
  List<Object?> get props =>
      <Object?>[id, starsToUnlock, comingSoon, wall, extras, pivot];
}

/// Каталог стаканов в порядке показа; открытие — за звёзды заказов.
abstract final class JarShapes {
  static const String defaultId = 'classic';

  static List<JarShape> get all => _all;

  static JarShape byId(String? id) => _all.firstWhere(
        (JarShape j) => j.id == id,
        orElse: () => _all.first,
      );
}
