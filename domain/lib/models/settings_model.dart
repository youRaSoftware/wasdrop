import 'package:equatable/equatable.dart';

/// Пользовательские настройки (Hive-бокс `settingsBox`).
class SettingsModel extends Equatable {
  /// Тема-обои по умолчанию (описания тем — `GameThemes` в core_ui).
  static const String defaultThemeId = 'cream';

  /// Мастер-тумблер звука: эффекты и (вместе с [musicOn]) музыка.
  final bool soundOn;

  /// Фоновая музыка — играет только при включённом [soundOn].
  final bool musicOn;

  final bool hapticsOn;

  /// Пунктир прицела от подвешенного фрукта до кучи.
  final bool aimLineOn;

  /// Выбранная тема-обои.
  final String themeId;

  const SettingsModel({
    required this.soundOn,
    required this.musicOn,
    required this.hapticsOn,
    required this.aimLineOn,
    this.themeId = defaultThemeId,
  });

  const SettingsModel.empty()
      : this(soundOn: true, musicOn: true, hapticsOn: false, aimLineOn: true);

  /// Музыка должна играть.
  bool get musicPlays => soundOn && musicOn;

  SettingsModel copyWith({
    bool? soundOn,
    bool? musicOn,
    bool? hapticsOn,
    bool? aimLineOn,
    String? themeId,
  }) {
    return SettingsModel(
      soundOn: soundOn ?? this.soundOn,
      musicOn: musicOn ?? this.musicOn,
      hapticsOn: hapticsOn ?? this.hapticsOn,
      aimLineOn: aimLineOn ?? this.aimLineOn,
      themeId: themeId ?? this.themeId,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[soundOn, musicOn, hapticsOn, aimLineOn, themeId];
}
