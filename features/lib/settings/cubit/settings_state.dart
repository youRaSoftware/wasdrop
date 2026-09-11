part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final GameStatsModel stats;

  /// «1.0.0 (2)»; пустая строка, пока не загружена.
  final String version;

  /// Показан оверлей «Сбросить статистику?».
  final bool confirmingReset;

  /// Показан оверлей выбора языка.
  final bool choosingLanguage;

  /// UMP требует пункт «Настройки рекламы» (регион с обязательным согласием).
  final bool adPrivacyRequired;

  const SettingsState({
    this.stats = const GameStatsModel.empty(),
    this.version = '',
    this.confirmingReset = false,
    this.choosingLanguage = false,
    this.adPrivacyRequired = false,
  });

  SettingsState copyWith({
    GameStatsModel? stats,
    String? version,
    bool? confirmingReset,
    bool? choosingLanguage,
    bool? adPrivacyRequired,
  }) {
    return SettingsState(
      stats: stats ?? this.stats,
      version: version ?? this.version,
      confirmingReset: confirmingReset ?? this.confirmingReset,
      choosingLanguage: choosingLanguage ?? this.choosingLanguage,
      adPrivacyRequired: adPrivacyRequired ?? this.adPrivacyRequired,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        stats,
        version,
        confirmingReset,
        choosingLanguage,
        adPrivacyRequired,
      ];
}
