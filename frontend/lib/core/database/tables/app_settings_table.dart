import 'package:drift/drift.dart';

import '../database_constants.dart';

/// Application settings table — minimal single-row configuration.
///
/// Stores the default SAR-to-YER exchange rate used as a suggested value
/// when entering new transactions. Changing this value does NOT affect
/// historical transaction snapshots (ADR-005).
///
/// This table is not connected to any UI during Phase 02.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  /// Singleton row identifier. Always "app" for the single settings row.
  TextColumn get id => text().withLength(min: 1, max: 10)();

  /// Default SAR-to-YER exchange rate (scale-6 INTEGER).
  /// Used only as a suggested value for new transactions.
  IntColumn get defaultExchangeRateScaled => integer().nullable()();

  /// Canonical application locale. Only "en" and "ar" are supported.
  TextColumn get localeCode =>
      text().withDefault(const Constant(kDefaultLocaleCode))();

  /// Creation timestamp, ISO 8601 UTC string.
  TextColumn get createdAt => text()();

  /// Last update timestamp, ISO 8601 UTC string.
  TextColumn get updatedAt => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {id},
      ];
}
