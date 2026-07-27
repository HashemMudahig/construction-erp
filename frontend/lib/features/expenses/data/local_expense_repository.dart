import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/expenses_dao.dart';
import '../../../core/database/daos/projects_dao.dart';
import '../../../core/database/finance/currency_conversion.dart';
import '../../../core/uuid/uuid_util.dart';
import '../../settings/data/local_settings_repository.dart';
import '../../settings/domain/settings_repository_interface.dart';
import '../domain/expense_entity.dart';
import '../domain/expense_repository_interface.dart';
import 'expense_mapper.dart';

/// Local (Drift/SQLite) implementation of [ExpenseRepositoryInterface].
class LocalExpenseRepository implements ExpenseRepositoryInterface {
  LocalExpenseRepository(
    this._dao,
    this._projectsDao,
    this._db, [
    this._settings,
  ]);

  final ExpensesDao _dao;
  final ProjectsDao _projectsDao;
  final AppDatabase _db;
  final SettingsRepositoryInterface? _settings;

  @override
  Future<List<ExpenseEntity>> listByProject(String projectId) async {
    UuidUtil.validate(projectId);
    final rows = await _dao.getActiveExpensesByProject(projectId);
    return rows.map(ExpenseMapper.rowToEntity).toList();
  }

  @override
  Future<ExpenseEntity?> getById(String id) async {
    UuidUtil.validate(id);
    final row = await _dao.getExpenseById(id);
    if (row == null) return null;
    return ExpenseMapper.rowToEntity(row);
  }

  @override
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
  }) async {
    UuidUtil.validate(projectId);
    _validateAmount(originalAmountMinor);
    _validateCurrency(originalCurrency);
    _validateCategory(category);
    _validateExpenseDate(expenseDate);

    final project = await _projectsDao.getProjectById(projectId);
    if (project == null) {
      throw ArgumentError('Project not found: $projectId');
    }

    int finalRate;
    int finalConverted;
    String finalRateSource;

    if (originalCurrency == kCurrencyYer) {
      finalRate = kIdentityExchangeRate;
      finalConverted = originalAmountMinor;
      finalRateSource = kRateSourceIdentity;
      rateDate = null;
    } else {
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
          throw ArgumentError('SAR expense requires a positive exchange rate');
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
      rateDate ??= expenseDate;
    }

    final id = UuidUtil.generate();
    final now = _utcNowIso();

    await _dao.insertExpense(ExpenseMapper.entityToInsertCompanion(
      id: id,
      projectId: projectId,
      expenseGroupId: expenseGroupId,
      category: category,
      originalAmountMinor: originalAmountMinor,
      originalCurrency: originalCurrency,
      exchangeRateScaled: finalRate,
      convertedYerAmount: finalConverted,
      rateSource: finalRateSource,
      rateDate: rateDate,
      expenseDate: expenseDate,
      notes: notes,
      createdAt: now,
    ));

    final row = await _dao.getExpenseById(id);
    return ExpenseMapper.rowToEntity(row!);
  }

  @override
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
  }) async {
    UuidUtil.validate(id);

    final existing = await _dao.getExpenseById(id);
    if (existing == null) {
      throw ArgumentError('Expense not found: $id');
    }

    if (originalAmountMinor != null) _validateAmount(originalAmountMinor);
    if (originalCurrency != null) _validateCurrency(originalCurrency);
    if (category != null) _validateCategory(category);
    if (expenseDate != null) _validateExpenseDate(expenseDate);

    int? finalConverted;
    int? finalRate;
    String? finalRateSource;
    String? finalRateDate;

    final effectiveCurrency = originalCurrency ?? existing.originalCurrency;
    final effectiveAmount = originalAmountMinor ?? existing.originalAmountMinor;

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
        throw ArgumentError('SAR expense requires positive exchange rate');
      }
      finalConverted = convertToYer(effectiveAmount, kCurrencySar, finalRate);
      finalRateSource = rateSource ?? existing.rateSource;
      finalRateDate = rateDate ??
          existing.rateDate ??
          (expenseDate ?? existing.expenseDate);
    }

    await _dao.updateExpense(
      id,
      ExpenseMapper.entityToUpdateCompanion(
        category: category,
        originalAmountMinor: originalAmountMinor,
        originalCurrency: originalCurrency,
        exchangeRateScaled: finalRate,
        convertedYerAmount: finalConverted,
        rateSource: finalRateSource,
        rateDate: finalRateDate,
        expenseDate: expenseDate,
        notes: notes,
      ),
    );

    final row = await _dao.getExpenseById(id);
    return ExpenseMapper.rowToEntity(row!);
  }

  @override
  Future<void> softDelete(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getExpenseByIdIncludeDeleted(id);
    if (existing == null) {
      throw ArgumentError('Expense not found: $id');
    }
    if (existing.isDeleted) return; // Idempotent
    await _dao.softDelete(id, _utcNowIso());
  }

  @override
  Future<void> restore(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getExpenseByIdIncludeDeleted(id);
    if (existing == null) {
      throw ArgumentError('Expense not found: $id');
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
  Future<int> totalActiveExpensesYer(String projectId) async {
    UuidUtil.validate(projectId);
    return _dao.sumActiveExpensesYer(projectId);
  }

  @override
  Future<int> countAllByProject(String projectId) async {
    UuidUtil.validate(projectId);
    return _dao.countAllByProject(projectId);
  }

  // ── Validation helpers ──

  void _validateAmount(int amount) {
    if (amount <= 0) {
      throw ArgumentError('Expense amount must be positive');
    }
  }

  void _validateCurrency(String currency) {
    if (!kSupportedCurrencies.contains(currency)) {
      throw ArgumentError('Unsupported currency: $currency');
    }
  }

  void _validateCategory(String category) {
    if (!kExpenseCategories.contains(category)) {
      throw ArgumentError('Invalid expense category: $category');
    }
  }

  void _validateExpenseDate(String date) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw ArgumentError('Invalid expense date format: $date');
    }
    DateTime.parse('${date}T00:00:00');
  }

  String _utcNowIso() => DateTime.now().toUtc().toIso8601String();
}

/// Active runtime provider for the local expense repository.
final localExpenseRepositoryProvider =
    Provider<ExpenseRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalExpenseRepository(
    db.expensesDao,
    db.projectsDao,
    db,
    ref.watch(localSettingsRepositoryProvider),
  );
});
