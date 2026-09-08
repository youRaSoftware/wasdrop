import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

import 'fruit_sprites.dart';

/// Спрайты фруктов как Flutter-картинки — для HUD и меню (в игре их рисует
/// движок через [FruitSprites]).
abstract final class FruitAssets {
  static ImageProvider idle(BallTier tier) => AssetImage(
        'assets/images/${FruitSprites.fileName(tier, 'idle')}',
        package: FruitSprites.package,
      );
}
