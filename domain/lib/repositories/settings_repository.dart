import '../models/settings_model.dart';

abstract interface class SettingsRepository {
  Future<SettingsModel> getSettings();
  Future<void> saveSettings(SettingsModel settings);
}
