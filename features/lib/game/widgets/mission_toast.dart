import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'mission_text.dart';

/// Всплывашка «Заказ выполнен!» над стаканом: карточка всплывает и
/// растворяется за [duration], вокруг — конфетти в палитре игры. Игру не
/// блокирует (кладётся в `Overlay` без затемнения).
class MissionToast extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 1400);

  final Mission mission;
  final VoidCallback onDone;

  const MissionToast({required this.mission, required this.onDone, super.key});

  @override
  State<MissionToast> createState() => _MissionToastState();
}

class _MissionToastState extends State<MissionToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: MissionToast.duration,
  )..forward().whenComplete(widget.onDone);

  final List<_Confetto> _confetti = List<_Confetto>.generate(
    18,
    (int i) => _Confetto(i),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Overlay лежит вне Material — без него текст получает жёлтое
    // подчёркивание «нет Material-предка».
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? child) {
            final double t = _c.value;
            final double pop =
                Curves.easeOutBack.transform((t / 0.3).clamp(0, 1));
            final double fade = t < 0.75 ? 1 : 1 - (t - 0.75) / 0.25;
            return Opacity(
              opacity: fade,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: <Widget>[
                  CustomPaint(
                    size: const Size(260, 140),
                    painter: _ConfettiPainter(_confetti, t),
                  ),
                  Transform.scale(scale: 0.8 + 0.2 * pop, child: child),
                ],
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.accent, width: 2),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.panelShadow,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  context.tr(LocaleKeys.missions_done),
                  style: AppFonts.overlayTitle.copyWith(
                    fontSize: 15,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  missionText(context, widget.mission),
                  textAlign: TextAlign.center,
                  style: AppFonts.best.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                missionRewardChip(widget.mission.reward, iconSize: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Confetto {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double spin;

  _Confetto(int i)
      : angle = (i / 18) * 2 * math.pi + (i.isEven ? 0.15 : -0.15),
        speed = 70 + (i * 37) % 60,
        size = 4 + (i * 13) % 4,
        color = AppColors.tiers[(i * 5) % AppColors.tiers.length],
        spin = ((i * 7) % 5 - 2) * 3.0;
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetto> items;
  final double t;

  const _ConfettiPainter(this.items, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double e = Curves.easeOutCubic.transform(t);
    for (final _Confetto p in items) {
      final Offset pos = c +
          Offset(math.cos(p.angle), math.sin(p.angle)) * (p.speed * e) +
          Offset(0, 40 * t * t);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        Paint()..color = p.color.withValues(alpha: 1 - t * 0.6),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
