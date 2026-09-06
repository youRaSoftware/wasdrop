import 'package:flutter/foundation.dart';

/// Хук обратной связи на нажатие кнопок дизайн-системы (звук + хаптика).
///
/// core_ui ничего не знает о сервисах приложения: приложение назначает
/// [onPressed] при старте (`lib/main_common.dart` → `AudioService.tap`),
/// а все кнопки из `core_ui/lib/src/widgets/` дёргают [trigger].
abstract final class ButtonFeedback {
  static VoidCallback? onPressed;

  static void trigger() => onPressed?.call();
}
