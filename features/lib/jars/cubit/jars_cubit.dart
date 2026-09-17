import 'package:core/core.dart';
import 'package:domain/domain.dart';

part 'jars_state.dart';

/// Экран выбора стакана: звёзды из прогресса, выбор — в настройки
/// (`SettingsService.setJarId`), действует на следующую партию.
class JarsCubit extends Cubit<JarsState> {
  final ProgressRepository progressRepository;
  final SettingsService settings;

  JarsCubit({required this.progressRepository, required this.settings})
      : super(JarsState(stars: 0, selectedId: settings.value.jarId)) {
    _load();
  }

  Future<void> _load() async {
    final ProgressModel progress = await progressRepository.getProgress();
    if (isClosed) return;
    emit(state.copyWith(stars: progress.stars));
  }

  /// Выбирает открытый стакан; закрытый игнорируется.
  Future<void> select(JarShape jar) async {
    if (!state.isUnlocked(jar) || jar.id == state.selectedId) return;
    emit(state.copyWith(selectedId: jar.id));
    await settings.setJarId(jar.id);
  }
}
