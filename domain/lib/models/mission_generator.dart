import 'dart:math';

import '../enums/ball_tier.dart';
import '../enums/bonus.dart';
import 'mission.dart';

/// Раздаёт заказы по уровню игрока ([level] — сколько заказов выполнено за
/// всё время): первые заказы простые (мандарин, 300 очков, серия 3), дальше
/// — крупнее фрукты, длиннее серии, экономия и бомбочка. Типы трёх текущих
/// заказов не повторяются; [random] с seed даёт одинаковые заказы
/// (ежедневный вызов).
///
/// Награда — всегда звезда; очков заказы не дают (счёт только от слияний,
/// иначе лидерборды и достижения за очки обесцениваются), а заряд бонуса —
/// только за трудные заказы (серия ≥ 5, сбор ≥ 4, экономия, бомбочка по
/// цели, ≥ 10 чистых бросков), с потолком `GameRules.max*` в кубите.
class MissionGenerator {
  final Random random;

  /// «Сад чудес»: в пул добавляются заказы на особые фрукты.
  final bool garden;

  MissionGenerator(this.random, {this.garden = false});

  /// Сколько заказов висит одновременно.
  static const int slots = 3;

  /// Стартовый набор: [slots] заказов разных типов.
  List<Mission> initial(int level, {int firstId = 1}) {
    final List<Mission> out = <Mission>[];
    for (int i = 0; i < slots; i++) {
      out.add(next(level, existing: out, id: firstId + i));
    }
    return out;
  }

  /// Новый заказ на замену: тип не совпадает с [existing], фрукт-цель —
  /// не тот же, что в других заказах на фрукт.
  Mission next(int level, {required List<Mission> existing, required int id}) {
    final Set<MissionType> usedTypes =
        existing.map((Mission m) => m.type).toSet();
    final Set<BallTier?> usedTiers =
        existing.map((Mission m) => m.tier).toSet();
    final List<MissionType> pool = _poolFor(level)
        .where((MissionType t) => !usedTypes.contains(t))
        .toList();
    final MissionType type = pool[random.nextInt(pool.length)];
    return _build(type, level, id, usedTiers);
  }

  List<MissionType> _poolFor(int level) {
    final List<MissionType> base = _basePool(level);
    if (!garden) return base;
    return <MissionType>[
      ...base,
      MissionType.mergeRainbow,
      MissionType.popBubbles,
    ];
  }

  List<MissionType> _basePool(int level) {
    if (level < 3) {
      return const <MissionType>[
        MissionType.getFruit,
        MissionType.score,
        MissionType.mergeStreak,
        MissionType.collectFruits,
      ];
    }
    if (level < 9) {
      return const <MissionType>[
        MissionType.getFruit,
        MissionType.collectFruits,
        MissionType.mergeStreak,
        MissionType.combo,
        MissionType.score,
        MissionType.clean,
      ];
    }
    return const <MissionType>[
      MissionType.getFruit,
      MissionType.collectFruits,
      MissionType.mergeStreak,
      MissionType.combo,
      MissionType.economy,
      MissionType.bonusBomb,
      MissionType.score,
      MissionType.clean,
    ];
  }

  /// Ступень сложности 0…3 по уровню.
  int _tierStep(int level) => level < 3
      ? 0
      : level < 9
          ? 1
          : level < 20
              ? 2
              : 3;

  BallTier _pickTier(List<BallTier> candidates, Set<BallTier?> used) {
    final List<BallTier> free =
        candidates.where((BallTier t) => !used.contains(t)).toList();
    final List<BallTier> from = free.isEmpty ? candidates : free;
    return from[random.nextInt(from.length)];
  }

  int _range(int lo, int hi) => lo + random.nextInt(hi - lo + 1);

  Bonus _anyBonus() => Bonus.values[random.nextInt(Bonus.values.length)];

  Mission _build(MissionType type, int level, int id, Set<BallTier?> used) {
    final int step = _tierStep(level);
    switch (type) {
      case MissionType.getFruit:
        final BallTier tier = _pickTier(
          switch (step) {
            0 => const <BallTier>[BallTier.t3, BallTier.t4],
            1 => const <BallTier>[BallTier.t4, BallTier.t5, BallTier.t6],
            2 => const <BallTier>[BallTier.t6, BallTier.t7, BallTier.t8],
            _ => const <BallTier>[BallTier.t8, BallTier.t9, BallTier.t10],
          },
          used,
        );
        return Mission(
          id: id,
          type: type,
          tier: tier,
          target: 1,
          reward: MissionReward(bonus: step >= 3 ? _anyBonus() : null),
        );
      case MissionType.collectFruits:
        final BallTier tier = _pickTier(
          switch (step) {
            0 => const <BallTier>[BallTier.t2, BallTier.t3],
            1 => const <BallTier>[BallTier.t3, BallTier.t4],
            2 => const <BallTier>[BallTier.t4, BallTier.t5],
            _ => const <BallTier>[BallTier.t5, BallTier.t6, BallTier.t7],
          },
          used,
        );
        final int n = _range(3, 3 + step);
        return Mission(
          id: id,
          type: type,
          tier: tier,
          target: n,
          reward: MissionReward(bonus: n >= 4 ? _anyBonus() : null),
        );
      case MissionType.mergeStreak:
        final int streak = _range(3 + step, 4 + 2 * step);
        return Mission(
          id: id,
          type: type,
          target: streak,
          reward: MissionReward(bonus: streak >= 5 ? Bonus.shake : null),
        );
      case MissionType.combo:
        return Mission(
          id: id,
          type: type,
          target: 1,
          reward: const MissionReward(),
        );
      case MissionType.economy:
        final BallTier tier = _pickTier(
          step < 3
              ? const <BallTier>[BallTier.t5, BallTier.t6]
              : const <BallTier>[BallTier.t7, BallTier.t8],
          used,
        );
        // Бросков хватает на «честную» сборку с запасом ≈ 30 %.
        final int drops = (1 << (tier.number - 1)) + tier.number * 3;
        return Mission(
          id: id,
          type: type,
          tier: tier,
          target: drops,
          reward: const MissionReward(bonus: Bonus.bomb),
        );
      case MissionType.bonusBomb:
        final BallTier tier = _pickTier(
          const <BallTier>[BallTier.t3, BallTier.t4, BallTier.t5],
          used,
        );
        return Mission(
          id: id,
          type: type,
          tier: tier,
          target: 1,
          reward: const MissionReward(bonus: Bonus.bomb),
        );
      case MissionType.score:
        return Mission(
          id: id,
          type: type,
          target: switch (step) {
            0 => _range(3, 6) * 100,
            1 => _range(8, 15) * 100,
            2 => _range(20, 40) * 100,
            _ => _range(50, 90) * 100,
          },
          reward: MissionReward(bonus: step >= 2 ? Bonus.upgrade : null),
        );
      case MissionType.mergeRainbow:
        return Mission(
          id: id,
          type: type,
          target: _range(1, 1 + step ~/ 2),
          reward: MissionReward(bonus: step >= 2 ? Bonus.bomb : null),
        );
      case MissionType.popBubbles:
        return Mission(
          id: id,
          type: type,
          target: _range(2, 3 + step ~/ 2),
          reward: const MissionReward(),
        );
      case MissionType.clean:
        final int clean = _range(6 + 2 * step, 10 + 3 * step);
        return Mission(
          id: id,
          type: type,
          target: clean,
          reward: MissionReward(bonus: clean >= 10 ? Bonus.shake : null),
        );
    }
  }
}
