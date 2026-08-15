import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/daos/dashboard_dao.dart';
import 'package:construction_erp/features/dashboard/data/local_dashboard_repository.dart';
import 'package:construction_erp/core/database/database_provider.dart';
import 'package:construction_erp/features/dashboard/presentation/dashboard_providers.dart';
import 'package:construction_erp/features/transfers/domain/wallet_balance_service.dart';

LocalDashboardRepository _repo(AppDatabase db) => LocalDashboardRepository(
      DashboardDao(db),
      WalletBalanceService(
        db.paymentsDao,
        db.expensesDao,
        db.currencyTransfersDao,
      ),
    );

const client1 = 'aaaaaaaa-0000-4000-8000-000000000001';
const client2 = 'aaaaaaaa-0000-4000-8000-000000000002';
const project1 = 'bbbbbbbb-0000-4000-8000-000000000001';
const project2 = 'bbbbbbbb-0000-4000-8000-000000000002';
const ts = '2026-01-01T00:00:00Z';

Future<AppDatabase> seededDatabase() async {
  final db = AppDatabase(NativeDatabase.memory());
  await db.into(db.clients).insert(ClientsCompanion.insert(
      id: client1, name: 'Active client', createdAt: ts, updatedAt: ts));
  await db.into(db.clients).insert(ClientsCompanion.insert(
      id: client2,
      name: 'Archived client',
      archived: const Value(true),
      createdAt: ts,
      updatedAt: ts));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
      id: project1,
      clientId: client1,
      name: 'Alpha',
      budgetAmountMinor: 0,
      budgetCurrency: 'YER',
      status: const Value('active'),
      createdAt: ts));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
      id: project2,
      clientId: client2,
      name: 'Beta',
      budgetAmountMinor: 0,
      budgetCurrency: 'YER',
      status: const Value('completed'),
      createdAt: ts));
  return db;
}

void main() {
  test('active Dashboard provider resolves to local repository without Dio',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    expect(
      container.read(dashboardRepositoryProvider),
      isA<LocalDashboardRepository>(),
    );
    container.dispose();
    await db.close();
  });

  test('empty database returns zero summary and 12 zero-filled months',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = _repo(db);
    final summary = await repo.getSummary();
    expect(summary.activeClientCount, 0);
    expect(summary.netCashFlowYer, 0);
    final months =
        await repo.getFinanceTimeline(referenceDate: DateTime(2026, 3, 31));
    expect(months, hasLength(12));
    expect(months.first.canonicalKey, '2025-04');
    expect(months.last.canonicalKey, '2026-03');
    expect(
        months.every((m) => m.totalPaymentsYer == 0 && m.totalExpensesYer == 0),
        true);
    await db.close();
  });

  test('summary excludes archived clients and soft-deleted finance', () async {
    final db = await seededDatabase();
    await db.into(db.payments).insert(PaymentsCompanion.insert(
        id: 'cccccccc-0000-4000-8000-000000000001',
        projectId: project1,
        originalAmountMinor: 500,
        originalCurrency: 'YER',
        exchangeRateScaled: 1000000,
        convertedYerAmount: 500,
        paymentDate: '2026-02-10',
        method: 'cash',
        createdAt: ts));
    await db.into(db.payments).insert(PaymentsCompanion.insert(
        id: 'cccccccc-0000-4000-8000-000000000002',
        projectId: project1,
        originalAmountMinor: 999,
        originalCurrency: 'YER',
        exchangeRateScaled: 1000000,
        convertedYerAmount: 999,
        paymentDate: '2026-02-11',
        method: 'cash',
        createdAt: ts,
        isDeleted: const Value(true)));
    await db.into(db.expenses).insert(ExpensesCompanion.insert(
        id: 'dddddddd-0000-4000-8000-000000000001',
        projectId: project1,
        originalAmountMinor: 700,
        originalCurrency: 'YER',
        exchangeRateScaled: 1000000,
        convertedYerAmount: 700,
        category: 'labor',
        expenseDate: '2026-02-12',
        createdAt: ts));
    final summary =
        await _repo(db).getSummary();
    expect(summary.activeClientCount, 1);
    expect(summary.totalProjectCount, 2);
    expect(summary.activeProjectCount, 1);
    expect(summary.completedProjectCount, 1);
    expect(summary.onHoldProjectCount, 0);
    expect(summary.planningProjectCount, 0);
    expect(summary.cancelledProjectCount, 0);
    expect(summary.statusCountsConsistent, true);
    expect(summary.totalPaymentsYer, 500);
    expect(summary.totalExpensesYer, 700);
    expect(summary.netCashFlowYer, -200);
    await db.close();
  });

  test('project aggregates are independent and milestone progress is exact',
      () async {
    final db = await seededDatabase();
    for (var i = 1; i <= 2; i++) {
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-00000000000$i',
          projectId: project1,
          originalAmountMinor: 100 * i,
          originalCurrency: 'YER',
          exchangeRateScaled: 1000000,
          convertedYerAmount: 100 * i,
          paymentDate: '2026-02-0$i',
          method: 'cash',
          createdAt: ts));
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'dddddddd-0000-4000-8000-00000000000$i',
          projectId: project1,
          originalAmountMinor: 10 * i,
          originalCurrency: 'YER',
          exchangeRateScaled: 1000000,
          convertedYerAmount: 10 * i,
          category: 'labor',
          expenseDate: '2026-02-0$i',
          createdAt: ts));
    }
    await db.into(db.milestones).insert(MilestonesCompanion.insert(
        id: 'eeeeeeee-0000-4000-8000-000000000001',
        projectId: project1,
        title: 'Done',
        dueDate: '2026-02-01',
        status: const Value('completed'),
        createdAt: ts));
    await db.into(db.milestones).insert(MilestonesCompanion.insert(
        id: 'eeeeeeee-0000-4000-8000-000000000002',
        projectId: project1,
        title: 'Overdue',
        dueDate: '2026-02-02',
        status: const Value('overdue'),
        createdAt: ts));
    final projects =
        await _repo(db).getProjectsOverview();
    final alpha = projects.first;
    expect(alpha.totalPaymentsYer, 300);
    expect(alpha.totalExpensesYer, 30);
    expect(alpha.netCashFlowYer, 270);
    expect(alpha.milestoneProgressPercent, 50);
    expect(projects.last.totalPaymentsYer, 0);
    await db.close();
  });

  test('timeline crosses December and zero-fills missing months', () async {
    final db = await seededDatabase();
    await db.into(db.payments).insert(PaymentsCompanion.insert(
        id: 'cccccccc-0000-4000-8000-000000000001',
        projectId: project1,
        originalAmountMinor: 410000,
        originalCurrency: 'SAR',
        exchangeRateScaled: 410000000,
        convertedYerAmount: 410000,
        paymentDate: '2025-12-31',
        method: 'cash',
        createdAt: ts));
    final months = await _repo(db)
        .getFinanceTimeline(
            referenceDate: DateTime(2026, 2, 28), monthCount: 3);
    expect(
        months.map((m) => m.canonicalKey), ['2025-12', '2026-01', '2026-02']);
    expect(months.map((m) => m.totalPaymentsYer), [410000, 0, 0]);
    await db.close();
  });
}
