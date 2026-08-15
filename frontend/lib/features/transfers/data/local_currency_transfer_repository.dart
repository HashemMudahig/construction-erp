import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/currency_transfers_dao.dart';
import '../../../core/database/daos/projects_dao.dart';
import '../../../core/database/finance/currency_conversion.dart';
import '../../../core/uuid/uuid_util.dart';
import '../data/currency_transfer_mapper.dart';
import '../domain/currency_transfer_entity.dart';
import '../domain/currency_transfer_repository_interface.dart';

/// Local (Drift/SQLite) implementation of
/// [CurrencyTransferRepositoryInterface].
///
/// A transfer moves funds between two currency wallets within the same
/// project. The canonical exchange rate is expressed as YER per 1 SAR
/// (scale-6 INTEGER), matching the rest of the system. The target amount is
/// computed from the source amount and the rate using exact integer
/// round-half-up arithmetic and stored as an immutable snapshot.
class LocalCurrencyTransferRepository
    implements CurrencyTransferRepositoryInterface {
  LocalCurrencyTransferRepository(this._dao, this._projectsDao);

  final CurrencyTransfersDao _dao;
  final ProjectsDao _projectsDao;

  @override
  Future<List<CurrencyTransferEntity>> listByProject(
      String projectId) async {
    UuidUtil.validate(projectId);
    final rows = await _dao.getActiveTransfersByProject(projectId);
    return rows.map(CurrencyTransferMapper.rowToEntity).toList();
  }

  @override
  Future<CurrencyTransferEntity?> getById(String id) async {
    UuidUtil.validate(id);
    final row = await _dao.getTransferById(id);
    if (row == null) return null;
    return CurrencyTransferMapper.rowToEntity(row);
  }

  @override
  Future<CurrencyTransferEntity> create({
    required String projectId,
    required String sourceCurrency,
    required String targetCurrency,
    required int sourceAmountMinor,
    int? targetAmountMinor,
    required int exchangeRateScaled,
    required String date,
    String? notes,
  }) async {
    UuidUtil.validate(projectId);
    _validateCurrency(sourceCurrency);
    _validateCurrency(targetCurrency);
    if (sourceCurrency == targetCurrency) {
      throw ArgumentError(
          'Source and target currencies must differ for a transfer');
    }
    if (sourceAmountMinor <= 0) {
      throw ArgumentError('Source amount must be positive');
    }
    if (exchangeRateScaled <= 0) {
      throw ArgumentError('Exchange rate must be positive');
    }
    _validateDate(date);

    final project = await _projectsDao.getProjectById(projectId);
    if (project == null) {
      throw ArgumentError('Project not found: $projectId');
    }

    final int computedTarget;
    if (sourceCurrency == kCurrencySar && targetCurrency == kCurrencyYer) {
      // SAR -> YER: direct conversion.
      computedTarget = convertToYer(
          sourceAmountMinor, kCurrencySar, exchangeRateScaled);
    } else if (sourceCurrency == kCurrencyYer && targetCurrency == kCurrencySar) {
      // YER -> SAR: inverse conversion using the same canonical rate.
      computedTarget = convertToCurrency(
          sourceAmountMinor, kCurrencyYer, kCurrencySar, exchangeRateScaled);
    } else {
      throw ArgumentError(
          'Unsupported transfer pair: $sourceCurrency -> $targetCurrency');
    }

    if (targetAmountMinor != null && targetAmountMinor != computedTarget) {
      throw ArgumentError(
        'Target amount ($targetAmountMinor) does not match calculation '
        '($computedTarget)',
      );
    }

    final id = UuidUtil.generate();
    final now = _utcNowIso();

    await _dao.insertTransfer(CurrencyTransferMapper.entityToInsertCompanion(
      id: id,
      projectId: projectId,
      sourceCurrency: sourceCurrency,
      targetCurrency: targetCurrency,
      sourceAmountMinor: sourceAmountMinor,
      targetAmountMinor: computedTarget,
      exchangeRateScaled: exchangeRateScaled,
      date: date,
      notes: notes,
      createdAt: now,
    ));

    final row = await _dao.getTransferById(id);
    return CurrencyTransferMapper.rowToEntity(row!);
  }

  @override
  Future<void> softDelete(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getTransferByIdIncludeDeleted(id);
    if (existing == null) {
      throw ArgumentError('Transfer not found: $id');
    }
    if (existing.isDeleted) return; // Idempotent
    await _dao.softDelete(id, _utcNowIso());
  }

  @override
  Future<void> restore(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getTransferByIdIncludeDeleted(id);
    if (existing == null) {
      throw ArgumentError('Transfer not found: $id');
    }
    if (!existing.isDeleted) return; // Idempotent
    await _dao.restore(id);
  }

  @override
  Future<int> countAllByProject(String projectId) async {
    UuidUtil.validate(projectId);
    return _dao.countAllByProject(projectId);
  }

  // ── Validation helpers ──

  void _validateCurrency(String currency) {
    if (!kSupportedCurrencies.contains(currency)) {
      throw ArgumentError('Unsupported currency: $currency');
    }
  }

  void _validateDate(String d) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d)) {
      throw ArgumentError('Invalid transfer date format: $d');
    }
    DateTime.parse('${d}T00:00:00');
  }

  String _utcNowIso() => DateTime.now().toUtc().toIso8601String();
}

/// Active runtime provider for the local currency transfer repository.
final localCurrencyTransferRepositoryProvider =
    Provider<CurrencyTransferRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalCurrencyTransferRepository(
    db.currencyTransfersDao,
    db.projectsDao,
  );
});