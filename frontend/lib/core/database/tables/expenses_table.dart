import 'package:drift/drift.dart';

import '../database_constants.dart';

/// Expenses table — preserves verified Expense fields and adds multi-currency
/// snapshot fields per ADR-005.
///
/// Base fields match `backend/app/models/expense.py` and
/// `frontend/lib/features/expenses/domain/expense_entity.dart`.
///
/// Multi-currency fields (new, per ADR-005):
/// - [originalAmountMinor]: expense amount in original currency minor units.
/// - [originalCurrency]: "YER" or "SAR".
/// - [exchangeRateScaled]: scale-6 INTEGER. Identity rate for YER.
/// - [convertedYerAmount]: converted amount in YER minor units (scale 0).
/// - [rateSource]: identity, default, project, or manual.
/// - [rateDate]: ISO date when the rate was applied.
///
/// [expenseGroupId] supports mixed-currency expenses (peer lines belonging to
/// one business expense), per the accepted multi-currency contract. This is a
/// peer-grouping model, not a parent-child hierarchy.
@DataClassName('ExpenseRow')
class Expenses extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// FK to projects.id. ON DELETE RESTRICT (financial records must not be
  /// silently destroyed — see delete policy documentation).
  TextColumn get projectId =>
      text().withLength(min: 36, max: 36).customConstraint(
          'NOT NULL REFERENCES projects(id) ON DELETE RESTRICT')();

  /// Optional group ID for mixed-currency expense lines.
  /// Multiple expense rows sharing the same expenseGroupId represent one
  /// business expense in different currencies. This is a peer grouping, not
  /// a parent-child hierarchy.
  TextColumn get expenseGroupId => text().nullable()();

  /// Original amount in minor units (scaled INTEGER per originalCurrency).
  IntColumn get originalAmountMinor => integer()();

  /// Original currency code: "YER" or "SAR".
  TextColumn get originalCurrency => text().withLength(min: 3, max: 3)();

  /// Exchange rate applied (scale-6 INTEGER). Identity rate (1,000,000) for YER.
  IntColumn get exchangeRateScaled => integer()();

  /// Converted YER amount in minor units (scale 0).
  IntColumn get convertedYerAmount => integer()();

  /// Rate source: identity, default, project, or manual.
  TextColumn get rateSource =>
      text().withDefault(const Constant(kRateSourceIdentity))();

  /// Date the rate was applied, ISO 8601 date-only (YYYY-MM-DD). Nullable for YER.
  TextColumn get rateDate => text().nullable()();

  /// Expense category: materials, labor, equipment, permits, other.
  TextColumn get category => text()();

  /// Expense date, ISO 8601 date-only (YYYY-MM-DD). Required.
  TextColumn get expenseDate => text()();

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
