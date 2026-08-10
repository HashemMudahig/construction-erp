import 'package:drift/drift.dart';

import '../database_constants.dart';

/// Projects table — preserves verified Project fields and adds multi-currency
/// support per ADR-005.
///
/// Base fields match `backend/app/models/project.py` and
/// `frontend/lib/features/projects/domain/project_entity.dart`.
///
/// Multi-currency fields (new, per ADR-005):
/// - [budgetAmountMinor]: budget stored as scaled INTEGER.
/// - [budgetCurrency]: currency code for the budget ("YER" or "SAR").
/// - [exchangePolicy]: "fixed" or "per_transaction".
/// - [fixedExchangeRateScaled]: scale-6 INTEGER, required when policy=fixed
///   and currency is non-YER; NULL otherwise.
@DataClassName('ProjectRow')
class Projects extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// FK to clients.id. ON DELETE RESTRICT (safe: prevents losing project history).
  TextColumn get clientId => text()
      .withLength(min: 36, max: 36)
      .customConstraint('NOT NULL REFERENCES clients(id) ON DELETE RESTRICT')();

  /// Project display name. Required, max 200 chars.
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Optional project description.
  TextColumn get description => text().nullable()();

  /// Budget amount in minor units (scaled INTEGER per budget_currency).
  /// ADR-005: never REAL. YER scale 0, SAR scale 2.
  ///
  /// Represents the **current** contract value after any amendments.
  IntColumn get budgetAmountMinor => integer()();

  /// Original contract value in minor units, captured at creation time and
  /// never overwritten by direct edits or amendments. Used to preserve the
  /// original agreed value while [budgetAmountMinor] reflects the current
  /// (possibly amended) value. Equal to [budgetAmountMinor] on creation.
  IntColumn get originalContractValueMinor => integer().withDefault(
        const Constant(0),
      )();

  /// Currency code for budget: "YER" or "SAR".
  TextColumn get budgetCurrency => text().withLength(min: 3, max: 3)();

  /// Exchange policy: "fixed" or "per_transaction".
  TextColumn get exchangePolicy =>
      text().withDefault(const Constant(kExchangePolicyPerTransaction))();

  /// Fixed exchange rate (scale-6 INTEGER). Required when policy=fixed and
  /// currency is non-YER. NULL when policy=per_transaction or currency=YER.
  IntColumn get fixedExchangeRateScaled => integer().nullable()();

  /// Optional start date, ISO 8601 date-only (YYYY-MM-DD).
  TextColumn get startDate => text().nullable()();

  /// Optional end date, ISO 8601 date-only (YYYY-MM-DD).
  TextColumn get endDate => text().nullable()();

  /// Project status: planning, active, completed, on_hold, cancelled.
  TextColumn get status => text().withDefault(const Constant('planning'))();

  /// Creation timestamp, ISO 8601 UTC string.
  TextColumn get createdAt => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {id},
      ];
}
