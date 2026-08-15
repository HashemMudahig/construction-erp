import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transfers/domain/wallet_balance_service.dart'
    show ProjectWalletBalances;
import '../data/local_dashboard_repository.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository_interface.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepositoryInterface>((ref) {
  return ref.watch(localDashboardRepositoryProvider);
});

final dashboardReferenceDateProvider =
    Provider<DateTime>((ref) => DateTime.now());

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).getSummary();
});

final dashboardGlobalWalletProvider =
    FutureProvider<ProjectWalletBalances>((ref) {
  return ref.watch(dashboardRepositoryProvider).getGlobalWalletBalances();
});

final dashboardProjectsProvider =
    FutureProvider<List<DashboardProjectOverview>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getProjectsOverview();
});

final dashboardFinanceProvider =
    FutureProvider<List<DashboardFinanceMonth>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getFinanceTimeline(
        referenceDate: ref.watch(dashboardReferenceDateProvider),
      );
});

void invalidateDashboard(Ref ref) {
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(dashboardGlobalWalletProvider);
  ref.invalidate(dashboardProjectsProvider);
  ref.invalidate(dashboardFinanceProvider);
}
