import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/currency_transfers_table.dart';

part 'currency_transfers_dao.g.dart';

/// Data Access Object for the [CurrencyTransfers] table.
///
/// Used by [LocalCurrencyTransferRepository] — not accessed directly by
/// screens.
@DriftAccessor(tables: [CurrencyTransfers])
class CurrencyTransfersDao extends DatabaseAccessor<AppDatabase>
    with _$CurrencyTransfersDaoMixin {
  CurrencyTransfersDao(super.db);

  Future<int> insertTransfer(CurrencyTransfersCompanion transfer) =>
      into(currencyTransfers).insert(transfer);

  /// Returns the active (non-deleted) transfer, or null.
  Future<CurrencyTransferRow?> getTransferById(String id) => (select(
        currencyTransfers,
      )..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
      .getSingleOrNull();

  /// Returns any transfer by ID (including soft-deleted), for audit use.
  Future<CurrencyTransferRow?> getTransferByIdIncludeDeleted(String id) =>
      (select(currencyTransfers)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// List active transfers by project, ordered by date descending.
  Future<List<CurrencyTransferRow>> getActiveTransfersByProject(
          String projectId) =>
      (select(currencyTransfers)
            ..where((t) =>
                t.projectId.equals(projectId) & t.isDeleted.equals(false))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.date, mode: OrderingMode.desc)
            ]))
          .get();

  /// All active (non-deleted) transfers across all projects.
  Future<List<CurrencyTransferRow>> getAllActiveTransfers() =>
      (select(currencyTransfers)
            ..where((t) => t.isDeleted.equals(false)))
          .get();

  /// List all transfers including soft-deleted by project (for audit/tests).
  Future<List<CurrencyTransferRow>> getAllTransfersByProject(
          String projectId) =>
      (select(currencyTransfers)
            ..where((t) => t.projectId.equals(projectId))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.date, mode: OrderingMode.desc)
            ]))
          .get();

  Future<bool> updateTransfer(String id, CurrencyTransfersCompanion companion) =>
      (update(currencyTransfers)..where((t) => t.id.equals(id)))
          .write(companion)
          .then((rows) => rows > 0);

  /// Soft-delete a single transfer.
  Future<bool> softDelete(String id, String deletedAtIso) =>
      (update(currencyTransfers)
            ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
          .write(CurrencyTransfersCompanion(
              isDeleted: const Value(true),
              deletedAt: Value(deletedAtIso)))
          .then((rows) => rows > 0);

  /// Restore a soft-deleted transfer.
  Future<bool> restore(String id) => (update(currencyTransfers)
        ..where((t) => t.id.equals(id) & t.isDeleted.equals(true)))
      .write(const CurrencyTransfersCompanion(
          isDeleted: Value(false), deletedAt: Value(null)))
      .then((rows) => rows > 0);

  /// Count all historical transfers (including soft-deleted) for a project.
  Future<int> countAllByProject(String projectId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM currency_transfers WHERE project_id = ?',
      variables: [Variable.withString(projectId)],
      readsFrom: {currencyTransfers},
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Sum of source amounts for active transfers of a project where the
  /// source currency matches [currency]. Represents debits from that
  /// currency's wallet.
  Future<int> sumSourceAmounts(String projectId, String currency) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(source_amount_minor), 0) AS total '
      'FROM currency_transfers WHERE project_id = ? AND source_currency = ? AND is_deleted = 0',
      variables: [Variable.withString(projectId), Variable.withString(currency)],
      readsFrom: {currencyTransfers},
    ).getSingle();
    return result.read<int>('total');
  }

  /// Sum of target amounts for active transfers of a project where the
  /// target currency matches [currency]. Represents credits to that
  /// currency's wallet.
  Future<int> sumTargetAmounts(String projectId, String currency) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(target_amount_minor), 0) AS total '
      'FROM currency_transfers WHERE project_id = ? AND target_currency = ? AND is_deleted = 0',
      variables: [Variable.withString(projectId), Variable.withString(currency)],
      readsFrom: {currencyTransfers},
    ).getSingle();
    return result.read<int>('total');
  }

  /// Physical delete — only for isolated database tests, not exposed through
  /// the repository.
  Future<int> deleteTransfer(String id) =>
      (delete(currencyTransfers)..where((t) => t.id.equals(id))).go();
}