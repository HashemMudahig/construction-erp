import 'dashboard_models.dart';
import '../../transfers/domain/wallet_balance_service.dart';

abstract interface class DashboardRepositoryInterface {
  Future<DashboardSummary> getSummary();
  Future<ProjectWalletBalances> getGlobalWalletBalances();
  Future<List<DashboardProjectOverview>> getProjectsOverview();
  Future<List<DashboardFinanceMonth>> getFinanceTimeline({
    required DateTime referenceDate,
    int monthCount = 12,
  });
}
