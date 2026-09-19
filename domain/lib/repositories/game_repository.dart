import '../enums/game_mode.dart';
import '../models/game_snapshot.dart';

/// Сохранённая партия — по одной на сохраняемый режим (классика, сад).
abstract interface class GameRepository {
  Future<GameSnapshot?> load({GameMode mode = GameMode.classic});
  Future<void> save(GameSnapshot snapshot, {GameMode mode = GameMode.classic});
  Future<void> clear({GameMode mode = GameMode.classic});
}
