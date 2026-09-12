import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../splash/engine/splash_game.dart';
import '../engine/menu_pile_game.dart';

/// Живой фон меню (вариант «куча»): фрукты быстро сыплются и ложатся кучей
/// вдоль нижнего края, тап по фрукту подбрасывает его. Тот же движок, что
/// у заставки. Кладётся под интерфейс меню; тапы по кнопкам до него не
/// доходят.
class MenuFruitPile extends StatefulWidget {
  /// Фруктов на ширину телефона; на планшете — пропорционально ширине.
  /// Куча должна занимать нижнюю четверть экрана, не выше кнопок.
  static const int fruitsPerPhone = 14;
  static const double spawnInterval = 0.045;

  /// Крупнее черники (t7) в кучу не сыплем — иначе она вырастает до кнопок.
  static const int maxTierIndex = 6;

  const MenuFruitPile({super.key});

  @override
  State<MenuFruitPile> createState() => _MenuFruitPileState();
}

class _MenuFruitPileState extends State<MenuFruitPile> {
  late final MenuPileGame _game = MenuPileGame(
    fruitCountPerPhone: MenuFruitPile.fruitsPerPhone,
    spawnInterval: MenuFruitPile.spawnInterval,
    maxTierIndex: MenuFruitPile.maxTierIndex,
  );

  @override
  Widget build(BuildContext context) {
    return GameWidget<SplashGame>(game: _game);
  }
}
