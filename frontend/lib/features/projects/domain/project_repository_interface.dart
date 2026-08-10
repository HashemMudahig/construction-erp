import 'project_entity.dart';

/// A per-currency sub-total of payments or expenses, in the original
/// transaction currency. Used for grouped multi-currency display.
class CurrencyBreakdownEntry {
  const CurrencyBreakdownEntry({
    required this.currency,
    required this.amountMinor,
  });

  /// Currency code, e.g. "SAR" or "YER".
  final String currency;

  /// Total in [currency] minor units.
  final int amountMinor;
}

/// Local financial summary for a project.
///
/// All "contract-currency" totals ([totalPaymentsContractCurrency],
/// [totalExpensesContractCurrency], [remainingContractValue],
/// [netCashFlow]) are expressed in the project's [ProjectEntity.budgetCurrency]
/// minor units. They are computed by converting each payment/expense into the
/// contract currency using that row's own immutable exchange-rate snapshot, so
/// historical exchange rates are preserved and never recalculated against the
/// current rate.
///
/// The legacy [totalPaymentsYer]/[totalExpensesYer]/[balance] fields remain
/// for backward compatibility with existing dashboard/reports consumers and
/// tests; they aggregate the stored YER snapshots.
///
/// [profitMargin] is a ratio (not percentage), matching the Phase 01 verified
/// contract: (netCashFlow / totalPayments) quantized to 0.01. A value of 0.50
/// means 50% margin.
class ProjectFinancialSummary {
  ProjectFinancialSummary({
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
    required this.balance,
    required this.profitMargin,
    required this.contractCurrency,
    required this.currentContractValue,
    required this.originalContractValue,
    required this.totalPaymentsContractCurrency,
    required this.totalExpensesContractCurrency,
    required this.remainingContractValue,
    required this.netCashFlow,
    required this.paymentsByCurrency,
    required this.expensesByCurrency,
  });

  /// Contract (budget) currency code, e.g. "SAR" or "YER".
  final String contractCurrency;

  /// Current contract value (reflects amendments) in minor units.
  final int currentContractValue;

  /// Original contract value captured at creation, never overwritten.
  final int originalContractValue;

  /// Total payments converted into the contract currency (minor units).
  final int totalPaymentsContractCurrency;

  /// Total expenses converted into the contract currency (minor units).
  final int totalExpensesContractCurrency;

  /// Remaining contract value = contract value − total payments in
  /// contract currency. Negative when overpaid.
  final int remainingContractValue;

  /// Net cash flow = converted payments − converted expenses, in contract
  /// currency minor units.
  final int netCashFlow;

  /// Payments grouped by their original transaction currency. Each entry's
  /// [CurrencyBreakdownEntry.amountMinor] is in that currency's minor units.
  final List<CurrencyBreakdownEntry> paymentsByCurrency;

  /// Expenses grouped by their original transaction currency.
  final List<CurrencyBreakdownEntry> expensesByCurrency;

  // ── Legacy YER-aggregated fields (backward compatibility) ──

  final int totalPaymentsYer;
  final int totalExpensesYer;
  final int balance;
  final double profitMargin;
}

/// Contract for project data access operations.
///
/// Implemented in production by the local Drift/SQLite repository.
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
  /// Uses exact local Payment and Expense snapshots.
  Future<ProjectFinancialSummary> getFinancialSummary(String id);

  /// Applies a contract amendment: changes the **current** contract value
  /// while preserving the [ProjectEntity.originalContractValueMinor].
  ///
  /// [newContractValueMinor] is the new current contract value in minor
  /// units (in the project's existing budget currency). The original value
  /// is never overwritten. Use this instead of [update] when financial
  /// transactions already exist and the contract value must change.
  Future<ProjectEntity> amendContract({
    required String id,
    required int newContractValueMinor,
  });
}
