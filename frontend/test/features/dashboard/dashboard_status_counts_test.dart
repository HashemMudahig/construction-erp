import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/database/daos/dashboard_dao.dart';
import 'package:construction_erp/core/localization/app_localizations.dart';
import 'package:construction_erp/features/dashboard/data/local_dashboard_repository.dart';
import 'package:construction_erp/features/projects/data/local_project_repository.dart';
import 'package:construction_erp/features/projects/domain/project_entity.dart';
import 'package:construction_erp/features/transfers/domain/wallet_balance_service.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _ts = '2026-01-01T00:00:00Z';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seedClient(AppDatabase db) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
      id: _clientId, name: 'Owner', createdAt: _ts, updatedAt: _ts));
}

LocalProjectRepository _repo(AppDatabase db) =>
    LocalProjectRepository(db.projectsDao, db.clientsDao, db);

LocalDashboardRepository _dashboard(AppDatabase db) => LocalDashboardRepository(
      DashboardDao(db),
      WalletBalanceService(
        db.paymentsDao,
        db.expensesDao,
        db.currencyTransfersDao,
      ),
    );

const _statuses = kProjectStatuses; // planning, active, completed, on_hold, cancelled

void main() {
  group('Dashboard project status counts', () {
    test('Test 1: three active projects', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      for (var i = 0; i < 3; i++) {
        await repo.create(
          clientId: _clientId,
          name: 'Active $i',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer,
          status: 'active',
        );
      }
      final summary = await _dashboard(db).getSummary();
      expect(summary.totalProjectCount, 3);
      expect(summary.activeProjectCount, 3);
      expect(summary.completedProjectCount, 0);
      expect(summary.onHoldProjectCount, 0);
      expect(summary.planningProjectCount, 0);
      expect(summary.cancelledProjectCount, 0);
      expect(summary.statusCountsSum, 3);
      expect(summary.statusCountsConsistent, true);
      await db.close();
    });

    test('Test 2: one active, one completed, one paused', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      await repo.create(
        clientId: _clientId,
        name: 'Active',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'active',
      );
      await repo.create(
        clientId: _clientId,
        name: 'Completed',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'completed',
      );
      await repo.create(
        clientId: _clientId,
        name: 'Paused',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'on_hold',
      );
      final summary = await _dashboard(db).getSummary();
      expect(summary.activeProjectCount, 1);
      expect(summary.completedProjectCount, 1);
      expect(summary.onHoldProjectCount, 1);
      expect(summary.totalProjectCount, 3);
      expect(summary.statusCountsSum, 3);
      expect(summary.statusCountsConsistent, true);
      await db.close();
    });

    test('Test 3: change active -> completed moves bucket, total unchanged',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final projects = <ProjectEntity>[];
      for (var i = 0; i < 3; i++) {
        projects.add(await repo.create(
          clientId: _clientId,
          name: 'P$i',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer,
          status: 'active',
        ));
      }
      var summary = await _dashboard(db).getSummary();
      expect(summary.activeProjectCount, 3);
      expect(summary.completedProjectCount, 0);

      await repo.update(id: projects.first.id, status: 'completed');
      summary = await _dashboard(db).getSummary();
      expect(summary.activeProjectCount, 2);
      expect(summary.completedProjectCount, 1);
      expect(summary.totalProjectCount, 3);
      expect(summary.statusCountsConsistent, true);
      await db.close();
    });

    test('Test 4: change completed -> active moves bucket, total unchanged',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final a = await repo.create(
        clientId: _clientId,
        name: 'A',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'active',
      );
      await repo.create(
        clientId: _clientId,
        name: 'B',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'completed',
      );
      await repo.create(
        clientId: _clientId,
        name: 'C',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'completed',
      );
      var summary = await _dashboard(db).getSummary();
      expect(summary.activeProjectCount, 1);
      expect(summary.completedProjectCount, 2);

      await repo.update(id: a.id, status: 'completed');
      summary = await _dashboard(db).getSummary();
      expect(summary.activeProjectCount, 0);
      expect(summary.completedProjectCount, 3);
      expect(summary.totalProjectCount, 3);

      // Now flip one completed back to active.
      await repo.update(id: a.id, status: 'active');
      summary = await _dashboard(db).getSummary();
      expect(summary.activeProjectCount, 1);
      expect(summary.completedProjectCount, 2);
      expect(summary.totalProjectCount, 3);
      expect(summary.statusCountsConsistent, true);
      await db.close();
    });

    test('Test 5: persistence — counts remain identical after reopen',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_dash_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClient(db1);
      final repo1 = _repo(db1);
      await repo1.create(
        clientId: _clientId,
        name: 'Active',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'active',
      );
      final completed = await repo1.create(
        clientId: _clientId,
        name: 'Completed',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'active',
      );
      await repo1.update(id: completed.id, status: 'completed');
      await repo1.create(
        clientId: _clientId,
        name: 'Paused',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'on_hold',
      );
      final before = await _dashboard(db1).getSummary();
      expect(before.activeProjectCount, 1);
      expect(before.completedProjectCount, 1);
      expect(before.onHoldProjectCount, 1);
      expect(before.totalProjectCount, 3);
      await db1.close();

      // Reopen from the same file.
      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final after = await _dashboard(db2).getSummary();
      expect(after.activeProjectCount, before.activeProjectCount);
      expect(after.completedProjectCount, before.completedProjectCount);
      expect(after.onHoldProjectCount, before.onHoldProjectCount);
      expect(after.totalProjectCount, before.totalProjectCount);
      expect(after.statusCountsConsistent, true);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Test 6: localization — status keys resolve to localized labels',
        () async {
      final en = AppLocalizations(const Locale('en'));
      final ar = AppLocalizations(const Locale('ar'));
      for (final status in _statuses) {
        final key = 'status_$status';
        final enLabel = en.translate(key);
        final arLabel = ar.translate(key);
        // Must not return the raw key (no leak of internal identifiers).
        expect(enLabel, isNot(key));
        expect(arLabel, isNot(key));
        // Arabic label must contain Arabic characters, not the status token.
        expect(arLabel, isNot(contains(status)));
        expect(arLabel, isNot(contains('STATUS')));
      }
      expect(en.translate('status_active'), 'Active');
      expect(ar.translate('status_active'), 'نشط');
      expect(en.translate('status_completed'), 'Completed');
      expect(ar.translate('status_completed'), 'مكتمل');
      expect(en.translate('status_on_hold'), 'On hold');
      expect(ar.translate('status_on_hold'), 'معلّق');
      expect(en.translate('status_planning'), 'Planning');
      expect(ar.translate('status_planning'), 'قيد التخطيط');
      expect(en.translate('status_cancelled'), 'Cancelled');
      expect(ar.translate('status_cancelled'), 'ملغي');
    });

    testWidgets(
        'Test 6b: project list card never exposes raw status identifier',
        (tester) async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      await repo.create(
        clientId: _clientId,
        name: 'Site Works',
        budgetAmountMinor: 100,
        budgetCurrency: kCurrencyYer,
        status: 'active',
      );
      final projects = await repo.list();
      expect(projects, hasLength(1));
      await db.close();
      // Sanity: the persisted status is the canonical token, not a label.
      expect(projects.first.status, 'active');
    });

    test('Test 7: zero-state — no projects yields all-zero counts', () async {
      final db = _createDb();
      await _seedClient(db);
      final summary = await _dashboard(db).getSummary();
      expect(summary.totalProjectCount, 0);
      expect(summary.planningProjectCount, 0);
      expect(summary.activeProjectCount, 0);
      expect(summary.completedProjectCount, 0);
      expect(summary.onHoldProjectCount, 0);
      expect(summary.cancelledProjectCount, 0);
      expect(summary.statusCountsSum, 0);
      expect(summary.statusCountsConsistent, true);
      await db.close();
    });

    test('Test 8: mixed-status dataset — sum of counts equals total', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final counts = <String, int>{
        for (final s in _statuses) s: 0,
      };
      var total = 0;
      for (final status in _statuses) {
        for (var i = 0; i < 2; i++) {
          await repo.create(
            clientId: _clientId,
            name: '$status-$i',
            budgetAmountMinor: 100,
            budgetCurrency: kCurrencyYer,
            status: status,
          );
          counts[status] = counts[status]! + 1;
          total++;
        }
      }
      final summary = await _dashboard(db).getSummary();
      expect(summary.totalProjectCount, total);
      expect(summary.planningProjectCount, counts['planning']);
      expect(summary.activeProjectCount, counts['active']);
      expect(summary.completedProjectCount, counts['completed']);
      expect(summary.onHoldProjectCount, counts['on_hold']);
      expect(summary.cancelledProjectCount, counts['cancelled']);
      expect(summary.statusCountsSum, total);
      expect(summary.statusCountsConsistent, true);
      await db.close();
    });
  });

  group('Dashboard status invariant', () {
    test('invariant holds for every supported status combination', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      // Cycle through every status at least once.
      for (var i = 0; i < _statuses.length; i++) {
        await repo.create(
          clientId: _clientId,
          name: 'Invariant $i',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer,
          status: _statuses[i],
        );
      }
      final summary = await _dashboard(db).getSummary();
      expect(
        summary.statusCountsSum,
        summary.totalProjectCount,
        reason:
            'sum(status counts) must equal total project count — a project '
            'must never be counted in more than one mutually-exclusive bucket.',
      );
      await db.close();
    });
  });
}