import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/clients_dao.dart';
import '../../../core/database/daos/expenses_dao.dart';
import '../../../core/database/daos/payments_dao.dart';
import '../../../core/database/daos/projects_dao.dart';
import '../../../core/database/finance/currency_conversion.dart';
import '../../../core/uuid/uuid_util.dart';
import '../domain/project_entity.dart';
import '../domain/project_repository_interface.dart';
import 'project_mapper.dart';

/// Local (Drift/SQLite) implementation of [ProjectRepositoryInterface].
class LocalProjectRepository implements ProjectRepositoryInterface {
  LocalProjectRepository(this._dao, this._clientsDao, AppDatabase db)
      : _paymentsDao = db.paymentsDao,
        _expensesDao = db.expensesDao;

  final ProjectsDao _dao;
  final ClientsDao _clientsDao;
  final PaymentsDao _paymentsDao;
  final ExpensesDao _expensesDao;

  @override
  Future<List<ProjectEntity>> list({
    String? clientId,
    String? status,
    String? search,
  }) async {
    final hasSearch = search != null && search.trim().isNotEmpty;
    final List<ProjectRow> rows;

    if (hasSearch) {
      rows = await _dao.searchByName(search.trim());
    } else if (clientId != null && status != null) {
      rows = await _dao.getByClientAndStatus(clientId, status);
    } else if (clientId != null) {
      rows = await _dao.getByClient(clientId);
    } else if (status != null) {
      rows = await _dao.getByStatus(status);
    } else {
      rows = await _dao.getAllProjects();
    }
    return rows.map(ProjectMapper.rowToEntity).toList();
  }

  @override
  Future<ProjectEntity?> getById(String id) async {
    UuidUtil.validate(id);
    final row = await _dao.getProjectById(id);
    if (row == null) return null;
    return ProjectMapper.rowToEntity(row);
  }

  @override
  Future<ProjectEntity> create({
    required String clientId,
    required String name,
    String? description,
    required int budgetAmountMinor,
    required String budgetCurrency,
    String exchangePolicy = 'per_transaction',
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String status = 'planning',
  }) async {
    UuidUtil.validate(clientId);
    _validateName(name);
    _validateStatus(status);
    _validateCurrency(budgetCurrency);
    _validateBudgetAmount(budgetAmountMinor, budgetCurrency);
    _validateExchangePolicy(exchangePolicy);
    _validateDates(startDate, endDate);
    _validateFixedRate(budgetCurrency, exchangePolicy, fixedExchangeRateScaled);

    // Verify client exists
    final client = await _clientsDao.getClientById(clientId);
    if (client == null) {
      throw ArgumentError('Client not found: $clientId');
    }

    final id = UuidUtil.generate();
    final now = _utcNowIso();

    await _dao.insertProject(ProjectMapper.entityToInsertCompanion(
      id: id,
      clientId: clientId,
      name: name.trim(),
      description:
          description?.trim().isEmpty == true ? null : description?.trim(),
      budgetAmountMinor: budgetAmountMinor,
      budgetCurrency: budgetCurrency,
      exchangePolicy: exchangePolicy,
      fixedExchangeRateScaled: fixedExchangeRateScaled,
      startDate: startDate,
      endDate: endDate,
      status: status,
      createdAt: now,
    ));

    final row = await _dao.getProjectById(id);
    return ProjectMapper.rowToEntity(row!);
  }

