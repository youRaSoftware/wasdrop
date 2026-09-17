import '../enums/ball_tier.dart';

/// Достижения Game Center. [id] — идентификатор в App Store Connect
/// (`com.wasdrop.<name>`); список и условия дублируются в
/// `.claude/my_docs/GAME_CENTER_ASC.md` для заведения в консоли.
enum GameAchievement {
  /// Первый лимон / киви / виноград / дыня / арбуз, полученный слиянием.
  lemon('com.wasdrop.fruit.lemon', tier: BallTier.t4),
  kiwi('com.wasdrop.fruit.kiwi', tier: BallTier.t6),
  grape('com.wasdrop.fruit.grape', tier: BallTier.t8),
  melon('com.wasdrop.fruit.melon', tier: BallTier.t10),
  watermelon('com.wasdrop.fruit.watermelon', tier: BallTier.t11),

  /// Очки за одну партию.
  score1k('com.wasdrop.score.1k', score: 1000),
  score10k('com.wasdrop.score.10k', score: 10000),

  /// Сыгранных партий всего.
  games10('com.wasdrop.games.10', games: 10),
  games100('com.wasdrop.games.100', games: 100),

  /// Выполненных заказов всего.
  missions25('com.wasdrop.missions.25', missions: 25);

  final String id;
  final BallTier? tier;
  final int? score;
  final int? games;
  final int? missions;

  const GameAchievement(
    this.id, {
    this.tier,
    this.score,
    this.games,
    this.missions,
  });

  /// Достижения за фрукт [produced] (слияние или увеличение).
  static Iterable<GameAchievement> forFruit(BallTier produced) =>
      values.where((GameAchievement a) => a.tier == produced);

  static Iterable<GameAchievement> forScore(int score) =>
      values.where((GameAchievement a) => a.score != null && score >= a.score!);

  static Iterable<GameAchievement> forGames(int games) =>
      values.where((GameAchievement a) => a.games != null && games >= a.games!);

  static Iterable<GameAchievement> forMissions(int missions) => values.where(
      (GameAchievement a) => a.missions != null && missions >= a.missions!);
}
