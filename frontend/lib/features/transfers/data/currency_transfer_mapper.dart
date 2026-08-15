import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';
import '../domain/currency_transfer_entity.dart';

/// Maps between [CurrencyTransferRow] (Drift) and [CurrencyTransferEntity]
/// (domain).
class CurrencyTransferMapper {
  CurrencyTransferMapper._();

  static CurrencyTransferEntity rowToEntity(CurrencyTransferRow row) {
    return CurrencyTransferEntity(
      id: row.id,
      projectId: row.projectId,
      sourceCurrency: row.sourceCurrency,
      targetCurrency: row.targetCurrency,
      sourceAmountMinor: row.sourceAmountMinor,
      targetAmountMinor: row.targetAmountMinor,
      exchangeRateScaled: row.exchangeRateScaled,
      date: DateTime.parse('${row.date}T00:00:00'),
      notes: row.notes,
      createdAt: DateTime.parse(row.createdAt),
      isDeleted: row.isDeleted,
      deletedAt:
          row.deletedAt == null ? null : DateTime.parse(row.deletedAt!),
    );
  }

  static CurrencyTransfersCompanion entityToInsertCompanion({
    required String id,
    required String projectId,
    required String sourceCurrency,
    required String targetCurrency,
    required int sourceAmountMinor,
    required int targetAmountMinor,
    required int exchangeRateScaled,
    required String date,
    String? notes,
    required String createdAt,
  }) {
    return CurrencyTransfersCompanion.insert(
      id: id,
      projectId: projectId,
      sourceCurrency: sourceCurrency,
      targetCurrency: targetCurrency,
      sourceAmountMinor: sourceAmountMinor,
      targetAmountMinor: targetAmountMinor,
      exchangeRateScaled: exchangeRateScaled,
      date: date,
      notes: Value(notes),
      createdAt: createdAt,
    );
  }
}