import 'package:equatable/equatable.dart';

import '../enums/ball_tier.dart';

/// Шар в сохранённой партии. Координаты — мировые единицы (ширина мира 360);
/// [bottomOffset] — расстояние от центра до дна: высота мира зависит от
/// экрана, а расстояние до дна — нет.
class BallSnapshot extends Equatable {
  final BallTier tier;
  final double x;
  final double bottomOffset;
  final double angle;
  final double vx;
  final double vy;

  const BallSnapshot({
    required this.tier,
    required this.x,
    required this.bottomOffset,
    required this.angle,
    required this.vx,
    required this.vy,
  });

  @override
  List<Object?> get props => <Object?>[tier, x, bottomOffset, angle, vx, vy];
}

/// Сохранённая партия — восстанавливается из меню кнопкой «Продолжить».
class GameSnapshot extends Equatable {
  final int score;
  final BallTier current;
  final BallTier next;

  /// Слияний за партию и самый крупный фрукт партии (для статистики).
  final int merges;
  final BallTier? bestTier;

  /// Оставшиеся заряды бонусов «Встряхнуть», «Бомбочка» и «Увеличить».
  final int shakes;
  final int bombs;
  final int upgrades;
  final List<BallSnapshot> balls;
  final DateTime savedAt;

  const GameSnapshot({
    required this.score,
    required this.current,
    required this.next,
    required this.merges,
    required this.bestTier,
    required this.shakes,
    required this.bombs,
    required this.upgrades,
    required this.balls,
    required this.savedAt,
  });

  @override
  List<Object?> get props => <Object?>[
        score,
        current,
        next,
        merges,
        bestTier,
        shakes,
        bombs,
        upgrades,
        balls,
        savedAt,
      ];
}
