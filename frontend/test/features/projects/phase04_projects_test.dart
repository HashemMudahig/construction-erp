import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/uuid/uuid_util.dart';
import 'package:construction_erp/features/projects/data/local_project_repository.dart';
import 'package:construction_erp/features/projects/data/project_mapper.dart';
import 'package:construction_erp/features/projects/domain/project_repository_interface.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _ts = '2026-01-15T10:00:00Z';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seedClient(AppDatabase db) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
      id: _clientId, name: 'Test Client', createdAt: _ts, updatedAt: _ts));
}

LocalProjectRepository _repo(AppDatabase db) =>
    LocalProjectRepository(db.projectsDao, db.clientsDao, db);

void main() {
  group('LocalProjectRepository', () {
    test('Create project', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'Test Project',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      expect(project.name, 'Test Project');
      expect(project.clientId, _clientId);
      expect(project.budgetAmountMinor, 1000000);
      expect(project.budgetCurrency, kCurrencyYer);
      expect(UuidUtil.isValid(project.id), true);
      await db.close();
    });

    test('Get project by ID', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final created = await repo.create(
          clientId: _clientId,
          name: 'Find Me',
          budgetAmountMinor: 500000,
          budgetCurrency: kCurrencyYer);
      final found = await repo.getById(created.id);
      expect(found, isNotNull);
      expect(found!.name, 'Find Me');
      await db.close();
    });

    test('List projects', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      await repo.create(
          clientId: _clientId,
          name: 'Alpha',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      await repo.create(
          clientId: _clientId,
          name: 'Beta',
          budgetAmountMinor: 200,
          budgetCurrency: kCurrencyYer);
      final list = await repo.list();
      expect(list.length, 2);
      await db.close();
    });

    test('Update project', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final created = await repo.create(
          clientId: _clientId,
          name: 'Original',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      final updated = await repo.update(id: created.id, name: 'Updated');
      expect(updated.name, 'Updated');
      await db.close();
    });

    test('Update status', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final created = await repo.create(
          clientId: _clientId,
          name: 'Status Test',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      final updated = await repo.update(id: created.id, status: 'active');
      expect(updated.status, 'active');
      await db.close();
    });

    test('Search by name', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      await repo.create(
          clientId: _clientId,
          name: 'Alpha Tower',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      await repo.create(
          clientId: _clientId,
          name: 'Beta Building',
          budgetAmountMinor: 200,
          budgetCurrency: kCurrencyYer);
      final results = await repo.list(search: 'Alpha');
      expect(results.length, 1);
      expect(results.first.name, 'Alpha Tower');
      await db.close();
    });

    test('Filter by client', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
          id: 'aaaaaaaa-0000-4000-8000-000000000002',
          name: 'Client B',
          createdAt: _ts,
          updatedAt: _ts));
      await _seedClient(db);
      final repo = _repo(db);
      await repo.create(
          clientId: _clientId,
          name: 'P1',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      await repo.create(
          clientId: 'aaaaaaaa-0000-4000-8000-000000000002',
          name: 'P2',
          budgetAmountMinor: 200,
          budgetCurrency: kCurrencyYer);
      final results = await repo.list(clientId: _clientId);
      expect(results.length, 1);
      expect(results.first.name, 'P1');
      await db.close();
    });

    test('Filter by status', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      await repo.create(
          clientId: _clientId,
          name: 'Active',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer,
          status: 'active');
      await repo.create(
          clientId: _clientId,
          name: 'Planning',
          budgetAmountMinor: 200,
          budgetCurrency: kCurrencyYer,
          status: 'planning');
      final results = await repo.list(status: 'active');
      expect(results.length, 1);
      expect(results.first.name, 'Active');
      await db.close();
    });

    test('Hard-delete empty project', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final created = await repo.create(
          clientId: _clientId,
          name: 'Delete Me',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      await repo.deleteIfEligible(created.id);
      final found = await repo.getById(created.id);
      expect(found, isNull);
      await db.close();
    });

    test('Reject deletion with milestones', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final created = await repo.create(
          clientId: _clientId,
          name: 'Has Milestones',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      await db.into(db.milestones).insert(MilestonesCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: created.id,
          title: 'M1',
          dueDate: '2026-06-01',
          createdAt: _ts));
      expect(
          () => repo.deleteIfEligible(created.id), throwsA(isA<StateError>()));
      await db.close();
    });

    test('Reject deletion with payments', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final created = await repo.create(
          clientId: _clientId,
          name: 'Has Payments',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'dddddddd-0000-4000-8000-000000000001',
          projectId: created.id,
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 500,
          paymentDate: '2026-03-15',
          method: 'cash',
          createdAt: _ts));
      expect(
          () => repo.deleteIfEligible(created.id), throwsA(isA<StateError>()));
      await db.close();
    });

    test('Reject deletion with expenses', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final created = await repo.create(
          clientId: _clientId,
          name: 'Has Expenses',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'eeeeeeee-0000-4000-8000-000000000001',
          projectId: created.id,
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 200,
          category: 'materials',
          expenseDate: '2026-03-20',
          createdAt: _ts));
      expect(
          () => repo.deleteIfEligible(created.id), throwsA(isA<StateError>()));
      await db.close();
    });

    test('Orphan project rejected (non-existent client)', () async {
      final db = _createDb();
      final repo = _repo(db);
      expect(
        () => repo.create(
            clientId: 'nonexistent-0000-4000-8000-000000000000',
            name: 'Orphan',
            budgetAmountMinor: 100,
            budgetCurrency: kCurrencyYer),
        throwsArgumentError,
      );
      await db.close();
    });

    test('Invalid UUID rejected', () async {
      final db = _createDb();
      final repo = _repo(db);
      expect(() => repo.getById('bad-uuid'), throwsArgumentError);
      await db.close();
    });

    test('Blank name rejected', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      expect(
          () => repo.create(
              clientId: _clientId,
              name: '  ',
              budgetAmountMinor: 100,
              budgetCurrency: kCurrencyYer),
          throwsArgumentError);
      await db.close();
    });
  });

  group('multi-currency', () {
    test('YER budget exact round-trip', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'YER Project',
          budgetAmountMinor: 1500000,
          budgetCurrency: kCurrencyYer);
      final found = await repo.getById(project.id);
      expect(found!.budgetAmountMinor, 1500000);
      expect(found.budgetCurrency, kCurrencyYer);
      await db.close();
    });

    test('SAR budget round-trip', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'SAR Project',
          budgetAmountMinor: 15000050,
          budgetCurrency: kCurrencySar,
          exchangePolicy: kExchangePolicyPerTransaction);
      final found = await repo.getById(project.id);
      expect(found!.budgetAmountMinor, 15000050);
      expect(found.budgetCurrency, kCurrencySar);
      await db.close();
    });

    test('Fixed SAR policy requires positive rate', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      expect(
        () => repo.create(
            clientId: _clientId,
            name: 'Fixed SAR No Rate',
            budgetAmountMinor: 100000,
            budgetCurrency: kCurrencySar,
            exchangePolicy: kExchangePolicyFixed,
            fixedExchangeRateScaled: null),
        throwsArgumentError,
      );
      await db.close();
    });

    test('Per-transaction SAR accepts no fixed rate', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'Per Tx SAR',
          budgetAmountMinor: 100000,
          budgetCurrency: kCurrencySar,
          exchangePolicy: kExchangePolicyPerTransaction);
      expect(project.fixedExchangeRateScaled, isNull);
      await db.close();
    });

    test('Fixed rate with valid positive value accepted', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'Fixed SAR',
          budgetAmountMinor: 100000,
          budgetCurrency: kCurrencySar,
          exchangePolicy: kExchangePolicyFixed,
          fixedExchangeRateScaled: 410000000);
      expect(project.fixedExchangeRateScaled, 410000000);
      await db.close();
    });
  });

  group('profitability', () {
    test('Empty records return zero', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'Empty',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      final summary = await repo.getFinancialSummary(project.id);
      expect(summary.totalPaymentsYer, 0);
      expect(summary.totalExpensesYer, 0);
      expect(summary.balance, 0);
      expect(summary.profitMargin, 0.0);
      await db.close();
    });

    test('Aggregation without Cartesian multiplication', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'With Data',
          budgetAmountMinor: 100000,
          budgetCurrency: kCurrencyYer);

      // Insert 2 payments and 2 expenses
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'dddddddd-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 600,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 600,
          paymentDate: '2026-03-01',
          method: 'cash',
          createdAt: _ts));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'dddddddd-0000-4000-8000-000000000002',
          projectId: project.id,
          originalAmountMinor: 400,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 400,
          paymentDate: '2026-03-02',
          method: 'cash',
          createdAt: _ts));
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'eeeeeeee-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 200,
          category: 'materials',
          expenseDate: '2026-03-03',
          createdAt: _ts));
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'eeeeeeee-0000-4000-8000-000000000002',
          projectId: project.id,
          originalAmountMinor: 100,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 100,
          category: 'labor',
          expenseDate: '2026-03-04',
          createdAt: _ts));

      final summary = await repo.getFinancialSummary(project.id);
      expect(summary.totalPaymentsYer, 1000); // 600 + 400
      expect(summary.totalExpensesYer, 300); // 200 + 100
      expect(summary.balance, 700);
      // margin = 700/1000 = 0.7
      expect((summary.profitMargin * 100).round(), 70);
      await db.close();
    });

    test('Zero payment margin is guarded', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'No Payments',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      final summary = await repo.getFinancialSummary(project.id);
      expect(summary.profitMargin, 0.0);
      await db.close();
    });
  });

  group('persistence', () {
    test('Project remains after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p04_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClient(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          clientId: _clientId,
          name: 'Persistent',
          budgetAmountMinor: 500000,
          budgetCurrency: kCurrencyYer);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found, isNotNull);
      expect(found!.name, 'Persistent');
      expect(found.budgetAmountMinor, 500000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Client relationship remains after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p04_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClient(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          clientId: _clientId,
          name: 'Rel Test',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found!.clientId, _clientId);
      final client = await db2.clientsDao.getClientById(_clientId);
      expect(client, isNotNull);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Exchange policy and fixed rate remain after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p04_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClient(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          clientId: _clientId,
          name: 'SAR Fixed',
          budgetAmountMinor: 100000,
          budgetCurrency: kCurrencySar,
          exchangePolicy: kExchangePolicyFixed,
          fixedExchangeRateScaled: 410000000);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found!.exchangePolicy, kExchangePolicyFixed);
      expect(found.fixedExchangeRateScaled, 410000000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });

  group('mapping', () {
    test('Row maps exactly to entity', () async {
      final db = _createDb();
      await _seedClient(db);
      await db.into(db.projects).insert(ProjectsCompanion.insert(
          id: _projectId,
          clientId: _clientId,
          name: 'Test',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer,
          exchangePolicy: const Value('per_transaction'),
          createdAt: _ts));
      final row = await db.projectsDao.getProjectById(_projectId);
      final entity = ProjectMapper.rowToEntity(row!);
      expect(entity.id, _projectId);
      expect(entity.clientId, _clientId);
      expect(entity.name, 'Test');
      expect(entity.budgetAmountMinor, 1000000);
      expect(entity.budgetCurrency, kCurrencyYer);
      expect(entity.status, 'planning');
      await db.close();
    });

    test('Nullable fields round-trip', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'Nullables',
          budgetAmountMinor: 100,
          budgetCurrency: kCurrencyYer);
      final found = await repo.getById(project.id);
      expect(found!.description, isNull);
      expect(found.startDate, isNull);
      expect(found.endDate, isNull);
      expect(found.fixedExchangeRateScaled, isNull);
      await db.close();
    });
  });

  group('interface compliance', () {
    test('LocalProjectRepository implements ProjectRepositoryInterface', () {
      final db = _createDb();
      final repo = _repo(db);
      expect(repo, isA<ProjectRepositoryInterface>());
      db.close();
    });
  });

  group('transitional regression: local client creates local project', () {
    test('Local Client → local Project works end-to-end', () async {
      final db = _createDb();
      // Create local client
      await db.into(db.clients).insert(ClientsCompanion.insert(
          id: _clientId, name: 'Local Client', createdAt: _ts, updatedAt: _ts));
      // Create local project using that client
      final repo = _repo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'Local Project',
          budgetAmountMinor: 500000,
          budgetCurrency: kCurrencyYer);
      expect(project.clientId, _clientId);
      // Verify persistence
      final found = await repo.getById(project.id);
      expect(found, isNotNull);
      expect(found!.name, 'Local Project');
      await db.close();
    });
  });
}
