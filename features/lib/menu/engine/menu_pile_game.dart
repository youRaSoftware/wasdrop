import 'package:flame/events.dart';

import '../../splash/engine/splash_game.dart';

/// Куча фруктов в меню: заставка, которая быстро насыпает фрукты и даёт
/// подбросить любой из них тапом. Кладётся под интерфейс меню, тапы по
/// кнопкам до неё не доходят.
class MenuPileGame extends SplashGame with TapCallbacks {
  MenuPileGame({
    required super.fruitCountPerPhone,
    required super.spawnInterval,
    required super.maxTierIndex,
  });

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    poke(screenToWorld(event.canvasPosition));
  }
}
