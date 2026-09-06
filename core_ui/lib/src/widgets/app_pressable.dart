import 'package:flutter/material.dart';

import '../feedback/button_feedback.dart';

/// Строит виджет по степени нажатия [pressed] ∈ [0, 1].
typedef PressableBuilder = Widget Function(
  BuildContext context,
  double pressed,
  Widget? child,
);

/// Основа всех кнопок дизайн-системы: ловит нажатие, анимирует «степень
/// нажатия» (0 → 1 при onTapDown, обратно при отпускании/отмене) и отдаёт её
/// в [builder]. На срабатывании вызывает [ButtonFeedback.trigger] (звук +
/// хаптика по настройкам), затем [onPressed]. `onPressed == null` — кнопка
/// выключена: без анимации и без колбэков.
class AppPressable extends StatefulWidget {
  final PressableBuilder builder;
  final VoidCallback? onPressed;
  final Widget? child;
  final Duration duration;
  final bool feedback;

  const AppPressable({
    required this.builder,
    required this.onPressed,
    this.child,
    this.duration = const Duration(milliseconds: 110),
    this.feedback = true,
    super.key,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.duration * 1.6,
  );
  late final CurvedAnimation _pressed = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeOutBack,
  );

  bool get _enabled => widget.onPressed != null;

  @override
  void dispose() {
    _pressed.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (_enabled) _controller.forward();
  }

  void _release() {
    if (_controller.status != AnimationStatus.dismissed) _controller.reverse();
  }

  void _onTap() {
    if (!_enabled) return;
    if (widget.feedback) ButtonFeedback.trigger();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: (TapUpDetails _) => _release(),
      onTapCancel: _release,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _pressed,
        child: widget.child,
        builder: (BuildContext context, Widget? child) {
          return widget.builder(context, _pressed.value, child);
        },
      ),
    );
  }
}
