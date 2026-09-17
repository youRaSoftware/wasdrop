import '../enums/ball_tier.dart';
import 'mission.dart';

/// Событие партии, которое двигает заказы.
sealed class MissionEvent {
  const MissionEvent();
}

/// Слияние дало фрукт [produced] (null — джекпот двух арбузов).
class MergeEvent extends MissionEvent {
  final BallTier? produced;
  final int score;

  const MergeEvent({required this.produced, required this.score});
}

/// Бросок текущего фрукта.
class DropEvent extends MissionEvent {
  const DropEvent();
}

/// Бомбочка взорвала фрукт [tier].
class BombEvent extends MissionEvent {
  final BallTier tier;

  const BombEvent(this.tier);
}

/// Фрукт коснулся линии проигрыша (покоится выше неё).
class LineTouchEvent extends MissionEvent {
  const LineTouchEvent();
}

/// Результат шага трекера: обновлённые заказы, выполненные и провалившиеся
/// (economy с перебором бросков) — их кубит заменяет новыми.
class MissionStep {
  final List<Mission> missions;
  final List<Mission> completed;
  final List<Mission> failed;

  const MissionStep({
    required this.missions,
    this.completed = const <Mission>[],
    this.failed = const <Mission>[],
  });
}

/// Считает прогресс заказов по событиям партии. Счётчики серии/комбо/
/// чистых бросков живут здесь (в снимок не попадают — после
/// восстановления серия начинается заново); у economy потраченные броски
/// лежат в `Mission.progress` и в снимок попадают.
class MissionTracker {
  /// Слияний с последнего броска (комбо = ≥ 2).
  int mergesSinceDrop = 0;

  /// Слияний подряд без пустого броска.
  int streak = 0;

  /// Бросков подряд без касания линии.
  int cleanDrops = 0;

  void reset() {
    mergesSinceDrop = 0;
    streak = 0;
    cleanDrops = 0;
  }

  MissionStep apply(List<Mission> missions, MissionEvent event) {
    switch (event) {
      case DropEvent():
        if (mergesSinceDrop == 0) streak = 0;
        mergesSinceDrop = 0;
        cleanDrops++;
      case MergeEvent():
        mergesSinceDrop++;
        streak++;
      case LineTouchEvent():
        cleanDrops = 0;
      case BombEvent():
        break;
    }

    final List<Mission> out = <Mission>[];
    final List<Mission> completed = <Mission>[];
    final List<Mission> failed = <Mission>[];
    for (final Mission m in missions) {
      final Mission updated = _advance(m, event);
      if (updated.isDone) {
        completed.add(updated);
      } else if (m.type == MissionType.economy && updated.progress > m.target) {
        failed.add(m);
      } else {
        out.add(updated);
      }
    }
    return MissionStep(missions: out, completed: completed, failed: failed);
  }

  static Mission _count(Mission m, int progress) =>
      m.copyWith(progress: progress, done: progress >= m.target);

  Mission _advance(Mission m, MissionEvent event) {
    switch (m.type) {
      case MissionType.getFruit:
        if (event is MergeEvent && event.produced == m.tier) {
          return _count(m, 1);
        }
      case MissionType.collectFruits:
        if (event is MergeEvent && event.produced == m.tier) {
          return _count(m, m.progress + 1);
        }
      case MissionType.mergeStreak:
        if (event is MergeEvent || event is DropEvent) {
          return _count(m, streak);
        }
      case MissionType.combo:
        if (event is MergeEvent && mergesSinceDrop >= 2) {
          return _count(m, 1);
        }
      case MissionType.economy:
        if (event is MergeEvent && event.produced == m.tier) {
          return m.copyWith(done: true);
        }
        if (event is DropEvent) {
          return m.copyWith(progress: m.progress + 1);
        }
      case MissionType.bonusBomb:
        if (event is BombEvent && event.tier == m.tier) {
          return _count(m, 1);
        }
      case MissionType.score:
        if (event is MergeEvent) {
          return _count(m, event.score);
        }
      case MissionType.clean:
        if (event is DropEvent || event is LineTouchEvent) {
          return _count(m, cleanDrops);
        }
    }
    return m;
  }
}
