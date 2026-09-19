part of 'game_cubit.dart';

enum GameStatus { playing, paused, gameOver }

class GameState extends Equatable {
  final GameMode mode;

  /// Осталось секунд («На время»); null в других режимах.
  final int? secondsLeft;

  final int score;
  final int bestScore;
  final GameStatus status;
  final BallTier current;
  final BallTier next;

  /// Особые фрукты в окошках («Сад чудес»); null — обычный фрукт [current]/[next].
  final SpecialKind? currentSpecial;
  final SpecialKind? nextSpecial;
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

  /// Оставшиеся продолжения после проигрыша (за ролик / премиуму даром).
  final int continues;

  /// Оставшиеся пополнения зарядов каждого бонуса (за ролик / премиуму).
  final int shakeRefills;
  final int bombRefills;
  final int upgradeRefills;

  /// Текущие заказы (три; выполненный сразу заменяется новым).
  final List<Mission> missions;

  /// Последний выполненный заказ и порядковый номер выполнения за партию
  /// (форма показывает всплывашку, когда номер меняется).
  final Mission? completedMission;
  final int completedCount;

  /// Звёзд заработано за партию.
  final int starsEarned;

  /// Открыт экран заказов (партия на паузе).
  final bool missionsOpen;

  /// Показан онбординг «как играть» (первый запуск; движок стоит).
  final bool onboardingOpen;

  /// Показана справка «Сада чудес» (первый вход в режим; движок стоит).
  final bool gardenIntroOpen;

  /// Идёт показ ролика (кнопки рекламы заблокированы, движок на паузе).
  final bool adBusy;

  /// Последний ролик не загрузился — показать подсказку.
  final bool adUnavailable;

  const GameState({
    this.mode = GameMode.classic,
    this.secondsLeft,
    required this.score,
    required this.bestScore,
    required this.status,
    required this.current,
    required this.next,
    this.currentSpecial,
    this.nextSpecial,
    this.isNewRecord = false,
    this.merges = 0,
    this.bestTier,
    this.shakes = GameRules.shakesPerGame,
    this.bombs = GameRules.bombsPerGame,
    this.upgrades = GameRules.upgradesPerGame,
    this.armed,
    this.continues = GameRules.continuesPerGame,
    this.shakeRefills = GameRules.refillsPerBonus,
    this.bombRefills = GameRules.refillsPerBonus,
    this.upgradeRefills = GameRules.refillsPerBonus,
    this.missions = const <Mission>[],
    this.completedMission,
    this.completedCount = 0,
    this.starsEarned = 0,
    this.missionsOpen = false,
    this.onboardingOpen = false,
    this.gardenIntroOpen = false,
    this.adBusy = false,
    this.adUnavailable = false,
  });

  int charges(Bonus bonus) => switch (bonus) {
        Bonus.shake => shakes,
        Bonus.bomb => bombs,
        Bonus.upgrade => upgrades,
      };

  int refills(Bonus bonus) => switch (bonus) {
        Bonus.shake => shakeRefills,
        Bonus.bomb => bombRefills,
        Bonus.upgrade => upgradeRefills,
      };

  /// Полные заряды бонуса (после пополнения).
  static int fullCharges(Bonus bonus) => switch (bonus) {
        Bonus.shake => GameRules.shakesPerGame,
        Bonus.bomb => GameRules.bombsPerGame,
        Bonus.upgrade => GameRules.upgradesPerGame,
      };

  /// Продолжение после проигрыша — только в классике (в «На время» и
  /// ежедневном вызове зачёт честный).
  bool get canContinue => mode.allowsContinue && continues > 0;

  /// Кнопка бонуса без зарядов предлагает пополнение — только с
  /// монетизацией (за ролик / премиуму); в 1.0 заряды 3 / 1 / 1 на партию
  /// без пополнения (решение 2026-09-14).
  bool canRefill(Bonus bonus) =>
      AppConfig.monetizationEnabled &&
      status == GameStatus.playing &&
      charges(bonus) == 0 &&
      refills(bonus) > 0;

  /// [bestTier] сбрасывается в null, только если передать `bestTier: null`
  /// явно через [resetBestTier]; [armed] снимается через [disarm]; особые
  /// фрукты очереди задаются парой [queueSpecials] (null — оставить).
  GameState copyWith({
    int? secondsLeft,
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
    int? continues,
    int? shakeRefills,
    int? bombRefills,
    int? upgradeRefills,
    List<Mission>? missions,
    Mission? completedMission,
    int? completedCount,
    int? starsEarned,
    bool? missionsOpen,
    bool? onboardingOpen,
    bool? gardenIntroOpen,
    (SpecialKind?, SpecialKind?)? queueSpecials,
    bool? adBusy,
    bool? adUnavailable,
  }) {
    return GameState(
      mode: mode,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      status: status ?? this.status,
      current: current ?? this.current,
      next: next ?? this.next,
      currentSpecial: queueSpecials == null ? currentSpecial : queueSpecials.$1,
      nextSpecial: queueSpecials == null ? nextSpecial : queueSpecials.$2,
      isNewRecord: isNewRecord ?? this.isNewRecord,
      merges: merges ?? this.merges,
      bestTier: resetBestTier ? null : (bestTier ?? this.bestTier),
      shakes: shakes ?? this.shakes,
      bombs: bombs ?? this.bombs,
      upgrades: upgrades ?? this.upgrades,
      armed: disarm ? null : (armed ?? this.armed),
      continues: continues ?? this.continues,
      shakeRefills: shakeRefills ?? this.shakeRefills,
      bombRefills: bombRefills ?? this.bombRefills,
      upgradeRefills: upgradeRefills ?? this.upgradeRefills,
      missions: missions ?? this.missions,
      completedMission: completedMission ?? this.completedMission,
      completedCount: completedCount ?? this.completedCount,
      starsEarned: starsEarned ?? this.starsEarned,
      missionsOpen: missionsOpen ?? this.missionsOpen,
      onboardingOpen: onboardingOpen ?? this.onboardingOpen,
      gardenIntroOpen: gardenIntroOpen ?? this.gardenIntroOpen,
      adBusy: adBusy ?? this.adBusy,
      adUnavailable: adUnavailable ?? this.adUnavailable,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        mode,
        secondsLeft,
        score,
        bestScore,
        status,
        current,
        next,
        currentSpecial,
        nextSpecial,
        isNewRecord,
        merges,
        bestTier,
        shakes,
        bombs,
        upgrades,
        armed,
        continues,
        shakeRefills,
        bombRefills,
        upgradeRefills,
        adBusy,
        adUnavailable,
        missions,
        completedMission,
        completedCount,
        starsEarned,
        missionsOpen,
        onboardingOpen,
        gardenIntroOpen,
      ];
}