  @override
  Future<ProjectEntity> update({
    required String id,
    String? clientId,
    String? name,
    String? description,
    int? budgetAmountMinor,
    String? budgetCurrency,
    String? exchangePolicy,
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    UuidUtil.validate(id);

    final existing = await _dao.getProjectById(id);
    if (existing == null) {
      throw ArgumentError('Project not found: $id');
    }

    if (name != null) _validateName(name);
    if (status != null) _validateStatus(status);
    if (budgetCurrency != null) _validateCurrency(budgetCurrency);
    if (budgetAmountMinor != null && budgetCurrency != null) {
      _validateBudgetAmount(budgetAmountMinor, budgetCurrency);
    }
    if (exchangePolicy != null) _validateExchangePolicy(exchangePolicy);
    if (startDate != null || endDate != null) {
      _validateDates(
          startDate ?? existing.startDate, endDate ?? existing.endDate);
    }
    if (clientId != null) {
      UuidUtil.validate(clientId);
      final client = await _clientsDao.getClientById(clientId);
      if (client == null) {
        throw ArgumentError('Client not found: $clientId');
      }
    }

    // Contract-value lock: once any financial transaction (payment, expense,
    // or milestone) exists, the contract value (budgetAmountMinor) and
    // currency can no longer be changed through a plain update. The original
    // contract value is always preserved regardless.
    final hasTransactions = await hasChildRecords(id);
    if (hasTransactions) {
      if (budgetAmountMinor != null &&
          budgetAmountMinor != existing.budgetAmountMinor) {
        throw StateError(
          'Cannot edit contract value after payments, expenses, or '
          'milestones have been recorded. Use a contract amendment.',
        );
      }
      if (budgetCurrency != null &&
          budgetCurrency != existing.budgetCurrency) {
        throw StateError(
          'Cannot change contract currency after transactions exist.',
        );
      }
    }

    await _dao.updateProject(
      id,
      ProjectMapper.entityToUpdateCompanion(
        clientId: clientId,
        name: name?.trim(),
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        budgetAmountMinor: budgetAmountMinor,
        budgetCurrency: budgetCurrency,
        exchangePolicy: exchangePolicy,
        fixedExchangeRateScaled: fixedExchangeRateScaled,
        startDate: startDate,
        endDate: endDate,
        status: status,
      ),
    );

    final row = await _dao.getProjectById(id);
    return ProjectMapper.rowToEntity(row!);
  }

  @override
  Future<void> deleteIfEligible(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getProjectById(id);
    if (existing == null) {
      throw ArgumentError('Project not found: $id');
    }
    final hasChildren = await hasChildRecords(id);
    if (hasChildren) {
      throw StateError(
          'Cannot delete project: it has milestones, payments, or expenses.');
    }
    await _dao.deleteProject(id);
  }

  @override
  Future<bool> hasChildRecords(String id) async {
    final milestones = await _dao.countMilestones(id);
    if (milestones > 0) return true;
    final payments = await _dao.countPayments(id);
    if (payments > 0) return true;
    final expenses = await _dao.countExpenses(id);
    return expenses > 0;
  }

  @override
  Future<ProjectFinancialSummary> getFinancialSummary(String id) async {
    UuidUtil.validate(id);

    final project = await _dao.getProjectById(id);
    if (project == null) {
      throw ArgumentError('Project not found: $id');
    }
    final contractCurrency = project.budgetCurrency;
    final contractValueMinor = project.budgetAmountMinor;

    // Legacy YER aggregates (backward compatibility for dashboard/reports).
    final totalPaymentsYer = await _dao.sumPaymentsYer(id);
    final totalExpensesYer = await _dao.sumExpensesYer(id);
    final yerBalance = totalPaymentsYer - totalExpensesYer;
    final margin =
        totalPaymentsYer > 0 ? (yerBalance / totalPaymentsYer).toDouble() : 0.0;

    // Contract-currency aggregation. Each row is converted into the contract
    // currency using its own immutable exchange-rate snapshot, so historical
    // rates are preserved and never recalculated against the current rate.
    final payments = await _paymentsDao.getActivePaymentsByProject(id);
    final expenses = await _expensesDao.getActiveExpensesByProject(id);

    final Map<String, int> paymentsByCurrency = {};
    final Map<String, int> expensesByCurrency = {};
    int totalPaymentsContract = 0;
    int totalExpensesContract = 0;

    for (final p in payments) {
      paymentsByCurrency.update(
        p.originalCurrency,
        (v) => v + p.originalAmountMinor,
        ifAbsent: () => p.originalAmountMinor,
      );
      totalPaymentsContract += convertToCurrency(
        p.originalAmountMinor,
        p.originalCurrency,
        contractCurrency,
        p.exchangeRateScaled,
      );
    }
    for (final e in expenses) {
      expensesByCurrency.update(
        e.originalCurrency,
        (v) => v + e.originalAmountMinor,
        ifAbsent: () => e.originalAmountMinor,
      );
      totalExpensesContract += convertToCurrency(
        e.originalAmountMinor,
        e.originalCurrency,
        contractCurrency,
        e.exchangeRateScaled,
      );
    }

    final remainingContractValue = contractValueMinor - totalPaymentsContract;
    final netCashFlow = totalPaymentsContract - totalExpensesContract;

    return ProjectFinancialSummary(
      totalPaymentsYer: totalPaymentsYer,
      totalExpensesYer: totalExpensesYer,
      balance: yerBalance,
      profitMargin: margin,
      contractCurrency: contractCurrency,
      currentContractValue: contractValueMinor,
      originalContractValue: project.originalContractValueMinor,
      totalPaymentsContractCurrency: totalPaymentsContract,
      totalExpensesContractCurrency: totalExpensesContract,
      remainingContractValue: remainingContractValue,
      netCashFlow: netCashFlow,
      paymentsByCurrency: paymentsByCurrency.entries
          .map((e) => CurrencyBreakdownEntry(
              currency: e.key, amountMinor: e.value))
          .toList()
        ..sort((a, b) => a.currency.compareTo(b.currency)),
      expensesByCurrency: expensesByCurrency.entries
          .map((e) => CurrencyBreakdownEntry(
              currency: e.key, amountMinor: e.value))
          .toList()
        ..sort((a, b) => a.currency.compareTo(b.currency)),
    );
  }

  @override
  Future<ProjectEntity> amendContract({
    required String id,
    required int newContractValueMinor,
  }) async {
    UuidUtil.validate(id);
    final existing = await _dao.getProjectById(id);
    if (existing == null) {
      throw ArgumentError('Project not found: $id');
    }
    _validateBudgetAmount(newContractValueMinor, existing.budgetCurrency);
    // Only the current contract value (budgetAmountMinor) is updated; the
    // original is preserved.
    await _dao.updateProject(
      id,
      ProjectsCompanion(
        budgetAmountMinor: Value(newContractValueMinor),
      ),
    );
    final row = await _dao.getProjectById(id);
    return ProjectMapper.rowToEntity(row!);
  }

  // ── Validation helpers ──

  void _validateName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Project name is required');
    }
  }

  void _validateStatus(String status) {
    if (!kProjectStatuses.contains(status)) {
      throw ArgumentError('Invalid project status: $status');
    }
  }

  void _validateCurrency(String currency) {
    if (!kSupportedCurrencies.contains(currency)) {
      throw ArgumentError('Unsupported currency: $currency');
    }
  }

  void _validateBudgetAmount(int amount, String currency) {
    if (amount < 0) {
      throw ArgumentError('Budget must be non-negative');
    }
  }

  void _validateExchangePolicy(String policy) {
    if (!kValidExchangePolicies.contains(policy)) {
      throw ArgumentError('Invalid exchange policy: $policy');
    }
  }

  void _validateDates(String? startDate, String? endDate) {
    if (startDate != null &&
        endDate != null &&
        startDate.compareTo(endDate) > 0) {
      throw ArgumentError('End date must be on or after start date');
    }
  }

  void _validateFixedRate(String currency, String policy, int? fixedRate) {
    if (currency == kCurrencySar && policy == kExchangePolicyFixed) {
      if (fixedRate == null || fixedRate <= 0) {
        throw ArgumentError(
          'Fixed SAR project requires a positive fixed exchange rate',
        );
      }
    }
  }

  String _utcNowIso() => DateTime.now().toUtc().toIso8601String();
}

/// Active runtime provider for the local project repository.
final localProjectRepositoryProvider =
    Provider<ProjectRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalProjectRepository(db.projectsDao, db.clientsDao, db);
});
