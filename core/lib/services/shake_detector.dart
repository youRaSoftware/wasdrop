import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Встряска устройства по акселерометру без гравитации: срабатывает, когда
/// модуль ускорения превышает [threshold], не чаще [cooldown]. Не в DI —
/// живёт вместе с игровым экраном (`start` в initState, `stop` в dispose).
/// Симулятор и устройства без датчика просто молчат: ошибки потока глушатся.
class ShakeDetector {
  /// м/с². Ходьба и тап по столу дают 2–5, резкий взмах телефоном — 15–30.
  static const double defaultThreshold = 15;
  static const Duration defaultCooldown = Duration(milliseconds: 1200);

  final double threshold;
  final Duration cooldown;
  final VoidCallback onShake;

  /// Запущенные детекторы — для [simulate].
  static final Set<ShakeDetector> _active = <ShakeDetector>{};

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  ShakeDetector({
    required this.onShake,
    this.threshold = defaultThreshold,
    this.cooldown = defaultCooldown,
  });

  /// Тесты и симулятор (без акселерометра): «встряхнуть» все запущенные
  /// детекторы, минуя порог и кулдаун.
  static void simulate() {
    for (final ShakeDetector detector in _active.toList()) {
      detector.onShake();
    }
  }

  void start() {
    if (_subscription != null) return;
    _active.add(this);
    try {
      _subscription = userAccelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        _onEvent,
        onError: (Object error) =>
            debugPrint('ShakeDetector: accelerometer unavailable: $error'),
        cancelOnError: true,
      );
    } catch (error) {
      debugPrint('ShakeDetector: accelerometer unavailable: $error');
    }
  }

  void _onEvent(UserAccelerometerEvent event) {
    final double magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < threshold) return;
    final DateTime now = DateTime.now();
    if (now.difference(_lastShake) < cooldown) return;
    _lastShake = now;
    onShake();
  }

  Future<void> stop() async {
    _active.remove(this);
    await _subscription?.cancel();
    _subscription = null;
  }
}
