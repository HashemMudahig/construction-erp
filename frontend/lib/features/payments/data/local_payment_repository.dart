import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/payments_dao.dart';
import '../../../core/database/daos/projects_dao.dart';
import '../../../core/database/finance/currency_conversion.dart';
import '../../../core/uuid/uuid_util.dart';
import '../../settings/data/local_settings_repository.dart';
import '../../settings/domain/settings_repository_interface.dart';
import '../domain/payment_entity.dart';
import '../domain/payment_repository_interface.dart';
import 'payment_mapper.dart';

/// Local (Drift/SQLite) implementation of [PaymentRepositoryInterface].
///
/// Supports multi-currency payments with immutable exchange-rate snapshots,
/// soft deletion, and payment groups for mixed-currency business payments.
class LocalPaymentRepository implements PaymentRepositoryInterface {
  LocalPaymentRepository(
    this._dao,
    this._projectsDao,
    this._db, [
    this._settings,
  ]);

  final PaymentsDao _dao;
  final ProjectsDao _projectsDao;
  final AppDatabase _db;
  final SettingsRepositoryInterface? _settings;

  @override
  Future<List<PaymentEntity>> listByProject(String projectId) async {
    UuidUtil.validate(projectId);
    final rows = await _dao.getActivePaymentsByProject(projectId);
    return rows.map(PaymentMapper.rowToEntity).toList();
  }

  @override
  Future<PaymentEntity?> getById(String id) async {
    UuidUtil.validate(id);
    final row = await _dao.getPaymentById(id);
    if (row == null) return null;
    return PaymentMapper.rowToEntity(row);
  }

  @override
  Future<PaymentEntity> create({
    required String projectId,
    String? paymentGroupId,
    required int originalAmountMinor,
    required String originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String rateSource = 'identity',
    String? rateDate,
    required String paymentDate,
    required String method,
    String? notes,
  }) async {
    UuidUtil.validate(projectId);
    // paymentGroupId is a business grouping identifier, not necessarily a UUID format
    _validateAmount(originalAmountMinor);
    _validateCurrency(originalCurrency);
    _validateMethod(method);
    _validatePaymentDate(paymentDate);

    // Verify project exists
    final project = await _projectsDao.getProjectById(projectId);
    if (project == null) {
      throw ArgumentError('Project not found: $projectId');
    }

    // The stored converted YER amount is always the YER-equivalent of the
    // original amount (an immutable snapshot for dashboard/reports). A rate
    // is required whenever the original currency is SAR (to compute the YER
    // equivalent), regardless of the contract currency. When the payment
    // currency matches the contract currency the *user* does not need to
    // enter a rate (the project fixed rate or settings default is used), but
    // a rate is still resolved internally for the YER snapshot. Contract-
    // currency aggregation is performed on read via convertToCurrency, so
    // historical rates are preserved.
    final contractCurrency = project.budgetCurrency;
    final isCrossCurrency = originalCurrency != contractCurrency;
    int finalRate;
    int finalConverted;
    String finalRateSource;

    if (originalCurrency == kCurrencyYer) {
      // YER original: the YER snapshot is identity. If the contract currency
      // is SAR, the user must provide a YER/SAR rate so the contract-currency
      // aggregation can convert YER→SAR on read; store that rate.
      if (isCrossCurrency) {
        if (exchangeRateScaled == null || exchangeRateScaled <= 0) {
          if (project.exchangePolicy == kExchangePolicyFixed &&
              project.fixedExchangeRateScaled != null &&
              project.fixedExchangeRateScaled! > 0) {
            finalRate = project.fixedExchangeRateScaled!;
            finalRateSource = kRateSourceProject;
          } else if (_settings != null) {
            finalRate =
                (await _settings.loadSettings()).defaultSarToYerRateScaled;
            finalRateSource = kRateSourceDefault;
          } else {
            throw ArgumentError(
              'Cross-currency payment requires a positive exchange rate',
            );
          }
        } else {
          finalRate = exchangeRateScaled;
          finalRateSource = rateSource;
        }
        rateDate ??= paymentDate;
      } else {
        finalRate = kIdentityExchangeRate;
        finalRateSource = kRateSourceIdentity;
        rateDate = null;
      }
      finalConverted = originalAmountMinor;
    } else {
      // SAR — need exchange rate for the YER snapshot.
      if (exchangeRateScaled == null || exchangeRateScaled <= 0) {
        // Use project fixed rate if available
        if (project.exchangePolicy == kExchangePolicyFixed &&
            project.fixedExchangeRateScaled != null &&
            project.fixedExchangeRateScaled! > 0) {
          finalRate = project.fixedExchangeRateScaled!;
          finalRateSource = kRateSourceProject;
        } else if (_settings != null) {
          finalRate =
              (await _settings.loadSettings()).defaultSarToYerRateScaled;
          finalRateSource = kRateSourceDefault;
        } else {
          throw ArgumentError(
            'SAR payment requires a positive exchange rate',
          );
        }
      } else {
        finalRate = exchangeRateScaled;
        finalRateSource = rateSource;
      }
      finalConverted =
          convertToYer(originalAmountMinor, kCurrencySar, finalRate);
      if (convertedYerAmount != null && convertedYerAmount != finalConverted) {
        throw ArgumentError(
          'Converted YER amount ($convertedYerAmount) does not match calculation ($finalConverted)',
        );
      }
      rateDate ??= paymentDate;
    }

    final id = UuidUtil.generate();
    final now = _utcNowIso();

    await _dao.insertPayment(PaymentMapper.entityToInsertCompanion(
      id: id,
      projectId: projectId,
      paymentGroupId: paymentGroupId,
      originalAmountMinor: originalAmountMinor,
      originalCurrency: originalCurrency,
      exchangeRateScaled: finalRate,
      convertedYerAmount: finalConverted,
      rateSource: finalRateSource,
      rateDate: rateDate,
      paymentDate: paymentDate,
      method: method,
      notes: notes,
      createdAt: now,
    ));

    final row = await _dao.getPaymentById(id);
    return PaymentMapper.rowToEntity(row!);
  }

