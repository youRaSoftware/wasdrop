import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Наклон телефона по акселерометру **с гравитацией** (в отличие от
/// [ShakeDetector], которому гравитация мешает): отдаёт сглаженный вектор
/// в осях экрана — `x` вправо, `y` вниз, единицы м/с². Держит телефон
/// прямо → (0, 9.8); вверх ногами → (0, −9.8); правым краем вниз →
/// (9.8, 0). Живёт с экраном меню (куча фруктов пересыпается), в DI не
/// нужен. Без датчика (симулятор) молчит; [simulate] — для тестов.
class TiltDetector {
  static const double _smoothing = 0.25;

  final void Function(double x, double y) onTilt;

  static final Set<TiltDetector> _active = <TiltDetector>{};

  StreamSubscription<AccelerometerEvent>? _subscription;
  double _x = 0;
  double _y = 9.8;

  TiltDetector({required this.onTilt});

  static void simulate(double x, double y) {
    for (final TiltDetector d in _active.toList()) {
      d.onTilt(x, y);
    }
  }

  void start() {
    if (_subscription != null) return;
    _active.add(this);
    try {
      _subscription = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        _onEvent,
        onError: (Object error) =>
            debugPrint('TiltDetector: accelerometer unavailable: $error'),
        cancelOnError: true,
      );
    } catch (error) {
      debugPrint('TiltDetector: accelerometer unavailable: $error');
    }
  }

  /// Оси датчика (Android-соглашение, sensors_plus приводит iOS к нему):
  /// в покое датчик показывает минус гравитацию — телефон прямо даёт
  /// y = +9.8, правым краем вниз — x = −9.8. В осях экрана (y вниз):
  /// экранный x = −x датчика, экранный y = +y датчика.
  void _onEvent(AccelerometerEvent e) {
    _x += (-e.x - _x) * _smoothing;
    _y += (e.y - _y) * _smoothing;
    onTilt(_x, _y);
  }

  Future<void> stop() async {
    _active.remove(this);
    await _subscription?.cancel();
    _subscription = null;
  }
}
