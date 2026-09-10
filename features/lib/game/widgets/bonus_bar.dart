import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';

/// Полоса бонусов под стаканом: «Встряхнуть», «Бомбочка», «Увеличить» с
/// бейджами оставшихся зарядов. Кнопка взводит бонус ([GameCubit.armBonus]),
/// взведённый обведён акцентом; без зарядов (или не в игре) кнопка выключена
/// и приглушена.
class BonusBar extends StatelessWidget {
  static const Key shakeKey = Key('bonus_shake');
  static const Key bombKey = Key('bonus_bomb');
  static const Key upgradeKey = Key('bonus_upgrade');

  final ValueChanged<Bonus> onArm;

  const BonusBar({required this.onArm, super.key});

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
    final bool playing = state.status == GameStatus.playing;

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
            onPressed:
                playing && state.charges(bonus) > 0 ? () => onArm(bonus) : null,
          ),
        ],
      ],
    );
  }
}

class _BonusButton extends StatelessWidget {
  static const double badgeSize = 20;

  final AppIcons icon;
  final int charges;
  final bool selected;
  final VoidCallback? onPressed;

  const _BonusButton({
    required this.icon,
    required this.charges,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double box = AppDimens.iconButtonSize + badgeSize / 2;
    return Opacity(
      opacity: charges > 0 ? 1 : 0.4,
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
                    color: AppColors.accent,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Text(
                    '$charges',
                    style: AppFonts.best.copyWith(
                      color: AppColors.flash,
                      fontSize: 10,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
