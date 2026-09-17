import 'package:equatable/equatable.dart';

/// Прогресс игрока вне партии (Hive-бокс `progressBox`): звёзды за заказы
/// (валюта открытия стаканов), счётчики заказов, флаг онбординга.
class ProgressModel extends Equatable {
  /// Звёзды за выполненные заказы — открывают стаканы (`JarShape.starsToUnlock`).
  final int stars;

  /// Выполнено заказов за всё время.
  final int missionsDone;

  /// Первый запуск пройден (подсказка «как играть» показана).
  final bool onboardingDone;

  /// Ежедневный вызов: seed сыгранного дня (`dailySeed`, 0 — не играли)
  /// и счёт этого дня. Рекорд режима — в статистике.
  final int dailyPlayedSeed;
  final int dailyScore;

  const ProgressModel({
    required this.stars,
    required this.missionsDone,
    required this.onboardingDone,
    this.dailyPlayedSeed = 0,
    this.dailyScore = 0,
  });

  const ProgressModel.empty()
      : this(stars: 0, missionsDone: 0, onboardingDone: false);

  ProgressModel copyWith({
    int? stars,
    int? missionsDone,
    bool? onboardingDone,
    int? dailyPlayedSeed,
    int? dailyScore,
  }) {
    return ProgressModel(
      stars: stars ?? this.stars,
      missionsDone: missionsDone ?? this.missionsDone,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      dailyPlayedSeed: dailyPlayedSeed ?? this.dailyPlayedSeed,
      dailyScore: dailyScore ?? this.dailyScore,
    );
  }

  /// Сегодняшний вызов уже сыгран.
  bool dailyPlayed(int seed) => dailyPlayedSeed == seed;

  @override
  List<Object?> get props =>
      <Object?>[stars, missionsDone, onboardingDone, dailyPlayedSeed, dailyScore];
}
