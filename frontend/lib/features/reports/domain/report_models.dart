sealed class ReportResult {
  const ReportResult();
}

class ProjectStatusReport extends ReportResult {
  const ProjectStatusReport(this.items);
  final List<ProjectStatusReportRow> items;
}

class ProjectStatusReportRow {
  const ProjectStatusReportRow({
    required this.projectId,
    required this.name,
    required this.status,
    required this.budgetAmountMinor,
    required this.budgetCurrency,
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
    required this.milestoneCount,
    required this.completedMilestones,
  });

  final String projectId;
  final String name;
  final String status;
  final int budgetAmountMinor;
  final String budgetCurrency;
  final int totalPaymentsYer;
  final int totalExpensesYer;
  final int milestoneCount;
  final int completedMilestones;

  int get netCashFlowYer => totalPaymentsYer - totalExpensesYer;

  /// Percentage stored as basis points: 10000 = 100.00%.
  int get progressBasisPoints =>
      milestoneCount == 0 ? 0 : completedMilestones * 10000 ~/ milestoneCount;
}

class FinancialSummaryReport extends ReportResult {
  const FinancialSummaryReport({
    required this.startDate,
    required this.endDate,
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
    required this.perProject,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int totalPaymentsYer;
  final int totalExpensesYer;
  final List<ProjectFinancialReportRow> perProject;

  int get netCashFlowYer => totalPaymentsYer - totalExpensesYer;
}

class ProjectFinancialReportRow {
  const ProjectFinancialReportRow({
    required this.projectId,
    required this.name,
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
  });

  final String projectId;
  final String name;
  final int totalPaymentsYer;
  final int totalExpensesYer;

  int get netCashFlowYer => totalPaymentsYer - totalExpensesYer;
}

class ExpenseAnalysisReport extends ReportResult {
  const ExpenseAnalysisReport({
    required this.startDate,
    required this.endDate,
    required this.projectId,
    required this.grandTotalYer,
    required this.byCategory,
    required this.byProject,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? projectId;
  final int grandTotalYer;
  final List<ExpenseCategoryReportRow> byCategory;
  final List<ProjectExpenseReportRow> byProject;
}

class ExpenseCategoryReportRow {
  const ExpenseCategoryReportRow({
    required this.category,
    required this.totalExpensesYer,
    required this.shareBasisPoints,
  });

  final String category;
  final int totalExpensesYer;

  /// Percentage stored as basis points: 10000 = 100.00%.
  final int shareBasisPoints;
}

class ProjectExpenseReportRow {
  const ProjectExpenseReportRow({
    required this.projectId,
    required this.name,
    required this.totalExpensesYer,
    required this.byCategory,
  });

  final String projectId;
  final String name;
  final int totalExpensesYer;
  final List<ExpenseCategoryReportRow> byCategory;
}
