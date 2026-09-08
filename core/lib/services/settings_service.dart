import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// Настройки приложения. Текущее значение лежит в [settings]
/// (`ValueListenableBuilder` в меню, паузе и на экране настроек),
/// изменения сохраняются через [SettingsRepository]. `AudioService`
/// подписан на нотифаер и сам включает/выключает музыку; движок читает
/// `aimLineOn` напрямую из нотифаера.
class SettingsService {
  final SettingsRepository _repository;

  final ValueNotifier<SettingsModel> settings =
      ValueNotifier<SettingsModel>(const SettingsModel.empty());

  SettingsService(this._repository);

  SettingsModel get value => settings.value;

  Future<void> init() async {
    settings.value = await _repository.getSettings();
  }

  Future<void> setSoundOn(bool value) =>
      _update(settings.value.copyWith(soundOn: value));

  Future<void> setMusicOn(bool value) =>
      _update(settings.value.copyWith(musicOn: value));

  Future<void> setHapticsOn(bool value) =>
      _update(settings.value.copyWith(hapticsOn: value));

  Future<void> setAimLineOn(bool value) =>
      _update(settings.value.copyWith(aimLineOn: value));

  Future<void> setThemeId(String id) =>
      _update(settings.value.copyWith(themeId: id));

  Future<void> _update(SettingsModel next) async {
    if (next == settings.value) return;
    settings.value = next;
    await _repository.saveSettings(next);
  }
}
