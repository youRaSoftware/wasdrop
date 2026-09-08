part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final GameStatsModel stats;

  /// «1.0.0 (2)»; пустая строка, пока не загружена.
  final String version;

  /// Показан оверлей «Сбросить статистику?».
  final bool confirmingReset;

  const SettingsState({
    this.stats = const GameStatsModel.empty(),
    this.version = '',
    this.confirmingReset = false,
  });

  SettingsState copyWith({
    GameStatsModel? stats,
    String? version,
    bool? confirmingReset,
  }) {
    return SettingsState(
      stats: stats ?? this.stats,
      version: version ?? this.version,
      confirmingReset: confirmingReset ?? this.confirmingReset,
    );
  }

  @override
  List<Object?> get props => <Object?>[stats, version, confirmingReset];
}
