import 'dart:ui' as ui;

import 'package:domain/domain.dart';
import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';

import 'fruit_sprites.dart';

/// Спрайты особых фруктов «Сада чудес» из `features/assets/images/special/`:
/// пары idle/squish по [SpecialKind], брызги пузырика, осколки льда и
/// корка льда поверх замороженного фрукта. Грузятся один раз в
/// `WasDropGame.onLoad`; без файлов особый фрукт рисуется кружком.
class SpecialSprites {
  static const String package = 'features';
  static const String folder = 'special';

  /// Спрайт по фрукту, подогнанный по альфа-каналу как у обычных
  /// ([FruitSprites.measureBody]): видимое тело совпадает с физическим
  /// кругом [SpecialKind.radius], сколько бы пустого поля ни было в PNG
  /// (гнилушка в кадре мелкая — без подгонки она «висела в воздухе»).
  final Map<SpecialKind, FruitSprite> _fruits = <SpecialKind, FruitSprite>{};
  Sprite? bubblePop;
  Sprite? iceCrack;
  Sprite? iceOverlay;

  static String fileName(SpecialKind kind, String state) =>
      '$folder/${kind.name}_$state.png';

  FruitSprite? operator [](SpecialKind kind) => _fruits[kind];

  /// Сырой спрайт (окошко «следующий», прицел).
  Sprite? idle(SpecialKind kind) => _fruits[kind]?.idle;

  Future<void> load(Images images) async {
    try {
      for (final SpecialKind kind in SpecialKind.values) {
        final ui.Image idle =
            await images.load(fileName(kind, 'idle'), package: package);
        final ui.Image squish =
            await images.load(fileName(kind, 'squish'), package: package);
        final FruitBodyFit fit = await FruitSprites.measureBody(idle);
        _fruits[kind] = FruitSprite(
          idle: Sprite(idle),
          squish: Sprite(squish),
          fitRadiusPx: fit.radiusPx,
          bodyCenter: fit.center,
          // Тело особого — всегда круг: контур не нужен.
          hull: null,
          roundingPx: fit.roundingPx,
          maxExtentPx: fit.maxExtentPx,
          minExtentPx: fit.minExtentPx,
        );
      }
      bubblePop = Sprite(
        await images.load('$folder/bubble_pop.png', package: package),
      );
      iceCrack = Sprite(
        await images.load('$folder/ice_crack.png', package: package),
      );
      iceOverlay = Sprite(
        await images.load('$folder/ice_overlay.png', package: package),
      );
    } catch (error) {
      debugPrint('SpecialSprites: load failed, drawing plain circles: $error');
    }
  }
}

/// Игра, у которой есть спрайты особых фруктов (`WasDropGame`).
abstract interface class SpecialSpriteProvider {
  SpecialSprites get specialSprites;
}
