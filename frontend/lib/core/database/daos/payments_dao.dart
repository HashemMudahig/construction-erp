import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/payments_table.dart';

part 'payments_dao.g.dart';

/// Data Access Object for the [Payments] table.
///
/// Used by [LocalPaymentRepository] — not accessed directly by screens.
@DriftAccessor(tables: [Payments])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Future<int> insertPayment(PaymentsCompanion payment) =>
      into(payments).insert(payment);

  /// Returns the active (non-deleted) payment, or null.
  Future<PaymentRow?> getPaymentById(String id) => (select(payments)
        ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
      .getSingleOrNull();

  /// Returns any payment by ID (including soft-deleted), for internal/audit use.
  Future<PaymentRow?> getPaymentByIdIncludeDeleted(String id) =>
      (select(payments)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// List active payments by project, ordered by payment date descending.
  Future<List<PaymentRow>> getActivePaymentsByProject(String projectId) =>
      (select(payments)
            ..where((t) =>
                t.projectId.equals(projectId) & t.isDeleted.equals(false))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.paymentDate, mode: OrderingMode.desc)
            ]))
          .get();

  /// All active (non-deleted) payments across all projects.
  Future<List<PaymentRow>> getAllActivePayments() => (select(payments)
        ..where((t) => t.isDeleted.equals(false)))
      .get();

  /// List all payments including soft-deleted by project (for audit/tests).
  Future<List<PaymentRow>> getAllPaymentsByProject(String projectId) =>
      (select(payments)
            ..where((t) => t.projectId.equals(projectId))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.paymentDate, mode: OrderingMode.desc)
            ]))
          .get();

  /// Get active payments by group ID.
  Future<List<PaymentRow>> getActivePaymentsByGroup(String groupId) =>
      (select(payments)
            ..where((t) =>
                t.paymentGroupId.equals(groupId) & t.isDeleted.equals(false)))
          .get();

  Future<bool> updatePayment(String id, PaymentsCompanion companion) =>
      (update(payments)..where((t) => t.id.equals(id)))
          .write(companion)
          .then((rows) => rows > 0);

  /// Soft-delete a single payment.
  Future<bool> softDelete(String id, String deletedAtIso) => (update(payments)
        ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
      .write(PaymentsCompanion(
          isDeleted: const Value(true), deletedAt: Value(deletedAtIso)))
      .then((rows) => rows > 0);

  /// Restore a soft-deleted payment.
  Future<bool> restore(String id) => (update(payments)
        ..where((t) => t.id.equals(id) & t.isDeleted.equals(true)))
      .write(const PaymentsCompanion(
          isDeleted: Value(false), deletedAt: Value(null)))
      .then((rows) => rows > 0);

  /// Soft-delete all active payments in a group.
  Future<int> softDeleteGroup(String groupId, String deletedAtIso) {
    return (update(payments)
          ..where((t) =>
              t.paymentGroupId.equals(groupId) & t.isDeleted.equals(false)))
        .write(PaymentsCompanion(
            isDeleted: const Value(true), deletedAt: Value(deletedAtIso)));
  }

  /// Restore all soft-deleted payments in a group.
  Future<int> restoreGroup(String groupId) {
    return (update(payments)
          ..where((t) =>
              t.paymentGroupId.equals(groupId) & t.isDeleted.equals(true)))
        .write(const PaymentsCompanion(
            isDeleted: Value(false), deletedAt: Value(null)));
  }

  /// Count all historical payments (including soft-deleted) for a project.
  Future<int> countAllByProject(String projectId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM payments WHERE project_id = ?',
      variables: [Variable.withString(projectId)],
      readsFrom: {payments},
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Sum of converted YER amounts for active payments of a project.
  Future<int> sumActivePaymentsYer(String projectId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(converted_yer_amount), 0) AS total FROM payments WHERE project_id = ? AND is_deleted = 0',
      variables: [Variable.withString(projectId)],
      readsFrom: {payments},
    ).getSingle();
    return result.read<int>('total');
  }

  /// Physical delete — only for isolated database tests, not exposed through repository.
  Future<int> deletePayment(String id) =>
      (delete(payments)..where((t) => t.id.equals(id))).go();
}
