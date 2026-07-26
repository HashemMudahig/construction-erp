import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'app_settings_dao.g.dart';

/// Data Access Object for the [AppSettings] table.
@DriftAccessor(tables: [AppSettings])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  Future<int> insertSettings(AppSettingsCompanion settings) =>
      into(appSettings).insert(settings);

  Future<AppSettingRow?> getSettings() =>
      (select(appSettings)..limit(1)).getSingleOrNull();

  Future<bool> updateSettings(String id, AppSettingsCompanion companion) =>
      (update(appSettings)..where((t) => t.id.equals(id)))
          .write(companion)
          .then((rows) => rows > 0);
}
