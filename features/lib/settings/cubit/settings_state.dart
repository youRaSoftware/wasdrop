part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final GameStatsModel stats;

  /// «1.0.0 (2)»; пустая строка, пока не загружена.
  final String version;

  /// Показан оверлей «Сбросить статистику?».
  final bool confirmingReset;

  /// Показан оверлей выбора языка.
  final bool choosingLanguage;

  const SettingsState({
    this.stats = const GameStatsModel.empty(),
    this.version = '',
    this.confirmingReset = false,
    this.choosingLanguage = false,
  });

  SettingsState copyWith({
    GameStatsModel? stats,
    String? version,
    bool? confirmingReset,
    bool? choosingLanguage,
  }) {
    return SettingsState(
      stats: stats ?? this.stats,
      version: version ?? this.version,
      confirmingReset: confirmingReset ?? this.confirmingReset,
      choosingLanguage: choosingLanguage ?? this.choosingLanguage,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[stats, version, confirmingReset, choosingLanguage];
}
