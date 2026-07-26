import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/payment_entity.dart';

/// Maps between Drift [PaymentRow]/[PaymentsCompanion] and domain [PaymentEntity].
class PaymentMapper {
  PaymentMapper._();

  static PaymentEntity rowToEntity(PaymentRow row) {
    return PaymentEntity(
      id: row.id,
      projectId: row.projectId,
      paymentGroupId: row.paymentGroupId,
      originalAmountMinor: row.originalAmountMinor,
      originalCurrency: row.originalCurrency,
      exchangeRateScaled: row.exchangeRateScaled,
      convertedYerAmount: row.convertedYerAmount,
      rateSource: row.rateSource,
      rateDate: row.rateDate,
      paymentDate: DateTime.parse('${row.paymentDate}T00:00:00'),
      method: row.method,
      notes: row.notes,
      createdAt: DateTime.parse(row.createdAt),
      isDeleted: row.isDeleted,
      deletedAt: row.deletedAt != null ? DateTime.parse(row.deletedAt!) : null,
    );
  }

  static PaymentsCompanion entityToInsertCompanion({
    required String id,
    required String projectId,
    String? paymentGroupId,
    required int originalAmountMinor,
    required String originalCurrency,
    required int exchangeRateScaled,
    required int convertedYerAmount,
    String rateSource = 'identity',
    String? rateDate,
    required String paymentDate,
    required String method,
    String? notes,
    required String createdAt,
  }) {
    return PaymentsCompanion.insert(
      id: id,
      projectId: projectId,
      paymentGroupId: Value(paymentGroupId),
      originalAmountMinor: originalAmountMinor,
      originalCurrency: originalCurrency,
      exchangeRateScaled: exchangeRateScaled,
      convertedYerAmount: convertedYerAmount,
      rateSource: Value(rateSource),
      rateDate: Value(rateDate),
      paymentDate: paymentDate,
      method: method,
      notes: Value(notes),
      createdAt: createdAt,
      isDeleted: const Value(false),
      deletedAt: const Value.absent(),
    );
  }

  static PaymentsCompanion entityToUpdateCompanion({
    int? originalAmountMinor,
    String? originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String? rateSource,
    String? rateDate,
    String? paymentDate,
    String? method,
    String? notes,
  }) {
    return PaymentsCompanion(
      originalAmountMinor: originalAmountMinor != null
          ? Value(originalAmountMinor)
          : const Value.absent(),
      originalCurrency: originalCurrency != null
          ? Value(originalCurrency)
          : const Value.absent(),
      exchangeRateScaled: exchangeRateScaled != null
          ? Value(exchangeRateScaled)
          : const Value.absent(),
      convertedYerAmount: convertedYerAmount != null
          ? Value(convertedYerAmount)
          : const Value.absent(),
      rateSource: rateSource != null ? Value(rateSource) : const Value.absent(),
      rateDate: rateDate != null ? Value(rateDate) : const Value.absent(),
      paymentDate:
          paymentDate != null ? Value(paymentDate) : const Value.absent(),
      method: method != null ? Value(method) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
    );
  }
}
