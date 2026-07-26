import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/daos/reports_dao.dart';
import 'package:construction_erp/core/database/database_provider.dart';
import 'package:construction_erp/features/reports/data/api_reports_repository.dart';
import 'package:construction_erp/features/reports/data/local_reports_repository.dart';
import 'package:construction_erp/features/reports/presentation/report_providers.dart';

const _client1 = 'aaaaaaaa-0000-4000-8000-000000000001';
const _client2 = 'aaaaaaaa-0000-4000-8000-000000000002';
const _project1 = 'bbbbbbbb-0000-4000-8000-000000000001';
const _project2 = 'bbbbbbbb-0000-4000-8000-000000000002';
const _timestamp = '2026-01-01T00:00:00Z';

Future<AppDatabase> _seededDatabase() async {
  final db = AppDatabase(NativeDatabase.memory());
  await db.into(db.clients).insert(ClientsCompanion.insert(
        id: _client1,
        name: 'Active client',
        createdAt: _timestamp,
        updatedAt: _timestamp,
      ));
  await db.into(db.clients).insert(ClientsCompanion.insert(
        id: _client2,
        name: 'Archived client',
        archived: const Value(true),
        createdAt: _timestamp,
        updatedAt: _timestamp,
      ));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
        id: _project1,
        clientId: _client1,
        name: 'Alpha',
        budgetAmountMinor: 100000,
        budgetCurrency: 'YER',
        status: const Value('active'),
        createdAt: _timestamp,
      ));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
        id: _project2,
        clientId: _client2,
        name: 'Beta archived client history',
        budgetAmountMinor: 12345,
        budgetCurrency: 'SAR',
        status: const Value('completed'),
        createdAt: _timestamp,
      ));
  return db;
}

Future<void> _payment(
  AppDatabase db, {
  required String id,
  required String projectId,
  required int original,
  required String currency,
  required int converted,
  required String date,
  bool deleted = false,
}) {
  return db.into(db.payments).insert(PaymentsCompanion.insert(
        id: id,
        projectId: projectId,
        originalAmountMinor: original,
        originalCurrency: currency,
        exchangeRateScaled: currency == 'YER' ? 1000000 : 410000000,
        convertedYerAmount: converted,
        paymentDate: date,
        method: 'cash',
        createdAt: _timestamp,
        isDeleted: Value(deleted),
      ));
}

Future<void> _expense(
  AppDatabase db, {
  required String id,
  required String projectId,
  required int original,
  required String currency,
  required int converted,
  required String date,
  String category = 'materials',
  bool deleted = false,
}) {
  return db.into(db.expenses).insert(ExpensesCompanion.insert(
        id: id,
        projectId: projectId,
        originalAmountMinor: original,
        originalCurrency: currency,
        exchangeRateScaled: currency == 'YER' ? 1000000 : 410000000,
        convertedYerAmount: converted,
        category: category,
        expenseDate: date,
        createdAt: _timestamp,
        isDeleted: Value(deleted),
      ));
}

