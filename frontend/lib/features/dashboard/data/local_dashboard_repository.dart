import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/dashboard_dao.dart';
import '../../../core/database/database_provider.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository_interface.dart';

class DashboardLocalException implements Exception {
  const DashboardLocalException(this.message, [this.cause]);
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

class LocalDashboardRepository implements DashboardRepositoryInterface {
  LocalDashboardRepository(this._dao);
  final DashboardDao _dao;

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      final row = await _dao.getSummary();
      return DashboardSummary(
        activeClientCount: row.activeClients,
        activeProjectCount: row.activeProjects,
        completedProjectCount: row.completedProjects,
        totalPaymentsYer: row.totalPaymentsYer,
        totalExpensesYer: row.totalExpensesYer,
      );
    } catch (error) {
      throw DashboardLocalException(
          'Unable to read local dashboard summary.', error);
    }
  }

  @override
  Future<List<DashboardProjectOverview>> getProjectsOverview() async {
    try {
      final rows = await _dao.getProjectsOverview();
      return rows
          .map((row) => DashboardProjectOverview(
                projectId: row.id,
                projectName: row.name,
                projectStatus: row.status,
                clientName: row.clientName,
                totalPaymentsYer: row.paymentsYer,
                totalExpensesYer: row.expensesYer,
                completedMilestones: row.completedMilestones,
                totalMilestones: row.totalMilestones,
              ))
          .toList();
    } catch (error) {
      throw DashboardLocalException(
          'Unable to read local project overview.', error);
    }
  }

  @override
  Future<List<DashboardFinanceMonth>> getFinanceTimeline({
    required DateTime referenceDate,
    int monthCount = 12,
  }) async {
    if (monthCount <= 0) {
      throw ArgumentError.value(monthCount, 'monthCount', 'Must be positive.');
    }
    try {
      final end = DateTime(referenceDate.year, referenceDate.month);
      final start = DateTime(end.year, end.month - monthCount + 1);
      final afterEnd = DateTime(end.year, end.month + 1);
      String dateKey(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-01';
      final payments =
          await _dao.getPaymentMonths(dateKey(start), dateKey(afterEnd));
      final expenses =
          await _dao.getExpenseMonths(dateKey(start), dateKey(afterEnd));
      final paymentMap = {
        for (final r in payments) '${r.year}-${r.month}': r.totalYer
      };
      final expenseMap = {
        for (final r in expenses) '${r.year}-${r.month}': r.totalYer
      };
      return List.generate(monthCount, (index) {
        final date = DateTime(start.year, start.month + index);
        final key = '${date.year}-${date.month}';
        return DashboardFinanceMonth(
          year: date.year,
          month: date.month,
          totalPaymentsYer: paymentMap[key] ?? 0,
          totalExpensesYer: expenseMap[key] ?? 0,
        );
      });
    } catch (error) {
      if (error is ArgumentError) rethrow;
      throw DashboardLocalException(
          'Unable to read local finance timeline.', error);
    }
  }
}

final dashboardDaoProvider = Provider<DashboardDao>((ref) {
  return DashboardDao(ref.watch(databaseProvider));
});

final localDashboardRepositoryProvider =
    Provider<LocalDashboardRepository>((ref) {
  return LocalDashboardRepository(ref.watch(dashboardDaoProvider));
});
