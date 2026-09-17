import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import 'mission_text.dart';

/// Панель заказов между HUD и стаканом: три карточки в ряд (иконка цели,
/// текст, полоска прогресса, награда). Выполненная карточка сменяется
/// новой с выездом. На низких экранах — [compact]: три кольца прогресса
/// с иконками в одну строку. Тап по панели открывает экран заказов.
class MissionsPanel extends StatelessWidget {
  static const Key panelKey = Key('missions_panel');
  static const double height = 60;
  static const double compactHeight = 40;

  final bool compact;
  final VoidCallback onTap;

  const MissionsPanel({required this.onTap, this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    final List<Mission> missions = context.watch<GameCubit>().state.missions;
    return GestureDetector(
      key: panelKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: compact ? compactHeight : height,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < MissionGenerator.slots; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (Widget child, Animation<double> a) {
                    return FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.4),
                          end: Offset.zero,
                        ).animate(a),
                        child: child,
                      ),
                    );
                  },
                  child: i < missions.length
                      ? (compact
                          ? _CompactMission(
                              key: ValueKey<int>(missions[i].id),
                              mission: missions[i],
                            )
                          : MissionCard(
                              key: ValueKey<int>(missions[i].id),
                              mission: missions[i],
                            ))
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Карточка заказа: иконка, текст в две строки, полоска прогресса,
/// бейдж награды; последний шаг — лёгкая пульсация рамки.
class MissionCard extends StatelessWidget {
  final Mission mission;

  const MissionCard({required this.mission, super.key});

  bool get _almost =>
      mission.type != MissionType.economy &&
      mission.target > 1 &&
      mission.remaining == 1;

  @override
  Widget build(BuildContext context) {
    final String counter = missionCounter(context, mission, short: true);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _almost ? AppColors.accent : AppColors.stroke,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              missionIcon(mission, size: 22),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  missionText(context, mission),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.best.copyWith(
                    fontSize: 10,
                    height: 1.15,
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: mission.fraction,
                    minHeight: 3,
                    backgroundColor: AppColors.stroke,
                    color: mission.type == MissionType.economy
                        ? AppColors.alert
                        : AppColors.scoreGain,
                  ),
                ),
              ),
              if (counter.isNotEmpty) ...<Widget>[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    counter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.best.copyWith(
                      fontSize: 8.5,
                      color: AppColors.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 5),
              // На узких карточках награда ужимается, а не вылезает.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: missionRewardChip(mission.reward, iconSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Компактный заказ: кольцо прогресса с иконкой цели.
class _CompactMission extends StatelessWidget {
  final Mission mission;

  const _CompactMission({required this.mission, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CustomPaint(
          painter: _RingPainter(
            fraction: mission.fraction,
            color: mission.type == MissionType.economy
                ? AppColors.alert
                : AppColors.scoreGain,
          ),
          child: Center(child: missionIcon(mission, size: 22)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(2);
    canvas.drawOval(rect, Paint()..color = AppColors.surface);
    final Paint track = Paint()
      ..color = AppColors.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(rect, track);
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        track
          ..color = color
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}
