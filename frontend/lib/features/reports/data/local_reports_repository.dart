import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/reports_dao.dart';
import '../../../core/database/database_provider.dart';
import '../domain/report_filters.dart';
import '../domain/report_models.dart';
import '../domain/reports_repository_interface.dart';

class LocalReportsRepository implements ReportsRepositoryInterface {
  const LocalReportsRepository(this._dao);
  final ReportsDao _dao;

  @override
  Future<ReportResult> generate(ReportFilters filters) async {
    filters.validate();
    final projectId = filters.projectId;
    if (projectId != null && !await _dao.projectExists(projectId)) {
      throw const ReportFilterException('Project not found.');
    }
    return switch (filters.type) {
      ReportType.projectStatus => _projectStatus(filters),
      ReportType.financialSummary => _financialSummary(filters),
      ReportType.expenseAnalysis => _expenseAnalysis(filters),
    };
  }

  Future<ProjectStatusReport> _projectStatus(ReportFilters filters) async {
    final rows = await _dao.getProjectStatus(
      projectId: filters.projectId,
      status: filters.status,
    );
    return ProjectStatusReport(rows
        .map((row) => ProjectStatusReportRow(
              projectId: row.projectId,
              name: row.name,
              status: row.status,
              budgetAmountMinor: row.budgetAmountMinor,
              budgetCurrency: row.budgetCurrency,
              totalPaymentsYer: row.totalPaymentsYer,
              totalExpensesYer: row.totalExpensesYer,
              milestoneCount: row.milestoneCount,
              completedMilestones: row.completedMilestones,
            ))
        .toList());
  }

  Future<FinancialSummaryReport> _financialSummary(
    ReportFilters filters,
  ) async {
    final rows = await _dao.getFinancialSummary(
      startDate: filters.startDateIso,
      endDate: filters.endDateIso,
      projectId: filters.projectId,
    );
    final projects = rows
        .map((row) => ProjectFinancialReportRow(
              projectId: row.projectId,
              name: row.name,
              totalPaymentsYer: row.paymentsYer,
              totalExpensesYer: row.expensesYer,
              sarWalletBalance: row.sarWalletBalance,
              yerWalletBalance: row.yerWalletBalance,
            ))
        .toList();
    return FinancialSummaryReport(
      startDate: filters.startDate,
      endDate: filters.endDate,
      totalPaymentsYer:
          projects.fold(0, (sum, row) => sum + row.totalPaymentsYer),
      totalExpensesYer:
          projects.fold(0, (sum, row) => sum + row.totalExpensesYer),
      totalSarWalletBalance:
          projects.fold(0, (sum, row) => sum + row.sarWalletBalance),
      totalYerWalletBalance:
          projects.fold(0, (sum, row) => sum + row.yerWalletBalance),
      perProject: projects,
    );
  }

  Future<ExpenseAnalysisReport> _expenseAnalysis(
    ReportFilters filters,
  ) async {
    final rows = await _dao.getExpenseAnalysis(
      startDate: filters.startDateIso,
      endDate: filters.endDateIso,
      projectId: filters.projectId,
    );
    final grandTotal = rows.fold(0, (sum, row) => sum + row.totalYer);
    final categoryTotals = <String, int>{};
    final projectRows = <String, List<ReportsCategoryRow>>{};
    for (final row in rows) {
      categoryTotals.update(
        row.category,
        (value) => value + row.totalYer,
        ifAbsent: () => row.totalYer,
      );
      projectRows.putIfAbsent(row.projectId, () => []).add(row);
    }
    final byCategory = categoryTotals.entries
        .map((entry) => ExpenseCategoryReportRow(
              category: entry.key,
              totalExpensesYer: entry.value,
              shareBasisPoints:
                  grandTotal == 0 ? 0 : entry.value * 10000 ~/ grandTotal,
            ))
        .toList()
      ..sort((a, b) => a.category.compareTo(b.category));
    final byProject = projectRows.entries.map((entry) {
      final projectTotal =
          entry.value.fold(0, (sum, row) => sum + row.totalYer);
      return ProjectExpenseReportRow(
        projectId: entry.key,
        name: entry.value.first.projectName,
        totalExpensesYer: projectTotal,
        byCategory: entry.value
            .map((row) => ExpenseCategoryReportRow(
                  category: row.category,
                  totalExpensesYer: row.totalYer,
                  shareBasisPoints: projectTotal == 0
                      ? 0
                      : row.totalYer * 10000 ~/ projectTotal,
                ))
            .toList(),
      );
    }).toList()
      ..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : a.projectId.compareTo(b.projectId);
      });
    return ExpenseAnalysisReport(
      startDate: filters.startDate,
      endDate: filters.endDate,
      projectId: filters.projectId,
      grandTotalYer: grandTotal,
      byCategory: byCategory,
      byProject: byProject,
    );
  }
}

final reportsDaoProvider = Provider<ReportsDao>(
  (ref) => ReportsDao(ref.watch(databaseProvider)),
);

final localReportsRepositoryProvider = Provider<LocalReportsRepository>(
  (ref) => LocalReportsRepository(ref.watch(reportsDaoProvider)),
);
