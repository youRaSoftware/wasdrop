import 'package:domain/domain.dart';

import '../providers/local/settings_hive_provider.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsHiveProvider _provider;

  SettingsRepositoryImpl(this._provider);

  @override
  Future<SettingsModel> getSettings() async {
    return SettingsModel(
      soundOn: _provider.soundOn,
      musicOn: _provider.musicOn,
      hapticsOn: _provider.hapticsOn,
      aimLineOn: _provider.aimLineOn,
      themeId: _provider.themeId ?? SettingsModel.defaultThemeId,
      localeCode: _provider.localeCode,
    );
  }

  @override
  Future<void> saveSettings(SettingsModel settings) {
    return _provider.save(
      soundOn: settings.soundOn,
      musicOn: settings.musicOn,
      hapticsOn: settings.hapticsOn,
      aimLineOn: settings.aimLineOn,
      themeId: settings.themeId,
      localeCode: settings.localeCode,
    );
  }
}