void main() {
  test('active Reports provider resolves to local repository without Dio',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    expect(
      container.read(reportsRepositoryProvider),
      isA<LocalReportsRepository>(),
    );
    expect(container.read(apiReportsRepositoryProvider),
        isA<ApiReportsRepository>());
    container.dispose();
    await db.close();
  });

  group('filter validation', () {
    test('inclusive single-day, month, year, and leap-day ranges are accepted',
        () {
      for (final filters in [
        ReportFilters(
          startDate: DateTime(2026, 2, 2),
          endDate: DateTime(2026, 2, 2),
        ),
        ReportFilters(
          startDate: DateTime(2026, 1, 31),
          endDate: DateTime(2026, 2, 1),
        ),
        ReportFilters(
          startDate: DateTime(2025, 12, 31),
          endDate: DateTime(2026, 1, 1),
        ),
        ReportFilters(
          startDate: DateTime(2024, 2, 29),
          endDate: DateTime(2024, 2, 29),
        ),
      ]) {
        expect(filters.validate, returnsNormally);
      }
    });

    test('start after end is rejected', () {
      final filters = ReportFilters(
        startDate: DateTime(2026, 2, 2),
        endDate: DateTime(2026, 2, 1),
      );
      expect(filters.validate, throwsA(isA<ReportFilterException>()));
    });

    test('invalid project and status are rejected', () {
      expect(
        const ReportFilters(projectId: 'bad').validate,
        throwsA(isA<ReportFilterException>()),
      );
      expect(
        const ReportFilters(status: 'unknown').validate,
        throwsA(isA<ReportFilterException>()),
      );
    });

    test('date equality ignores time-of-day', () {
      expect(
        ReportFilters(startDate: DateTime(2026, 2, 1, 23)),
        ReportFilters(startDate: DateTime(2026, 2, 1, 1)),
      );
    });
  });

  test('empty reports return zero totals and project zero rows', () async {
    final db = await _seededDatabase();
    final repo = LocalReportsRepository(ReportsDao(db));
    final finance = await repo.generate(
      const ReportFilters(type: ReportType.financialSummary),
    ) as FinancialSummaryReport;
    expect(finance.totalPaymentsYer, 0);
    expect(finance.totalExpensesYer, 0);
    expect(finance.netCashFlowYer, 0);
    expect(finance.perProject, hasLength(2));
    final expense = await repo.generate(
      const ReportFilters(type: ReportType.expenseAnalysis),
    ) as ExpenseAnalysisReport;
    expect(expense.grandTotalYer, 0);
    expect(expense.byCategory, isEmpty);
    await db.close();
  });

  test('stored YER snapshots are exact and deleted rows are excluded',
      () async {
    final db = await _seededDatabase();
    await _payment(
      db,
      id: 'cccccccc-0000-4000-8000-000000000001',
      projectId: _project1,
      original: 10000,
      currency: 'SAR',
      converted: 41000,
      date: '2026-02-01',
    );
    await _payment(
      db,
      id: 'cccccccc-0000-4000-8000-000000000002',
      projectId: _project1,
      original: 999999,
      currency: 'YER',
      converted: 999999,
      date: '2026-02-01',
      deleted: true,
    );
    await _expense(
      db,
      id: 'dddddddd-0000-4000-8000-000000000001',
      projectId: _project1,
      original: 250,
      currency: 'SAR',
      converted: 1025,
      date: '2026-02-01',
    );
    final report = await LocalReportsRepository(ReportsDao(db)).generate(
      const ReportFilters(type: ReportType.financialSummary),
    ) as FinancialSummaryReport;
    expect(report.totalPaymentsYer, 41000);
    expect(report.totalExpensesYer, 1025);
    expect(report.netCashFlowYer, 39975);
    await db.close();
  });

  test('inclusive date filters use transaction dates, not createdAt', () async {
    final db = await _seededDatabase();
    for (final entry in const [
      ('1', '2026-01-31', 1),
      ('2', '2026-02-01', 2),
      ('3', '2026-02-28', 3),
      ('4', '2026-03-01', 4),
    ]) {
      await _payment(
        db,
        id: 'cccccccc-0000-4000-8000-00000000000${entry.$1}',
        projectId: _project1,
        original: entry.$3,
        currency: 'YER',
        converted: entry.$3,
        date: entry.$2,
      );
    }
    final report = await LocalReportsRepository(ReportsDao(db)).generate(
      ReportFilters(
        type: ReportType.financialSummary,
        startDate: DateTime(2026, 2, 1, 23, 59),
        endDate: DateTime(2026, 2, 28, 1),
      ),
    ) as FinancialSummaryReport;
    expect(report.totalPaymentsYer, 5);
    await db.close();
  });

  test('multiple payment and expense rows never multiply', () async {
    final db = await _seededDatabase();
    for (var i = 1; i <= 3; i++) {
      await _payment(
        db,
        id: 'cccccccc-0000-4000-8000-00000000000$i',
        projectId: _project1,
        original: i * 100,
        currency: 'YER',
        converted: i * 100,
        date: '2026-02-0$i',
      );
      await _expense(
        db,
        id: 'dddddddd-0000-4000-8000-00000000000$i',
        projectId: _project1,
        original: i * 10,
        currency: 'YER',
        converted: i * 10,
        date: '2026-02-0$i',
      );
    }
    final rows = (await LocalReportsRepository(ReportsDao(db)).generate(
      const ReportFilters(type: ReportType.projectStatus),
    ) as ProjectStatusReport)
        .items;
    expect(rows.first.totalPaymentsYer, 600);
    expect(rows.first.totalExpensesYer, 60);
    await db.close();
  });

  test('milestone progress excludes overdue and handles zero totals', () async {
    final db = await _seededDatabase();
    await db.into(db.milestones).insert(MilestonesCompanion.insert(
          id: 'eeeeeeee-0000-4000-8000-000000000001',
          projectId: _project1,
          title: 'Done',
          dueDate: '2026-01-01',
          status: const Value('completed'),
          createdAt: _timestamp,
        ));
    await db.into(db.milestones).insert(MilestonesCompanion.insert(
          id: 'eeeeeeee-0000-4000-8000-000000000002',
          projectId: _project1,
          title: 'Overdue',
          dueDate: '2026-01-02',
          status: const Value('overdue'),
          createdAt: _timestamp,
        ));
    final report = await LocalReportsRepository(ReportsDao(db)).generate(
      const ReportFilters(type: ReportType.projectStatus),
    ) as ProjectStatusReport;
    expect(report.items.first.progressBasisPoints, 5000);
    expect(report.items.last.progressBasisPoints, 0);
    await db.close();
  });

  test('project and status filters combine with logical AND', () async {
    final db = await _seededDatabase();
    final repo = LocalReportsRepository(ReportsDao(db));
    final match = await repo.generate(const ReportFilters(
      type: ReportType.projectStatus,
      projectId: _project1,
      status: 'active',
    )) as ProjectStatusReport;
    expect(match.items.single.projectId, _project1);
    final noMatch = await repo.generate(const ReportFilters(
      type: ReportType.projectStatus,
      projectId: _project1,
      status: 'completed',
    )) as ProjectStatusReport;
    expect(noMatch.items, isEmpty);
    await db.close();
  });

  test('archived client historical project remains reportable', () async {
    final db = await _seededDatabase();
    final report = await LocalReportsRepository(ReportsDao(db)).generate(
      const ReportFilters(
        type: ReportType.projectStatus,
        projectId: _project2,
      ),
    ) as ProjectStatusReport;
    expect(report.items.single.name, contains('archived client'));
    await db.close();
  });

  test('expense categories and per-project shares are exact with zero guard',
      () async {
    final db = await _seededDatabase();
    await _expense(
      db,
      id: 'dddddddd-0000-4000-8000-000000000001',
      projectId: _project1,
      original: 1,
      currency: 'YER',
      converted: 1,
      date: '2026-02-01',
      category: 'labor',
    );
    await _expense(
      db,
      id: 'dddddddd-0000-4000-8000-000000000002',
      projectId: _project1,
      original: 3,
      currency: 'YER',
      converted: 3,
      date: '2026-02-01',
      category: 'materials',
    );
    final report = await LocalReportsRepository(ReportsDao(db)).generate(
      const ReportFilters(type: ReportType.expenseAnalysis),
    ) as ExpenseAnalysisReport;
    expect(report.grandTotalYer, 4);
    expect(report.byCategory.first.shareBasisPoints, 2500);
    expect(report.byCategory.last.shareBasisPoints, 7500);
    expect(report.byProject.single.totalExpensesYer, 4);
    await db.close();
  });

  test('unknown well-formed project ID produces a clear error', () async {
    final db = await _seededDatabase();
    expect(
      LocalReportsRepository(ReportsDao(db)).generate(
        const ReportFilters(
          projectId: 'ffffffff-0000-4000-8000-000000000001',
        ),
      ),
      throwsA(
        isA<ReportFilterException>().having(
          (error) => error.message,
          'message',
          contains('not found'),
        ),
      ),
    );
    await db.close();
  });
}
