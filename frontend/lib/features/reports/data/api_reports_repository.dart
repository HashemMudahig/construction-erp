import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/report_filters.dart';
import '../domain/report_models.dart';
import '../domain/reports_repository_interface.dart';

/// Preserved FastAPI adapter. It is not used by the active Reports runtime.
class ApiReportsRepository implements ReportsRepositoryInterface {
  const ApiReportsRepository(this._dio);
  final Dio _dio;

  int _yer(Object? value) => num.parse(value?.toString() ?? '0').round();

  Map<String, dynamic> _params(ReportFilters filters) => {
        if (filters.startDateIso != null) 'start_date': filters.startDateIso,
        if (filters.endDateIso != null) 'end_date': filters.endDateIso,
        if (filters.projectId != null) 'project_id': filters.projectId,
        if (filters.status != null) 'status': filters.status,
      };

  @override
  Future<ReportResult> generate(ReportFilters filters) async {
    filters.validate();
    return switch (filters.type) {
      ReportType.projectStatus => _projectStatus(filters),
      ReportType.financialSummary => _financialSummary(filters),
      ReportType.expenseAnalysis => _expenseAnalysis(filters),
    };
  }

  Future<ProjectStatusReport> _projectStatus(ReportFilters filters) async {
    final response = await _dio.get(
      Endpoints.reportProjectStatus,
      queryParameters: _params(filters),
    );
    final rows = (response.data as List).cast<Map<String, dynamic>>();
    return ProjectStatusReport(rows
        .map((json) => ProjectStatusReportRow(
              projectId: json['project_id'] as String,
              name: json['name'] as String,
              status: json['status'] as String,
              budgetAmountMinor: _yer(json['budget']),
              budgetCurrency: 'YER',
              totalPaymentsYer: _yer(json['total_payments']),
              totalExpensesYer: _yer(json['total_expenses']),
              milestoneCount: json['milestone_count'] as int,
              completedMilestones: json['completed_milestones'] as int,
            ))
        .toList());
  }

  Future<FinancialSummaryReport> _financialSummary(
    ReportFilters filters,
  ) async {
    final response = await _dio.get(
      Endpoints.reportFinancialSummary,
      queryParameters: _params(filters),
    );
    final json = response.data as Map<String, dynamic>;
    return FinancialSummaryReport(
      startDate: filters.startDate,
      endDate: filters.endDate,
      totalPaymentsYer: _yer(json['total_income']),
      totalExpensesYer: _yer(json['total_expenses']),
      perProject: (json['per_project'] as List)
          .cast<Map<String, dynamic>>()
          .map((row) => ProjectFinancialReportRow(
                projectId: row['project_id'] as String,
                name: row['name'] as String,
                totalPaymentsYer: _yer(row['income']),
                totalExpensesYer: _yer(row['expenses']),
              ))
          .toList(),
    );
  }

  Future<ExpenseAnalysisReport> _expenseAnalysis(
    ReportFilters filters,
  ) async {
    final response = await _dio.get(
      Endpoints.reportExpenseAnalysis,
      queryParameters: _params(filters),
    );
    final json = response.data as Map<String, dynamic>;
    ExpenseCategoryReportRow category(Map<String, dynamic> row) =>
        ExpenseCategoryReportRow(
          category: row['category'] as String,
          totalExpensesYer: _yer(row['total']),
          shareBasisPoints:
              (num.parse(row['percentage'].toString()) * 100).round(),
        );

    return ExpenseAnalysisReport(
      startDate: filters.startDate,
      endDate: filters.endDate,
      projectId: filters.projectId,
      grandTotalYer: _yer(json['grand_total']),
      byCategory: (json['by_category'] as List)
          .cast<Map<String, dynamic>>()
          .map(category)
          .toList(),
      byProject: (json['by_project'] as List)
          .cast<Map<String, dynamic>>()
          .map((row) => ProjectExpenseReportRow(
                projectId: row['project_id'] as String,
                name: row['name'] as String,
                totalExpensesYer: _yer(row['total']),
                byCategory: (row['by_category'] as List)
                    .cast<Map<String, dynamic>>()
                    .map(category)
                    .toList(),
              ))
          .toList(),
    );
  }
}

final apiReportsRepositoryProvider = Provider<ApiReportsRepository>(
  (ref) => ApiReportsRepository(ref.watch(dioProvider)),
);
