import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';

class DashboardSummary {
  DashboardSummary({
    required this.activeProjects,
    required this.completedProjects,
    required this.totalClients,
    required this.outstandingBalances,
    required this.totalPayments,
    required this.totalExpenses,
  });
  final int activeProjects;
  final int completedProjects;
  final int totalClients;
  final Decimal outstandingBalances;
  final Decimal totalPayments;
  final Decimal totalExpenses;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        activeProjects: json['active_projects'] as int,
        completedProjects: json['completed_projects'] as int,
        totalClients: json['total_clients'] as int,
        outstandingBalances: Decimal.parse(json['outstanding_balances'] as String),
        totalPayments: Decimal.parse(json['total_payments'] as String),
        totalExpenses: Decimal.parse(json['total_expenses'] as String),
      );
}

class ProjectOverview {
  ProjectOverview({
    required this.projectId,
    required this.name,
    required this.clientName,
    required this.status,
    required this.budget,
    required this.paymentsSum,
    required this.expensesSum,
    required this.balance,
  });
  final String projectId;
  final String name;
  final String clientName;
  final String status;
  final Decimal budget;
  final Decimal paymentsSum;
  final Decimal expensesSum;
  final Decimal balance;

  factory ProjectOverview.fromJson(Map<String, dynamic> json) => ProjectOverview(
        projectId: json['project_id'] as String,
        name: json['name'] as String,
        clientName: json['client_name'] as String,
        status: json['status'] as String,
        budget: Decimal.parse(json['budget'] as String),
        paymentsSum: Decimal.parse(json['payments_sum'] as String),
        expensesSum: Decimal.parse(json['expenses_sum'] as String),
        balance: Decimal.parse(json['balance'] as String),
      );
}

class MonthlyPoint {
  MonthlyPoint({required this.month, required this.income, required this.expense});
  final String month;
  final Decimal income;
  final Decimal expense;

  factory MonthlyPoint.fromJson(Map<String, dynamic> json) => MonthlyPoint(
        month: json['month'] as String,
        income: Decimal.parse(json['income'] as String),
        expense: Decimal.parse(json['expense'] as String),
      );
}

class FinanceOverview {
  FinanceOverview({required this.months});
  final List<MonthlyPoint> months;

  factory FinanceOverview.fromJson(Map<String, dynamic> json) => FinanceOverview(
        months: (json['months'] as List)
            .map((e) => MonthlyPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get(Endpoints.dashboardSummary);
  return DashboardSummary.fromJson(res.data as Map<String, dynamic>);
});

final dashboardProjectsProvider = FutureProvider<List<ProjectOverview>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get(Endpoints.dashboardProjects);
  final list = res.data as List;
  return list.map((e) => ProjectOverview.fromJson(e as Map<String, dynamic>)).toList();
});

final dashboardFinanceProvider = FutureProvider<FinanceOverview>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get(Endpoints.dashboardFinance);
  return FinanceOverview.fromJson(res.data as Map<String, dynamic>);
});