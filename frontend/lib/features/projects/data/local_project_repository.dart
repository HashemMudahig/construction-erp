import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/clients_dao.dart';
import '../../../core/database/daos/projects_dao.dart';
import '../../../core/uuid/uuid_util.dart';
import '../domain/project_entity.dart';
import '../domain/project_repository_interface.dart';
import 'project_mapper.dart';

/// Local (Drift/SQLite) implementation of [ProjectRepositoryInterface].
class LocalProjectRepository implements ProjectRepositoryInterface {
  LocalProjectRepository(this._dao, this._clientsDao, AppDatabase db);

  final ProjectsDao _dao;
  final ClientsDao _clientsDao;

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
    final totalPayments = await _dao.sumPaymentsYer(id);
    final totalExpenses = await _dao.sumExpensesYer(id);
    final balance = totalPayments - totalExpenses;
    final margin =
        totalPayments > 0 ? (balance / totalPayments).toDouble() : 0.0;
    return ProjectFinancialSummary(
      totalPaymentsYer: totalPayments,
      totalExpensesYer: totalExpenses,
      balance: balance,
      profitMargin: margin,
    );
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
