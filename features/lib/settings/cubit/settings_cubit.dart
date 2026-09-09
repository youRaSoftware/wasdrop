import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'settings_state.dart';

/// Экран настроек: статистика (с подтверждаемым сбросом) и версия.
/// Тумблеры звука/вибрации/прицела идут напрямую в `SettingsService`.
class SettingsCubit extends Cubit<SettingsState> {
  final StatsRepository statsRepository;

  SettingsCubit({required this.statsRepository})
      : super(const SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    final GameStatsModel stats = await statsRepository.getStats();
    _safeEmit(state.copyWith(stats: stats));
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _safeEmit(
        state.copyWith(version: '${info.version} (${info.buildNumber})'),
      );
    } catch (error) {
      debugPrint('SettingsCubit: package info failed: $error');
    }
  }

  void _safeEmit(SettingsState next) {
    if (isClosed) return;
    emit(next);
  }

  void askReset() => _safeEmit(state.copyWith(confirmingReset: true));

  void cancelReset() => _safeEmit(state.copyWith(confirmingReset: false));

  void askLanguage() => _safeEmit(state.copyWith(choosingLanguage: true));

  void closeLanguage() => _safeEmit(state.copyWith(choosingLanguage: false));

  Future<void> confirmReset() async {
    await statsRepository.saveStats(const GameStatsModel.empty());
    _safeEmit(state.copyWith(
      stats: const GameStatsModel.empty(),
      confirmingReset: false,
    ));
  }
}
