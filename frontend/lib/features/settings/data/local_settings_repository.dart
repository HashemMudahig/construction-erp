import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/app_settings_dao.dart';
import '../../../core/database/finance/exchange_rate.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository_interface.dart';

typedef UtcNow = DateTime Function();

class LocalSettingsRepository implements SettingsRepositoryInterface {
  LocalSettingsRepository(
    this._dao, {
    UtcNow? utcNow,
  }) : _utcNow = utcNow ?? (() => DateTime.now().toUtc());

  final AppSettingsDao _dao;
  final UtcNow _utcNow;

  @override
  Future<AppSettingsEntity> loadSettings() async {
    await _seedDefaults();
    final row = await _dao.getSettings();
    if (row == null) {
      throw const SettingsValidationException(
          'Local settings are unavailable.');
    }
    final rate = row.defaultExchangeRateScaled;
    return AppSettingsEntity(
      defaultSarToYerRateScaled:
          rate != null && rate > 0 ? rate : kDefaultSarToYerRateScaled,
      localeCode: kSupportedLocaleCodes.contains(row.localeCode)
          ? row.localeCode
          : kDefaultLocaleCode,
    );
  }

  @override
  Future<AppSettingsEntity> updateDefaultSarToYerRate(String rate) async {
    final scaled = _parseRate(rate);
    await _seedDefaults();
    final updated = await _dao.updateSettings(
      'app',
      AppSettingsCompanion(
        defaultExchangeRateScaled: Value(scaled),
        updatedAt: Value(_timestamp()),
      ),
    );
    if (!updated) {
      throw const SettingsValidationException('Unable to save local settings.');
    }
    return loadSettings();
  }

  @override
  Future<AppSettingsEntity> updateLocale(String localeCode) async {
    if (!kSupportedLocaleCodes.contains(localeCode)) {
      throw SettingsValidationException('Unsupported locale: $localeCode');
    }
    await _seedDefaults();
    final updated = await _dao.updateSettings(
      'app',
      AppSettingsCompanion(
        localeCode: Value(localeCode),
        updatedAt: Value(_timestamp()),
      ),
    );
    if (!updated) {
      throw const SettingsValidationException('Unable to save local settings.');
    }
    return loadSettings();
  }

  int _parseRate(String value) {
    try {
      return toScaledExchangeRateFromString(value.trim());
    } catch (_) {
      throw const SettingsValidationException(
        'Enter a positive rate with at most 6 decimal places.',
      );
    }
  }

  Future<void> _seedDefaults() {
    final timestamp = _timestamp();
    return _dao.insertSettingsIfAbsent(AppSettingsCompanion.insert(
      id: 'app',
      defaultExchangeRateScaled: const Value(kDefaultSarToYerRateScaled),
      localeCode: const Value(kDefaultLocaleCode),
      createdAt: timestamp,
      updatedAt: timestamp,
    ));
  }

  String _timestamp() => _utcNow().toIso8601String();
}

final localSettingsRepositoryProvider =
    Provider<LocalSettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalSettingsRepository(db.appSettingsDao);
});
