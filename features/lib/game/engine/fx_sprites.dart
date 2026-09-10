import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';

/// Спрайты бонусов из `features/assets/images/fx/`: бомбочка, которая
/// ложится на выбранный фрукт, и три кадра взрыва. Грузятся один раз в
/// `WasDropGame.onLoad`; без файлов эффекты рисуются процедурно
/// (см. `bonus_effects.dart`).
class FxSprites {
  static const String package = 'features';
  static const String folder = 'fx';
  static const int boomFrames = 3;

  Sprite? bomb;
  final List<Sprite> boom = <Sprite>[];

  Future<void> load(Images images) async {
    try {
      final ui.Image bombImage =
          await images.load('$folder/bomb.png', package: package);
      bomb = Sprite(bombImage);
      for (int i = 1; i <= boomFrames; i++) {
        final ui.Image frame =
            await images.load('$folder/boom_$i.png', package: package);
        boom.add(Sprite(frame));
      }
    } catch (error) {
      debugPrint('FxSprites: load failed, drawing effects procedurally: '
          '$error');
    }
  }
}
