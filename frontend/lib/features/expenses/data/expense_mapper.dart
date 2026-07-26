import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/expense_entity.dart';

/// Maps between Drift [ExpenseRow]/[ExpensesCompanion] and domain [ExpenseEntity].
class ExpenseMapper {
  ExpenseMapper._();

  static ExpenseEntity rowToEntity(ExpenseRow row) {
    return ExpenseEntity(
      id: row.id,
      projectId: row.projectId,
      expenseGroupId: row.expenseGroupId,
      category: row.category,
      originalAmountMinor: row.originalAmountMinor,
      originalCurrency: row.originalCurrency,
      exchangeRateScaled: row.exchangeRateScaled,
      convertedYerAmount: row.convertedYerAmount,
      rateSource: row.rateSource,
      rateDate: row.rateDate,
      expenseDate: DateTime.parse('${row.expenseDate}T00:00:00'),
      notes: row.notes,
      createdAt: DateTime.parse(row.createdAt),
      isDeleted: row.isDeleted,
      deletedAt: row.deletedAt != null ? DateTime.parse(row.deletedAt!) : null,
    );
  }

  static ExpensesCompanion entityToInsertCompanion({
    required String id,
    required String projectId,
    String? expenseGroupId,
    required String category,
    required int originalAmountMinor,
    required String originalCurrency,
    required int exchangeRateScaled,
    required int convertedYerAmount,
    String rateSource = 'identity',
    String? rateDate,
    required String expenseDate,
    String? notes,
    required String createdAt,
  }) {
    return ExpensesCompanion.insert(
      id: id,
      projectId: projectId,
      expenseGroupId: Value(expenseGroupId),
      category: category,
      originalAmountMinor: originalAmountMinor,
      originalCurrency: originalCurrency,
      exchangeRateScaled: exchangeRateScaled,
      convertedYerAmount: convertedYerAmount,
      rateSource: Value(rateSource),
      rateDate: Value(rateDate),
      expenseDate: expenseDate,
      notes: Value(notes),
      createdAt: createdAt,
      isDeleted: const Value(false),
      deletedAt: const Value.absent(),
    );
  }

  static ExpensesCompanion entityToUpdateCompanion({
    String? category,
    int? originalAmountMinor,
    String? originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String? rateSource,
    String? rateDate,
    String? expenseDate,
    String? notes,
  }) {
    return ExpensesCompanion(
      category: category != null ? Value(category) : const Value.absent(),
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
      expenseDate:
          expenseDate != null ? Value(expenseDate) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
    );
  }
}
