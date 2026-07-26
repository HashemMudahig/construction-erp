import 'dashboard_models.dart';

abstract interface class DashboardRepositoryInterface {
  Future<DashboardSummary> getSummary();
  Future<List<DashboardProjectOverview>> getProjectsOverview();
  Future<List<DashboardFinanceMonth>> getFinanceTimeline({
    required DateTime referenceDate,
    int monthCount = 12,
  });
}
