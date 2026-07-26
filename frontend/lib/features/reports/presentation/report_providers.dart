import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';

// ---- DTOs ----

class ProjectStatusItem {
  ProjectStatusItem({
    required this.projectId,
    required this.name,
    required this.status,
    required this.budget,
    required this.totalPayments,
    required this.totalExpenses,
    required this.balance,
    required this.milestoneCount,
    required this.completedMilestones,
    required this.progressPct,
  });
  final String projectId;
  final String name;
  final String status;
  final Decimal budget;
  final Decimal totalPayments;
  final Decimal totalExpenses;
  final Decimal balance;
  final int milestoneCount;
  final int completedMilestones;
  final Decimal progressPct;

  factory ProjectStatusItem.fromJson(Map<String, dynamic> j) =>
      ProjectStatusItem(
        projectId: j['project_id'] as String,
        name: j['name'] as String,
        status: j['status'] as String,
        budget: Decimal.parse(j['budget'] as String),
        totalPayments: Decimal.parse(j['total_payments'] as String),
        totalExpenses: Decimal.parse(j['total_expenses'] as String),
        balance: Decimal.parse(j['balance'] as String),
        milestoneCount: j['milestone_count'] as int,
        completedMilestones: j['completed_milestones'] as int,
        progressPct: Decimal.parse(j['progress_pct'] as String),
      );
}

class ProjectFinancial {
  ProjectFinancial(
      {required this.projectId,
      required this.name,
      required this.income,
      required this.expenses,
      required this.net});
  final String projectId;
  final String name;
  final Decimal income;
  final Decimal expenses;
  final Decimal net;
  factory ProjectFinancial.fromJson(Map<String, dynamic> j) => ProjectFinancial(
      projectId: j['project_id'] as String,
      name: j['name'] as String,
      income: Decimal.parse(j['income'] as String),
      expenses: Decimal.parse(j['expenses'] as String),
      net: Decimal.parse(j['net'] as String));
}

class FinancialSummary {
  FinancialSummary(
      {required this.startDate,
      required this.endDate,
      required this.totalIncome,
      required this.totalExpenses,
      required this.net,
      required this.perProject});
  final String? startDate;
  final String? endDate;
  final Decimal totalIncome;
  final Decimal totalExpenses;
  final Decimal net;
  final List<ProjectFinancial> perProject;
  factory FinancialSummary.fromJson(Map<String, dynamic> j) => FinancialSummary(
      startDate: j['start_date'] as String?,
      endDate: j['end_date'] as String?,
      totalIncome: Decimal.parse(j['total_income'] as String),
      totalExpenses: Decimal.parse(j['total_expenses'] as String),
      net: Decimal.parse(j['net'] as String),
      perProject: (j['per_project'] as List)
          .map((e) => ProjectFinancial.fromJson(e as Map<String, dynamic>))
          .toList());
}

class CategoryBreakdown {
  CategoryBreakdown(
      {required this.category, required this.total, required this.percentage});
  final String category;
  final Decimal total;
  final Decimal percentage;
  factory CategoryBreakdown.fromJson(Map<String, dynamic> j) =>
      CategoryBreakdown(
          category: j['category'] as String,
          total: Decimal.parse(j['total'] as String),
          percentage: Decimal.parse(j['percentage'] as String));
}

class ProjectExpense {
  ProjectExpense(
      {required this.projectId,
      required this.name,
      required this.total,
      required this.byCategory});
  final String projectId;
  final String name;
  final Decimal total;
  final List<CategoryBreakdown> byCategory;
  factory ProjectExpense.fromJson(Map<String, dynamic> j) => ProjectExpense(
      projectId: j['project_id'] as String,
      name: j['name'] as String,
      total: Decimal.parse(j['total'] as String),
      byCategory: (j['by_category'] as List)
          .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList());
}

class ExpenseAnalysis {
  ExpenseAnalysis(
      {required this.startDate,
      required this.endDate,
      required this.projectId,
      required this.grandTotal,
      required this.byCategory,
      required this.byProject});
  final String? startDate;
  final String? endDate;
  final String? projectId;
  final Decimal grandTotal;
  final List<CategoryBreakdown> byCategory;
  final List<ProjectExpense> byProject;
  factory ExpenseAnalysis.fromJson(Map<String, dynamic> j) => ExpenseAnalysis(
      startDate: j['start_date'] as String?,
      endDate: j['end_date'] as String?,
      projectId: j['project_id'] as String?,
      grandTotal: Decimal.parse(j['grand_total'] as String),
      byCategory: (j['by_category'] as List)
          .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      byProject: (j['by_project'] as List)
          .map((e) => ProjectExpense.fromJson(e as Map<String, dynamic>))
          .toList());
}

// ---- Report generation provider ----

enum ReportType { projectStatus, financialSummary, expenseAnalysis }

class ReportFilters {
  ReportFilters(
      {this.type = ReportType.projectStatus,
      this.startDate,
      this.endDate,
      this.projectId,
      this.status});
  final ReportType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? projectId;
  final String? status;

  String? get startDateStr {
    if (startDate == null) return null;
    return '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}';
  }

  String? get endDateStr {
    if (endDate == null) return null;
    return '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';
  }
}

final reportResultProvider =
    FutureProvider.family<Map<String, dynamic>, ReportFilters>(
        (ref, filters) async {
  final dio = ref.read(dioProvider);
  final params = <String, dynamic>{};
  if (filters.startDateStr != null) params['start_date'] = filters.startDateStr;
  if (filters.endDateStr != null) params['end_date'] = filters.endDateStr;
  if (filters.projectId != null) params['project_id'] = filters.projectId;
  if (filters.status != null) params['status'] = filters.status;

  switch (filters.type) {
    case ReportType.projectStatus:
      final res =
          await dio.get(Endpoints.reportProjectStatus, queryParameters: params);
      return {'type': 'project_status', 'data': res.data};
    case ReportType.financialSummary:
      final res = await dio.get(Endpoints.reportFinancialSummary,
          queryParameters: params);
      return {'type': 'financial_summary', 'data': res.data};
    case ReportType.expenseAnalysis:
      final res = await dio.get(Endpoints.reportExpenseAnalysis,
          queryParameters: params);
      return {'type': 'expense_analysis', 'data': res.data};
  }
});
