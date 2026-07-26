import 'project_entity.dart';

/// Local financial summary for a project.
///
/// Computed from local Payment and Expense records. All amounts are in
/// converted YER minor units (scale 0).
///
/// [profitMargin] is a ratio (not percentage), matching the Phase 01
/// verified contract: (balance / totalPayments) quantized to 0.01.
/// A value of 0.50 means 50% margin.
class ProjectFinancialSummary {
  ProjectFinancialSummary({
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
    required this.balance,
    required this.profitMargin,
  });

  final int totalPaymentsYer;
  final int totalExpensesYer;
  final int balance;
  final double profitMargin;
}

/// Contract for project data access operations.
///
/// Implementations:
/// - [LocalProjectRepository] — active runtime, uses Drift/SQLite.
/// - [ApiProjectRepository] — preserved remote adapter, uses Dio/FastAPI.
abstract class ProjectRepositoryInterface {
  /// Lists projects. Optional filters by [clientId] and [status].
  /// When [search] is non-empty, filters by project name (case-insensitive).
  Future<List<ProjectEntity>> list({
    String? clientId,
    String? status,
    String? search,
  });

  /// Returns the project with the given [id], or null if not found.
  Future<ProjectEntity?> getById(String id);

  /// Creates a new project. Returns the created entity.
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
  });

  /// Updates an existing project. Only non-null fields are updated.
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
  });

  /// Hard-deletes a project if it has no child records (milestones, payments,
  /// expenses). Throws [StateError] if child records exist.
  Future<void> deleteIfEligible(String id);

  /// Returns true if the project has any child records.
  Future<bool> hasChildRecords(String id);

  /// Returns the local financial summary for the project.
  ///
  /// Computes totals from local Payment and Expense tables.
  /// Does not call Dio or FastAPI.
  Future<ProjectFinancialSummary> getFinancialSummary(String id);
}
