import 'package:domain/domain.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'locale_keys.g.dart';

/// Локализованное название фрукта по тиру (цепочка в настройках,
/// «Самый большой фрукт»). Через [context], чтобы виджет перестраивался
/// при смене языка.
abstract final class FruitLabel {
  static const Map<BallTier, String> _keys = <BallTier, String>{
    BallTier.t1: LocaleKeys.fruits_cherry,
    BallTier.t2: LocaleKeys.fruits_strawberry,
    BallTier.t3: LocaleKeys.fruits_tangerine,
    BallTier.t4: LocaleKeys.fruits_lemon,
    BallTier.t5: LocaleKeys.fruits_apple,
    BallTier.t6: LocaleKeys.fruits_kiwi,
    BallTier.t7: LocaleKeys.fruits_blueberry,
    BallTier.t8: LocaleKeys.fruits_grape,
    BallTier.t9: LocaleKeys.fruits_peach,
    BallTier.t10: LocaleKeys.fruits_melon,
    BallTier.t11: LocaleKeys.fruits_watermelon,
  };

  static String of(BuildContext context, BallTier tier) =>
      context.tr(_keys[tier]!);
}
