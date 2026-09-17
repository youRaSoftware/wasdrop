import 'dart:math';

import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MissionGenerator', () {
    test('три стартовых заказа разных типов, на старте — простые', () {
      for (int seed = 0; seed < 50; seed++) {
        final List<Mission> m = MissionGenerator(Random(seed)).initial(0);
        expect(m.map((Mission x) => x.type).toSet().length, 3);
        expect(m.map((Mission x) => x.id).toSet().length, 3);
        for (final Mission x in m) {
          expect(x.type, isNot(MissionType.economy));
          expect(x.type, isNot(MissionType.bonusBomb));
          if (x.type == MissionType.getFruit) {
            expect(x.tier!.index, lessThanOrEqualTo(BallTier.t4.index));
          }
        }
      }
    });

    test('один seed — одинаковые заказы (ежедневный вызов)', () {
      final List<Mission> a = MissionGenerator(Random(20260917)).initial(5);
      final List<Mission> b = MissionGenerator(Random(20260917)).initial(5);
      expect(a, b);
    });

    test('замена не повторяет тип и фрукт остальных', () {
      final MissionGenerator g = MissionGenerator(Random(3));
      final List<Mission> m = g.initial(12);
      for (int i = 0; i < 100; i++) {
        final Mission n = g.next(12, existing: m.sublist(1), id: 100 + i);
        expect(
            m.sublist(1).map((Mission x) => x.type), isNot(contains(n.type)));
      }
    });
  });

  group('MissionTracker', () {
    Mission of(MissionType t, {BallTier? tier, int target = 1, int id = 1}) =>
        Mission(
            id: id,
            type: t,
            tier: tier,
            target: target,
            reward: const MissionReward());

    test('getFruit / collectFruits по слиянию', () {
      final MissionTracker tr = MissionTracker();
      List<Mission> m = <Mission>[
        of(MissionType.getFruit, tier: BallTier.t3, id: 1),
        of(MissionType.collectFruits, tier: BallTier.t2, target: 2, id: 2),
      ];
      MissionStep s =
          tr.apply(m, const MergeEvent(produced: BallTier.t2, score: 2));
      expect(s.completed, isEmpty);
      expect(s.missions[1].progress, 1);
      m = s.missions;
      s = tr.apply(m, const MergeEvent(produced: BallTier.t3, score: 6));
      expect(s.completed.single.id, 1);
      m = s.missions;
      s = tr.apply(m, const MergeEvent(produced: BallTier.t2, score: 8));
      expect(s.completed.single.id, 2);
      expect(s.missions, isEmpty);
    });

    test('серия рвётся пустым броском, комбо — два слияния за бросок', () {
      final MissionTracker tr = MissionTracker();
      List<Mission> m = <Mission>[
        of(MissionType.mergeStreak, target: 3, id: 1),
        of(MissionType.combo, id: 2),
      ];
      m = tr.apply(m, const DropEvent()).missions;
      m = tr
          .apply(m, const MergeEvent(produced: BallTier.t2, score: 2))
          .missions;
      m = tr
          .apply(m, const MergeEvent(produced: BallTier.t3, score: 6))
          .missions;
      // Комбо выполнено на втором слиянии за один бросок.
      expect(m.map((Mission x) => x.id), <int>[1]);
      expect(m.single.progress, 2);
      m = tr
          .apply(m, const DropEvent())
          .missions; // бросок без слияний → серия 0
      expect(m.single.progress, 2,
          reason: 'серия обнуляется на следующем броске');
      m = tr.apply(m, const DropEvent()).missions;
      expect(m.single.progress, 0);
      m = tr
          .apply(m, const MergeEvent(produced: BallTier.t2, score: 8))
          .missions;
      m = tr.apply(m, const DropEvent()).missions;
      m = tr
          .apply(m, const MergeEvent(produced: BallTier.t2, score: 10))
          .missions;
      final MissionStep s =
          tr.apply(m, const MergeEvent(produced: BallTier.t3, score: 16));
      expect(s.completed.single.id, 1);
    });

    test('economy: успех в лимит, провал при переборе', () {
      final MissionTracker tr = MissionTracker();
      List<Mission> m = <Mission>[
        of(MissionType.economy, tier: BallTier.t5, target: 2, id: 7),
      ];
      m = tr.apply(m, const DropEvent()).missions;
      m = tr.apply(m, const DropEvent()).missions;
      expect(m.single.remaining, 0);
      MissionStep s = tr.apply(m, const DropEvent());
      expect(s.failed.single.id, 7);
      expect(s.missions, isEmpty);

      final MissionTracker tr2 = MissionTracker();
      m = <Mission>[
        of(MissionType.economy, tier: BallTier.t5, target: 2, id: 8)
      ];
      m = tr2.apply(m, const DropEvent()).missions;
      s = tr2.apply(m, const MergeEvent(produced: BallTier.t5, score: 32));
      expect(s.completed.single.id, 8);
    });

    test('clean сбрасывается касанием линии, score и bomb', () {
      final MissionTracker tr = MissionTracker();
      List<Mission> m = <Mission>[
        of(MissionType.clean, target: 3, id: 1),
        of(MissionType.score, target: 100, id: 2),
        of(MissionType.bonusBomb, tier: BallTier.t4, id: 3),
      ];
      m = tr.apply(m, const DropEvent()).missions;
      m = tr.apply(m, const DropEvent()).missions;
      expect(m[0].progress, 2);
      m = tr.apply(m, const LineTouchEvent()).missions;
      expect(m[0].progress, 0);
      m = tr.apply(m, const BombEvent(BallTier.t3)).missions;
      expect(m.length, 3);
      MissionStep s = tr.apply(m, const BombEvent(BallTier.t4));
      expect(s.completed.single.id, 3);
      s = tr.apply(
          s.missions, const MergeEvent(produced: BallTier.t7, score: 120));
      expect(s.completed.single.id, 2);
    });
  });
}
