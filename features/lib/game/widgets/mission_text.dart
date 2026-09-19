import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

import '../engine/fruit_assets.dart';
import '../engine/special_sprites.dart';

/// Текст заказа (`missions.<type>` с `{fruit}` и `{n}`).
String missionText(BuildContext context, Mission m) {
  final BallTier? tier = m.tier;
  final Map<String, String> args = <String, String>{
    'n': '${m.target}',
    if (tier != null) 'fruit': FruitLabel.of(context, tier),
  };
  final String key = switch (m.type) {
    MissionType.getFruit => LocaleKeys.missions_getFruit,
    MissionType.collectFruits => LocaleKeys.missions_collectFruits,
    MissionType.mergeStreak => LocaleKeys.missions_mergeStreak,
    MissionType.combo => LocaleKeys.missions_combo,
    MissionType.economy => LocaleKeys.missions_economy,
    MissionType.bonusBomb => LocaleKeys.missions_bonusBomb,
    MissionType.score => LocaleKeys.missions_score,
    MissionType.clean => LocaleKeys.missions_clean,
    MissionType.mergeRainbow => LocaleKeys.missions_mergeRainbow,
    MissionType.popBubbles => LocaleKeys.missions_popBubbles,
  };
  return context.tr(key, namedArgs: args);
}

/// Счётчик под текстом: «2/5», у economy — остаток бросков («Осталось
/// бросков: 12», в карточке [short] — «12»), у одноразовых целей — пусто.
String missionCounter(BuildContext context, Mission m, {bool short = false}) {
  switch (m.type) {
    case MissionType.getFruit:
    case MissionType.combo:
    case MissionType.bonusBomb:
      return '';
    case MissionType.economy:
      if (short) return '${m.remaining}';
      return context.tr(
        LocaleKeys.missions_dropsLeft,
        namedArgs: <String, String>{'n': '${m.remaining}'},
      );
    case MissionType.collectFruits:
    case MissionType.mergeStreak:
    case MissionType.score:
    case MissionType.clean:
    case MissionType.mergeRainbow:
    case MissionType.popBubbles:
      return '${m.progress.clamp(0, m.target)}/${m.target}';
  }
}

/// Иконка типа заказа: фрукт-цель или пиктограмма.
Widget missionIcon(Mission m, {double size = 24}) {
  final BallTier? tier = m.tier;
  if (tier != null) {
    return BallView(
      tier: tier,
      diameter: size,
      image: FruitAssets.idle(tier),
    );
  }
  if (m.type == MissionType.mergeRainbow || m.type == MissionType.popBubbles) {
    return Image.asset(
      'assets/images/${SpecialSprites.fileName(
        m.type == MissionType.mergeRainbow
            ? SpecialKind.rainbow
            : SpecialKind.bubble,
        'idle',
      )}',
      package: SpecialSprites.package,
      width: size,
      height: size,
    );
  }
  final AppIcons icon = switch (m.type) {
    MissionType.mergeStreak => AppIcons.streak,
    MissionType.combo => AppIcons.combo,
    MissionType.score => AppIcons.star,
    MissionType.clean => AppIcons.missions,
    _ => AppIcons.missions,
  };
  return AppIcon(icon, size: size);
}

/// Награда: иконка бонуса и/или «+N».
Widget missionRewardChip(MissionReward reward, {double iconSize = 14}) {
  final Bonus? bonus = reward.bonus;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (bonus != null) ...<Widget>[
        AppIcon(
          switch (bonus) {
            Bonus.shake => AppIcons.shake,
            Bonus.bomb => AppIcons.bomb,
            Bonus.upgrade => AppIcons.upgrade,
          },
          size: iconSize,
        ),
        const SizedBox(width: 2),
      ],
      if (reward.points > 0)
        Text(
          '+${reward.points}',
          style: AppFonts.best.copyWith(
            fontSize: iconSize * 0.8,
            color: AppColors.scoreGain,
            letterSpacing: 0,
          ),
        ),
      const SizedBox(width: 3),
      AppIcon(AppIcons.star, size: iconSize),
    ],
  );
}