  @override
  Future<PaymentEntity> update({
    required String id,
    int? originalAmountMinor,
    String? originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String? rateSource,
    String? rateDate,
    String? paymentDate,
    String? method,
    String? notes,
  }) async {
    UuidUtil.validate(id);

    final existing = await _dao.getPaymentById(id);
    if (existing == null) {
      throw ArgumentError('Payment not found: $id');
    }

    if (originalAmountMinor != null) _validateAmount(originalAmountMinor);
    if (originalCurrency != null) _validateCurrency(originalCurrency);
    if (method != null) _validateMethod(method);
    if (paymentDate != null) _validatePaymentDate(paymentDate);

    // If amount, currency, or rate changed, recalculate the converted YER
    // snapshot. A rate is required for SAR rows (for the YER snapshot);
    // YER rows use identity. Contract-currency aggregation is performed on
    // read via convertToCurrency, so historical rates are preserved.
    int? finalConverted;
    int? finalRate;
    String? finalRateSource;
    String? finalRateDate;

    final effectiveCurrency = originalCurrency ?? existing.originalCurrency;
    final effectiveAmount =
        originalAmountMinor ?? existing.originalAmountMinor;

    if (effectiveCurrency == kCurrencyYer) {
      finalRate = kIdentityExchangeRate;
      finalConverted = effectiveAmount;
      finalRateSource = kRateSourceIdentity;
      finalRateDate = null;
    } else if (originalAmountMinor != null ||
        exchangeRateScaled != null ||
        originalCurrency != null) {
      finalRate = exchangeRateScaled ?? existing.exchangeRateScaled;
      if (finalRate <= 0) {
        throw ArgumentError('SAR payment requires positive exchange rate');
      }
      finalConverted = convertToYer(effectiveAmount, kCurrencySar, finalRate);
      finalRateSource = rateSource ?? existing.rateSource;
      finalRateDate = rateDate ??
          existing.rateDate ??
          (paymentDate ?? existing.paymentDate);
    }

    await _dao.updatePayment(
      id,
      PaymentMapper.entityToUpdateCompanion(
        originalAmountMinor: originalAmountMinor,
        originalCurrency: originalCurrency,
        exchangeRateScaled: finalRate,
        convertedYerAmount: finalConverted,
        rateSource: finalRateSource,
        rateDate: finalRateDate,
        paymentDate: paymentDate,
        method: method,
        notes: notes,
      ),
    );

    final row = await _dao.getPaymentById(id);
    return PaymentMapper.rowToEntity(row!);
  }

  @override
  Future<void> softDelete(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getPaymentByIdIncludeDeleted(id);
    if (existing == null) {
      throw ArgumentError('Payment not found: $id');
    }
    if (existing.isDeleted) return; // Idempotent
    await _dao.softDelete(id, _utcNowIso());
  }

  @override
  Future<void> restore(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getPaymentByIdIncludeDeleted(id);
    if (existing == null) {
      throw ArgumentError('Payment not found: $id');
    }
    if (!existing.isDeleted) return; // Idempotent
    await _dao.restore(id);
  }

  @override
  Future<void> softDeleteGroup(String groupId) async {
    if (groupId.isEmpty) throw ArgumentError('Group ID cannot be empty');
    await _db.transaction(() async {
      await _dao.softDeleteGroup(groupId, _utcNowIso());
    });
  }

  @override
  Future<void> restoreGroup(String groupId) async {
    if (groupId.isEmpty) throw ArgumentError('Group ID cannot be empty');
    await _db.transaction(() async {
      await _dao.restoreGroup(groupId);
    });
  }

  @override
  Future<int> totalActivePaymentsYer(String projectId) async {
    UuidUtil.validate(projectId);
    return _dao.sumActivePaymentsYer(projectId);
  }

  @override
  Future<int> countAllByProject(String projectId) async {
    UuidUtil.validate(projectId);
    return _dao.countAllByProject(projectId);
  }

  // ── Validation helpers ──

  void _validateAmount(int amount) {
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be positive');
    }
  }

  void _validateCurrency(String currency) {
    if (!kSupportedCurrencies.contains(currency)) {
      throw ArgumentError('Unsupported currency: $currency');
    }
  }

  void _validateMethod(String method) {
    if (!kPaymentMethods.contains(method)) {
      throw ArgumentError('Invalid payment method: $method');
    }
  }

  void _validatePaymentDate(String date) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw ArgumentError('Invalid payment date format: $date');
    }
    DateTime.parse('${date}T00:00:00');
  }

  String _utcNowIso() => DateTime.now().toUtc().toIso8601String();
}

/// Active runtime provider for the local payment repository.
final localPaymentRepositoryProvider =
    Provider<PaymentRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalPaymentRepository(
    db.paymentsDao,
    db.projectsDao,
    db,
    ref.watch(localSettingsRepositoryProvider),
  );
});
