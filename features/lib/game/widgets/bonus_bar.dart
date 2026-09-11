import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';

/// Полоса бонусов под стаканом: «Встряхнуть», «Бомбочка», «Увеличить» с
/// бейджами оставшихся зарядов. Кнопка взводит бонус ([GameCubit.armBonus]),
/// взведённый обведён акцентом. Без зарядов, пока есть пополнения, кнопка
/// предлагает пополнить ([onRefill]: бейдж с иконкой рекламы, у премиума —
/// «+»); когда и пополнения кончились (или не в игре) — выключена и
/// приглушена.
class BonusBar extends StatelessWidget {
  static const Key shakeKey = Key('bonus_shake');
  static const Key bombKey = Key('bonus_bomb');
  static const Key upgradeKey = Key('bonus_upgrade');

  final ValueChanged<Bonus> onArm;
  final ValueChanged<Bonus> onRefill;
  final bool isPremium;

  const BonusBar({
    required this.onArm,
    required this.onRefill,
    required this.isPremium,
    super.key,
  });

  static Key keyFor(Bonus bonus) => switch (bonus) {
        Bonus.shake => shakeKey,
        Bonus.bomb => bombKey,
        Bonus.upgrade => upgradeKey,
      };

  static AppIcons _iconFor(Bonus bonus) => switch (bonus) {
        Bonus.shake => AppIcons.shake,
        Bonus.bomb => AppIcons.bomb,
        Bonus.upgrade => AppIcons.upgrade,
      };

  @override
  Widget build(BuildContext context) {
    final GameState state = context.watch<GameCubit>().state;
    final bool playing = state.status == GameStatus.playing && !state.adBusy;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final Bonus bonus in Bonus.values) ...<Widget>[
          if (bonus != Bonus.values.first) const SizedBox(width: 20),
          _BonusButton(
            key: keyFor(bonus),
            icon: _iconFor(bonus),
            charges: state.charges(bonus),
            selected: state.armed == bonus,
            refill: playing && state.canRefill(bonus)
                ? (isPremium ? _RefillBadge.free : _RefillBadge.ad)
                : null,
            onPressed: !playing
                ? null
                : state.charges(bonus) > 0
                    ? () => onArm(bonus)
                    : state.canRefill(bonus)
                        ? () => onRefill(bonus)
                        : null,
          ),
        ],
      ],
    );
  }
}

/// Бейдж на кнопке без зарядов: ролик или бесплатное пополнение (премиум).
enum _RefillBadge { ad, free }

class _BonusButton extends StatelessWidget {
  static const double badgeSize = 20;

  final AppIcons icon;
  final int charges;
  final bool selected;
  final _RefillBadge? refill;
  final VoidCallback? onPressed;

  const _BonusButton({
    required this.icon,
    required this.charges,
    required this.onPressed,
    this.refill,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double box = AppDimens.iconButtonSize + badgeSize / 2;
    final _RefillBadge? refill = this.refill;
    return Opacity(
      opacity: charges > 0 || refill != null ? 1 : 0.4,
      child: SizedBox(
        width: box,
        height: box,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              bottom: 0,
              child: IconCircleButton(
                onPressed: onPressed,
                borderColor: selected ? AppColors.accent : null,
                child: AppIcon(icon, size: 26),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        refill == null ? AppColors.accent : AppColors.surface,
                    border: Border.all(
                      color:
                          refill == null ? AppColors.surface : AppColors.accent,
                      width: 2,
                    ),
                  ),
                  child: switch (refill) {
                    null => Text(
                        '$charges',
                        style: AppFonts.best.copyWith(
                          color: AppColors.flash,
                          fontSize: 10,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                    _RefillBadge.ad => const AppIcon(AppIcons.adPlay, size: 12),
                    _RefillBadge.free => const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
