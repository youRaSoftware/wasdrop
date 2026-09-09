import '../models/game_snapshot.dart';

/// Сохранённая партия (одна на устройство).
abstract interface class GameRepository {
  Future<GameSnapshot?> load();
  Future<void> save(GameSnapshot snapshot);
  Future<void> clear();
}
