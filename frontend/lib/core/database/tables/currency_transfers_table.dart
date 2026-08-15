import 'package:drift/drift.dart';

/// Currency transfers table — permanent record of currency conversion
/// operations performed inside a project wallet.
///
/// A transfer moves funds from one currency wallet to another within the
/// same project. The source currency wallet is debited [sourceAmountMinor]
/// and the target currency wallet is credited [targetAmountMinor] using the
/// immutable [exchangeRateScaled] snapshot captured at transfer time.
///
/// Fields:
/// - [id]: UUID v4 primary key.
/// - [projectId]: FK to projects.id (ON DELETE RESTRICT).
/// - [sourceCurrency]: currency code debited ("YER" or "SAR").
/// - [targetCurrency]: currency code credited ("YER" or "SAR").
/// - [sourceAmountMinor]: amount debited from the source wallet, in source
///   currency minor units.
/// - [targetAmountMinor]: amount credited to the target wallet, in target
///   currency minor units.
/// - [exchangeRateScaled]: scale-6 INTEGER rate used for the conversion
///   (expressed as YER per 1 SAR, the project-wide canonical rate). When the
///   source is SAR and target is YER this is the direct rate; when source is
///   YER and target is SAR this is the same canonical rate used inversely.
/// - [date]: ISO 8601 date-only (YYYY-MM-DD). Required.
/// - [notes]: optional notes.
/// - [createdAt]: creation timestamp, ISO 8601 UTC string.
/// - [isDeleted]: soft-delete flag. Defaults to false.
/// - [deletedAt]: soft-delete timestamp. Null when not deleted.
@DataClassName('CurrencyTransferRow')
class CurrencyTransfers extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// FK to projects.id. ON DELETE RESTRICT.
  TextColumn get projectId => text()
      .withLength(min: 36, max: 36)
      .customConstraint('NOT NULL REFERENCES projects(id) ON DELETE RESTRICT')();

  /// Currency code debited ("YER" or "SAR").
  TextColumn get sourceCurrency => text().withLength(min: 3, max: 3)();

  /// Currency code credited ("YER" or "SAR").
  TextColumn get targetCurrency => text().withLength(min: 3, max: 3)();

  /// Amount debited from the source wallet, in source currency minor units.
  IntColumn get sourceAmountMinor => integer()();

  /// Amount credited to the target wallet, in target currency minor units.
  IntColumn get targetAmountMinor => integer()();

  /// Exchange rate applied (scale-6 INTEGER). Immutable snapshot.
  IntColumn get exchangeRateScaled => integer()();

  /// Transfer date, ISO 8601 date-only (YYYY-MM-DD). Required.
  TextColumn get date => text()();

  /// Optional notes.
  TextColumn get notes => text().nullable()();

  /// Creation timestamp, ISO 8601 UTC string.
  TextColumn get createdAt => text()();

  /// Soft-delete flag. false = active, true = deleted. Defaults to false.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Soft-delete timestamp, ISO 8601 UTC string. Null when not deleted.
  TextColumn get deletedAt => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {id},
      ];
}