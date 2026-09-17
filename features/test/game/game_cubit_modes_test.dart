// Режимы: «На время» — таймер и проигрыш «время вышло», рекорд режима
// отдельно от классики, без продолжений и снимка; ежедневный вызов —
// одинаковая очередь и заказы по seed даты, один зачёт в день.
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:features/game/cubit/game_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _StatsRepository implements StatsRepository {
  GameStatsModel stats = const GameStatsModel.empty();
  @override
  Future<GameStatsModel> getStats() async => stats;
  @override
  Future<void> saveStats(GameStatsModel value) async => stats = value;
}

class _GameRepository implements GameRepository {
  GameSnapshot? snapshot;
  @override
  Future<GameSnapshot?> load() async => snapshot;
  @override
  Future<void> save(GameSnapshot value) async => snapshot = value;
  @override
  Future<void> clear() async => snapshot = null;
}

class _SettingsRepository implements SettingsRepository {
  @override
  Future<SettingsModel> getSettings() async => const SettingsModel.empty();
  @override
  Future<void> saveSettings(SettingsModel settings) async {}
}

class _PremiumRepository implements PremiumRepository {
  @override
  Future<bool> isPremium() async => false;
  @override
  Future<void> setPremium(bool value) async {}
}

class _ProgressRepository implements ProgressRepository {
  ProgressModel progress = const ProgressModel.empty();
  @override
  Future<ProgressModel> getProgress() async => progress;
  @override
  Future<void> saveProgress(ProgressModel value) async => progress = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  late _StatsRepository stats;
  late _GameRepository games;
  late _ProgressRepository progress;

  GameCubit make(GameMode mode, {DateTime? now}) {
    final SettingsService settings = SettingsService(_SettingsRepository());
    final AudioService audio = AudioService(settings);
    final PremiumService premium = PremiumService(_PremiumRepository());
    return GameCubit(
      statsRepository: stats,
      gameRepository: games,
      audio: audio,
      premium: premium,
      ads: AdsService(AppConfig.fromFlavor(Flavor.dev), premium, audio),
      progressRepository: progress,
      gameCenter: GameCenterService(),
      mode: mode,
      now: now,
    );
  }

  setUp(() {
    stats = _StatsRepository();
    games = _GameRepository();
    progress = _ProgressRepository();
  });

  test('на время: таймер, время вышло → проигрыш, рекорд режима', () async {
    stats.stats = const GameStatsModel(bestScore: 5000, gamesPlayed: 3);
    final GameCubit cubit = make(GameMode.timed);
    await pumpEventQueue();
    // Первый запуск: онбординг открыт, таймер стоит.
    expect(cubit.state.onboardingOpen, isTrue);
    cubit.tick();
    expect(cubit.state.secondsLeft, GameRules.timedSeconds);
    await cubit.finishOnboarding();
    expect(progress.progress.onboardingDone, isTrue);
    expect(cubit.state.secondsLeft, GameRules.timedSeconds);
    // Рекорд в HUD — режима, а не классики.
    expect(cubit.state.bestScore, 0);
    cubit.tick();
    expect(cubit.state.secondsLeft, GameRules.timedSeconds - 1);
    cubit.pause();
    cubit.tick();
    expect(cubit.state.secondsLeft, GameRules.timedSeconds - 1,
        reason: 'на паузе таймер стоит');
    cubit.resume();
    cubit.onMerge(BallTier.t5); // 32 очка
    for (int i = 0; i < GameRules.timedSeconds; i++) {
      cubit.tick();
    }
    await pumpEventQueue();
    expect(cubit.state.secondsLeft, 0);
    expect(cubit.state.status, GameStatus.gameOver);
    expect(cubit.state.isNewRecord, isTrue);
    expect(cubit.state.canContinue, isFalse);
    expect(stats.stats.bestTimed, 32);
    expect(stats.stats.bestScore, 5000, reason: 'рекорд классики не тронут');
    expect(stats.stats.gamesPlayed, 4);
    // Снимок в этом режиме не пишется.
    await cubit.saveSnapshot(const <BallSnapshot>[], jarId: 'classic');
    expect(games.snapshot, isNull);
    await cubit.close();
  });

  test('ежедневный: одинаковая очередь и заказы по дате, один зачёт в день',
      () async {
    final DateTime day = DateTime.utc(2026, 9, 17, 10);
    final GameCubit a = make(GameMode.daily, now: day);
    final GameCubit b = make(GameMode.daily, now: day);
    await pumpEventQueue();
    expect(a.state.missions, b.state.missions);
    final List<BallTier> qa = <BallTier>[];
    final List<BallTier> qb = <BallTier>[];
    for (int i = 0; i < 12; i++) {
      qa.add(a.state.current);
      qb.add(b.state.current);
      a.onDropped();
      b.onDropped();
    }
    expect(qa, qb);
    final GameCubit other =
        make(GameMode.daily, now: DateTime.utc(2026, 9, 18, 10));
    await pumpEventQueue();
    expect(other.state.missions, isNot(a.state.missions));
    await other.close();
    await b.close();

    expect(progress.progress.dailyPlayed(dailySeed(day)), isFalse);
    a.onMerge(BallTier.t3); // 8 очков (+ награда заказа, если он на лимон)
    await a.gameOver();
    expect(progress.progress.dailyPlayed(dailySeed(day)), isTrue);
    expect(progress.progress.dailyScore, a.state.score);
    expect(stats.stats.bestDaily, a.state.score);
    expect(a.state.canContinue, isFalse);
    await a.close();
  });

  test('ежедневный: выход в меню тоже засчитывает день', () async {
    final DateTime day = DateTime.utc(2026, 9, 17, 10);
    final GameCubit cubit = make(GameMode.daily, now: day);
    await pumpEventQueue();
    cubit.onMerge(BallTier.t1);
    await cubit.close();
    expect(progress.progress.dailyPlayed(dailySeed(day)), isTrue);
    expect(progress.progress.dailyScore, cubit.state.score);
  });

  test('онбординг: только при первом запуске новой партии', () async {
    final GameCubit first = make(GameMode.classic);
    await pumpEventQueue();
    expect(first.state.onboardingOpen, isTrue);
    await first.finishOnboarding();
    expect(first.state.onboardingOpen, isFalse);
    await first.close();

    final GameCubit second = make(GameMode.classic);
    await pumpEventQueue();
    expect(second.state.onboardingOpen, isFalse);
    await second.close();
  });
}
