import 'expense_entity.dart';

/// Contract for expense data access operations.
abstract class ExpenseRepositoryInterface {
  /// Lists active (non-deleted) expenses for the given [projectId].
  Future<List<ExpenseEntity>> listByProject(String projectId);

  /// Returns the active expense with the given [id], or null.
  Future<ExpenseEntity?> getById(String id);

  /// Creates a single expense. Returns the created entity.
  Future<ExpenseEntity> create({
    required String projectId,
    String? expenseGroupId,
    required String category,
    required int originalAmountMinor,
    required String originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String rateSource = 'identity',
    String? rateDate,
    required String expenseDate,
    String? notes,
  });

  /// Updates an expense. Only non-null fields are updated.
  Future<ExpenseEntity> update({
    required String id,
    String? category,
    int? originalAmountMinor,
    String? originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String? rateSource,
    String? rateDate,
    String? expenseDate,
    String? notes,
  });

  /// Soft-deletes an expense.
  Future<void> softDelete(String id);

  /// Restores a soft-deleted expense.
  Future<void> restore(String id);

  /// Soft-deletes all active expenses in a group atomically.
  Future<void> softDeleteGroup(String groupId);

  /// Restores all soft-deleted expenses in a group atomically.
  Future<void> restoreGroup(String groupId);

  /// Returns the sum of converted YER amounts for active expenses of [projectId].
  Future<int> totalActiveExpensesYer(String projectId);

  /// Returns the count of all expenses (including soft-deleted) for [projectId].
  Future<int> countAllByProject(String projectId);
}
