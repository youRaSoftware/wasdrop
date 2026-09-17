// Куча в меню пересыпается по наклону: перевернули телефон — фрукты
// упали к верху экрана и не улетели (потолок), вернули — снова вниз.
import 'package:features/game/engine/ball_body.dart';
import 'package:features/menu/engine/menu_pile_game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('переворот телефона роняет кучу к верху экрана', () async {
    final MenuPileGame game = MenuPileGame(
      fruitCountPerPhone: 8,
      spawnInterval: 0.02,
      maxTierIndex: 3,
    );
    game.onGameResize(Vector2(360, 640));
    // ignore: invalid_use_of_internal_member
    await game.load();
    // ignore: invalid_use_of_internal_member
    game.mount();
    Future<void> run(double seconds) async {
      for (int i = 0; i < seconds * 60; i++) {
        game.update(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
    }

    await run(4);
    List<BallBody> balls() =>
        game.world.children.whereType<BallBody>().toList();
    expect(balls(), hasLength(8));
    expect(balls().every((BallBody b) => b.body.position.y > 320), isTrue,
        reason: 'сначала куча внизу');

    // Слабый наклон (телефон лежит) гравитацию не меняет.
    game.setTilt(0.5, 1);
    expect(game.world.physicsWorld.gravity.y, greaterThan(0));

    game.setTilt(0, -9.8); // вверх ногами
    await run(4);
    for (final BallBody b in balls()) {
      expect(b.body.position.y, lessThan(320),
          reason: 'после переворота фрукт у верха');
      expect(b.body.position.y, greaterThan(b.radius - 3),
          reason: 'потолок держит фрукт на экране');
    }

    game.setTilt(0, 9.8);
    await run(4);
    expect(balls().every((BallBody b) => b.body.position.y > 320), isTrue,
        reason: 'вернули — куча снова внизу');
    game.world.physicsWorld.destroy();
  });
}
