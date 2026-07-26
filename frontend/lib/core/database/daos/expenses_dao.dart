import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/expenses_table.dart';

part 'expenses_dao.g.dart';

/// Data Access Object for the [Expenses] table.
///
/// Used by [LocalExpenseRepository] — not accessed directly by screens.
@DriftAccessor(tables: [Expenses])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Future<int> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);

  /// Returns the active (non-deleted) expense, or null.
  Future<ExpenseRow?> getExpenseById(String id) => (select(expenses)
        ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
      .getSingleOrNull();

  /// Returns any expense by ID (including soft-deleted), for internal/audit use.
  Future<ExpenseRow?> getExpenseByIdIncludeDeleted(String id) =>
      (select(expenses)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// List active expenses by project, ordered by expense date descending.
  Future<List<ExpenseRow>> getActiveExpensesByProject(String projectId) =>
      (select(expenses)
            ..where((t) =>
                t.projectId.equals(projectId) & t.isDeleted.equals(false))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.expenseDate, mode: OrderingMode.desc)
            ]))
          .get();

  /// List all expenses including soft-deleted by project (for audit/tests).
  Future<List<ExpenseRow>> getAllExpensesByProject(String projectId) =>
      (select(expenses)
            ..where((t) => t.projectId.equals(projectId))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.expenseDate, mode: OrderingMode.desc)
            ]))
          .get();

  /// Get active expenses by group ID.
  Future<List<ExpenseRow>> getActiveExpensesByGroup(String groupId) =>
      (select(expenses)
            ..where((t) =>
                t.expenseGroupId.equals(groupId) & t.isDeleted.equals(false)))
          .get();

  Future<bool> updateExpense(String id, ExpensesCompanion companion) =>
      (update(expenses)..where((t) => t.id.equals(id)))
          .write(companion)
          .then((rows) => rows > 0);

  /// Soft-delete a single expense.
  Future<bool> softDelete(String id, String deletedAtIso) => (update(expenses)
        ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
      .write(ExpensesCompanion(
          isDeleted: const Value(true), deletedAt: Value(deletedAtIso)))
      .then((rows) => rows > 0);

  /// Restore a soft-deleted expense.
  Future<bool> restore(String id) => (update(expenses)
        ..where((t) => t.id.equals(id) & t.isDeleted.equals(true)))
      .write(const ExpensesCompanion(
          isDeleted: Value(false), deletedAt: Value(null)))
      .then((rows) => rows > 0);

  /// Soft-delete all active expenses in a group.
  Future<int> softDeleteGroup(String groupId, String deletedAtIso) {
    return (update(expenses)
          ..where((t) =>
              t.expenseGroupId.equals(groupId) & t.isDeleted.equals(false)))
        .write(ExpensesCompanion(
            isDeleted: const Value(true), deletedAt: Value(deletedAtIso)));
  }

  /// Restore all soft-deleted expenses in a group.
  Future<int> restoreGroup(String groupId) {
    return (update(expenses)
          ..where((t) =>
              t.expenseGroupId.equals(groupId) & t.isDeleted.equals(true)))
        .write(const ExpensesCompanion(
            isDeleted: Value(false), deletedAt: Value(null)));
  }

  /// Count all historical expenses (including soft-deleted) for a project.
  Future<int> countAllByProject(String projectId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM expenses WHERE project_id = ?',
      variables: [Variable.withString(projectId)],
      readsFrom: {expenses},
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Sum of converted YER amounts for active expenses of a project.
  Future<int> sumActiveExpensesYer(String projectId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(converted_yer_amount), 0) AS total FROM expenses WHERE project_id = ? AND is_deleted = 0',
      variables: [Variable.withString(projectId)],
      readsFrom: {expenses},
    ).getSingle();
    return result.read<int>('total');
  }

  /// Physical delete — only for isolated database tests, not exposed through repository.
  Future<int> deleteExpense(String id) =>
      (delete(expenses)..where((t) => t.id.equals(id))).go();
}
