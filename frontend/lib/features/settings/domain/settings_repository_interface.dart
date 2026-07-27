import 'app_settings.dart';

abstract interface class SettingsRepositoryInterface {
  Future<AppSettingsEntity> loadSettings();

  Future<AppSettingsEntity> updateDefaultSarToYerRate(String rate);

  Future<AppSettingsEntity> updateLocale(String localeCode);
}
