/// Expense domain entity with multi-currency snapshot fields and soft-delete.
///
/// Financial fields use scaled INTEGER (ADR-005):
/// - [originalAmountMinor]: in original currency minor units.
/// - [convertedYerAmount]: in YER minor units (scale 0).
/// - [exchangeRateScaled]: scale-6 INTEGER.
class ExpenseEntity {
  ExpenseEntity({
    required this.id,
    required this.projectId,
    this.expenseGroupId,
    required this.category,
    required this.originalAmountMinor,
    required this.originalCurrency,
    required this.exchangeRateScaled,
    required this.convertedYerAmount,
    this.rateSource = 'identity',
    this.rateDate,
    required this.expenseDate,
    this.notes,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String projectId;
  final String? expenseGroupId;
  final String category;
  final int originalAmountMinor;
  final String originalCurrency;
  final int exchangeRateScaled;
  final int convertedYerAmount;
  final String rateSource;
  final String? rateDate;
  final DateTime expenseDate;
  final String? notes;
  final DateTime createdAt;
  final bool isDeleted;
  final DateTime? deletedAt;
}
