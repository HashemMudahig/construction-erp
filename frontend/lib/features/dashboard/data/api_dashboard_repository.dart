import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository_interface.dart';

/// Preserved FastAPI adapter. It is not used by the active Dashboard runtime.
class ApiDashboardRepository implements DashboardRepositoryInterface {
  ApiDashboardRepository(this._dio);
  final Dio _dio;

  int _remoteYer(Object? value) => num.parse(value?.toString() ?? '0').round();

  @override
  Future<DashboardSummary> getSummary() async {
    final response = await _dio.get(Endpoints.dashboardSummary);
    final json = response.data as Map<String, dynamic>;
    return DashboardSummary(
      activeClientCount: json['total_clients'] as int,
      activeProjectCount: json['active_projects'] as int,
      completedProjectCount: json['completed_projects'] as int,
      totalPaymentsYer: _remoteYer(json['total_payments']),
      totalExpensesYer: _remoteYer(json['total_expenses']),
    );
  }

  @override
  Future<List<DashboardProjectOverview>> getProjectsOverview() async {
    final response = await _dio.get(Endpoints.dashboardProjects);
    return (response.data as List).cast<Map<String, dynamic>>().map((json) {
      return DashboardProjectOverview(
        projectId: json['project_id'] as String,
        projectName: json['name'] as String,
        projectStatus: json['status'] as String,
        clientName: json['client_name'] as String,
        totalPaymentsYer: _remoteYer(json['payments_sum']),
        totalExpensesYer: _remoteYer(json['expenses_sum']),
        completedMilestones: 0,
        totalMilestones: 0,
      );
    }).toList();
  }

  @override
  Future<List<DashboardFinanceMonth>> getFinanceTimeline({
    required DateTime referenceDate,
    int monthCount = 12,
  }) async {
    final response = await _dio.get(Endpoints.dashboardFinance);
    final json = response.data as Map<String, dynamic>;
    return (json['months'] as List).cast<Map<String, dynamic>>().map((item) {
      final parts = (item['month'] as String).split('-');
      return DashboardFinanceMonth(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        totalPaymentsYer: _remoteYer(item['income']),
        totalExpensesYer: _remoteYer(item['expense']),
      );
    }).toList();
  }
}

final apiDashboardRepositoryProvider = Provider<ApiDashboardRepository>((ref) {
  return ApiDashboardRepository(ref.watch(dioProvider));
});
