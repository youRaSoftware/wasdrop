part of 'game_cubit.dart';

enum GameStatus { playing, paused, gameOver }

/// Бонусы под стаканом. Кнопка взводит бонус ([GameState.armed]): встряска
/// ждёт тряски телефона, бомбочка и увеличение — тапа по фрукту.
enum Bonus { shake, bomb, upgrade }

class GameState extends Equatable {
  final int score;
  final int bestScore;
  final GameStatus status;
  final BallTier current;
  final BallTier next;
  final bool isNewRecord;

  /// Слияний за текущую партию.
  final int merges;

  /// Самый крупный фрукт, полученный за партию (null — ещё не было).
  final BallTier? bestTier;

  /// Оставшиеся заряды бонусов «Встряхнуть», «Бомбочка» и «Увеличить».
  final int shakes;
  final int bombs;
  final int upgrades;

  /// Взведённый бонус (null — обычная игра).
  final Bonus? armed;

  const GameState({
    required this.score,
    required this.bestScore,
    required this.status,
    required this.current,
    required this.next,
    this.isNewRecord = false,
    this.merges = 0,
    this.bestTier,
    this.shakes = GameRules.shakesPerGame,
    this.bombs = GameRules.bombsPerGame,
    this.upgrades = GameRules.upgradesPerGame,
    this.armed,
  });

  int charges(Bonus bonus) => switch (bonus) {
        Bonus.shake => shakes,
        Bonus.bomb => bombs,
        Bonus.upgrade => upgrades,
      };

  /// [bestTier] сбрасывается в null, только если передать `bestTier: null`
  /// явно через [resetBestTier]; [armed] снимается через [disarm].
  GameState copyWith({
    int? score,
    int? bestScore,
    GameStatus? status,
    BallTier? current,
    BallTier? next,
    bool? isNewRecord,
    int? merges,
    BallTier? bestTier,
    bool resetBestTier = false,
    int? shakes,
    int? bombs,
    int? upgrades,
    Bonus? armed,
    bool disarm = false,
  }) {
    return GameState(
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      status: status ?? this.status,
      current: current ?? this.current,
      next: next ?? this.next,
      isNewRecord: isNewRecord ?? this.isNewRecord,
      merges: merges ?? this.merges,
      bestTier: resetBestTier ? null : (bestTier ?? this.bestTier),
      shakes: shakes ?? this.shakes,
      bombs: bombs ?? this.bombs,
      upgrades: upgrades ?? this.upgrades,
      armed: disarm ? null : (armed ?? this.armed),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        score,
        bestScore,
        status,
        current,
        next,
        isNewRecord,
        merges,
        bestTier,
        shakes,
        bombs,
        upgrades,
        armed,
      ];
}
