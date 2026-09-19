import 'package:equatable/equatable.dart';

import '../enums/ball_tier.dart';
import '../enums/bonus.dart';

/// Типы заказов (`Mission.type`). Текст — ключи `missions.<type>`.
enum MissionType {
  /// Получить фрукт [Mission.tier] слиянием (один раз).
  getFruit,

  /// Получить [Mission.target] фруктов [Mission.tier] слиянием.
  collectFruits,

  /// [Mission.target] слияний подряд без «пустого» броска (бросок, после
  /// которого до следующего броска не было ни одного слияния, рвёт серию).
  mergeStreak,

  /// Два слияния одним броском.
  combo,

  /// Получить [Mission.tier] не позже чем за [Mission.target] бросков с
  /// момента выдачи заказа; перебор — заказ заменяется.
  economy,

  /// Взорвать бомбочкой фрукт [Mission.tier].
  bonusBomb,

  /// Набрать [Mission.target] очков за партию.
  score,

  /// [Mission.target] бросков подряд, пока ни один фрукт не касается линии.
  clean,

  /// «Сад чудес»: слить Радужку [Mission.target] раз.
  mergeRainbow,

  /// «Сад чудес»: унести пузыриком [Mission.target] фруктов.
  popBubbles,
}

/// Награда за заказ: заряд бонуса и/или очки; звезда — всегда одна.
class MissionReward extends Equatable {
  final Bonus? bonus;
  final int points;

  const MissionReward({this.bonus, this.points = 0});

  static const int stars = 1;

  @override
  List<Object?> get props => <Object?>[bonus, points];
}

/// Заказ в партии: цель с прогрессом. Три заказа висят одновременно;
/// выполненный заменяется новым (`MissionGenerator`).
class Mission extends Equatable {
  /// Уникален в пределах партии (для анимации замены карточки).
  final int id;
  final MissionType type;

  /// Фрукт-цель (getFruit, collectFruits, economy, bonusBomb).
  final BallTier? tier;

  /// Цель по счётчику (collectFruits, mergeStreak, economy, score, clean);
  /// у getFruit, combo и bonusBomb — 1.
  final int target;

  /// Счётчик к цели; у economy — потраченные броски (полоска убывает).
  final int progress;
  final MissionReward reward;

  /// Выполнен (ставит трекер; у economy не следует из [progress]).
  final bool done;

  const Mission({
    required this.id,
    required this.type,
    required this.target,
    required this.reward,
    this.tier,
    this.progress = 0,
    this.done = false,
  });

  bool get isDone => done;

  /// Сколько осталось до цели (economy — бросков в запасе).
  int get remaining => (target - progress).clamp(0, target);

  /// Заполнение полоски 0…1: у economy — остаток бросков.
  double get fraction => target == 0
      ? 1
      : (type == MissionType.economy ? remaining / target : progress / target)
          .clamp(0.0, 1.0);

  Mission copyWith({int? progress, bool? done}) => Mission(
        id: id,
        type: type,
        tier: tier,
        target: target,
        progress: progress ?? this.progress,
        reward: reward,
        done: done ?? this.done,
      );

  @override
  List<Object?> get props =>
      <Object?>[id, type, tier, target, progress, reward, done];
}
