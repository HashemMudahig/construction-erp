import 'package:drift/drift.dart';

import '../database_constants.dart';

/// Payments table — preserves verified Payment fields and adds multi-currency
/// snapshot fields per ADR-005.
///
/// Base fields match `backend/app/models/payment.py` and
/// `frontend/lib/features/payments/domain/payment_entity.dart`.
///
/// Multi-currency fields (new, per ADR-005):
/// - [originalAmountMinor]: payment amount in original currency minor units.
/// - [originalCurrency]: "YER" or "SAR".
/// - [exchangeRateScaled]: scale-6 INTEGER. Identity rate for YER.
/// - [convertedYerAmount]: converted amount in YER minor units (scale 0).
/// - [rateSource]: identity, default, project, or manual.
/// - [rateDate]: ISO date when the rate was applied.
///
/// [paymentGroupId] supports mixed-currency payments (multiple lines sharing
/// one business payment), per the accepted multi-currency contract.
@DataClassName('PaymentRow')
class Payments extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// FK to projects.id. ON DELETE RESTRICT (financial records must not be
  /// silently destroyed — see delete policy documentation).
  TextColumn get projectId =>
      text().withLength(min: 36, max: 36).customConstraint(
          'NOT NULL REFERENCES projects(id) ON DELETE RESTRICT')();

  /// Optional group ID for mixed-currency payment lines.
  /// Multiple payment rows sharing the same paymentGroupId represent one
  /// business payment in different currencies.
  TextColumn get paymentGroupId => text().nullable()();

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

  /// Payment date, ISO 8601 date-only (YYYY-MM-DD). Required.
  TextColumn get paymentDate => text()();

  /// Payment method: cash, bank_transfer, cheque, other.
  TextColumn get method => text()();

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
