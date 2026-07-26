import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/uuid/uuid_util.dart';
import 'package:construction_erp/features/expenses/data/local_expense_repository.dart';
import 'package:construction_erp/features/expenses/data/expense_mapper.dart';
import 'package:construction_erp/features/expenses/domain/expense_repository_interface.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _expenseId = 'eeeeeeee-0000-4000-8000-000000000001';
const _ts = '2026-01-15T10:00:00Z';
const _date = '2026-03-15';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seedClientAndProject(AppDatabase db) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
      id: _clientId, name: 'Test Client', createdAt: _ts, updatedAt: _ts));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
      id: _projectId,
      clientId: _clientId,
      name: 'Test Project',
      budgetAmountMinor: 1000000,
      budgetCurrency: kCurrencyYer,
      createdAt: _ts));
}

LocalExpenseRepository _repo(AppDatabase db) =>
    LocalExpenseRepository(db.expensesDao, db.projectsDao, db);

void main() {
  group('LocalExpenseRepository CRUD', () {
    test('Create YER expense', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      expect(exp.originalAmountMinor, 150000);
      expect(exp.originalCurrency, kCurrencyYer);
      expect(exp.exchangeRateScaled, kIdentityExchangeRate);
      expect(exp.convertedYerAmount, 150000);
      expect(exp.rateSource, kRateSourceIdentity);
      expect(UuidUtil.isValid(exp.id), true);
      await db.close();
    });

    test('Create SAR expense with rate', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'labor',
          originalAmountMinor: 50000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          expenseDate: _date);
      expect(exp.originalAmountMinor, 50000);
      expect(exp.originalCurrency, kCurrencySar);
      expect(exp.convertedYerAmount, 205000);
      await db.close();
    });

    test('Get expense by ID', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      final found = await repo.getById(created.id);
      expect(found, isNotNull);
      expect(found!.category, 'materials');
      await db.close();
    });

    test('List active expenses by project', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 100,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.create(
          projectId: _projectId,
          category: 'labor',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: '2026-03-16');
      final list = await repo.listByProject(_projectId);
      expect(list.length, 2);
      await db.close();
    });

    test('Update expense', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      final updated = await repo.update(id: created.id, category: 'labor');
      expect(updated.category, 'labor');
      await db.close();
    });

    test('Soft-delete expense', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.softDelete(created.id);
      final active = await repo.listByProject(_projectId);
      expect(active.length, 0);
      await db.close();
    });

    test('Soft-deleted expense excluded from financial total', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.softDelete(created.id);
      final total = await repo.totalActiveExpensesYer(_projectId);
      expect(total, 0);
      await db.close();
    });

    test('Restore expense', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.softDelete(created.id);
      await repo.restore(created.id);
      final active = await repo.listByProject(_projectId);
      expect(active.length, 1);
      await db.close();
    });

    test('Repeated soft delete is deterministic', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.softDelete(created.id);
      await repo.softDelete(created.id); // Should not throw
      await db.close();
    });

    test('Repeated restore is deterministic', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.softDelete(created.id);
      await repo.restore(created.id);
      await repo.restore(created.id); // Should not throw
      await db.close();
    });
  });

  group('categories', () {
    for (final cat in ['materials', 'labor', 'equipment', 'permits', 'other']) {
      test('$cat accepted', () async {
        final db = _createDb();
        await _seedClientAndProject(db);
        final repo = _repo(db);
        final exp = await repo.create(
            projectId: _projectId,
            category: cat,
            originalAmountMinor: 100,
            originalCurrency: kCurrencyYer,
            expenseDate: _date);
        expect(exp.category, cat);
        await db.close();
      });
    }

    test('Invalid category rejected', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      expect(
        () => repo.create(
            projectId: _projectId,
            category: 'invalid',
            originalAmountMinor: 100,
            originalCurrency: kCurrencyYer,
            expenseDate: _date),
        throwsArgumentError,
      );
      await db.close();
    });
  });

  group('currency and conversion', () {
    test('1000 SAR × 410 = 410000 YER', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          expenseDate: _date);
      expect(exp.convertedYerAmount, 410000);
      await db.close();
    });

    test('1000.50 SAR × 410 = 410205 YER', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 100050,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          expenseDate: _date);
      expect(exp.convertedYerAmount, 410205);
      await db.close();
    });

    test('YER identity rate enforced', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      expect(exp.exchangeRateScaled, kIdentityExchangeRate);
      expect(exp.convertedYerAmount, exp.originalAmountMinor);
      await db.close();
    });

    test('SAR requires positive rate', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      expect(
        () => repo.create(
            projectId: _projectId,
            category: 'materials',
            originalAmountMinor: 100,
            originalCurrency: kCurrencySar,
            expenseDate: _date),
        throwsArgumentError,
      );
      await db.close();
    });

    test('Unsupported currency rejected', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      expect(
        () => repo.create(
            projectId: _projectId,
            category: 'materials',
            originalAmountMinor: 100,
            originalCurrency: 'USD',
            expenseDate: _date),
        throwsArgumentError,
      );
      await db.close();
    });

    test('Zero amount rejected', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      expect(
        () => repo.create(
            projectId: _projectId,
            category: 'materials',
            originalAmountMinor: 0,
            originalCurrency: kCurrencyYer,
            expenseDate: _date),
        throwsArgumentError,
      );
      await db.close();
    });
  });

  group('project policy', () {
    test('Fixed SAR project uses project rate', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
          id: _clientId, name: 'Client', createdAt: _ts, updatedAt: _ts));
      await db.into(db.projects).insert(ProjectsCompanion.insert(
          id: _projectId,
          clientId: _clientId,
          name: 'SAR Fixed Project',
          budgetAmountMinor: 100000,
          budgetCurrency: kCurrencySar,
          exchangePolicy: const Value(kExchangePolicyFixed),
          fixedExchangeRateScaled: const Value(420000000),
          createdAt: _ts));
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 50000,
          originalCurrency: kCurrencySar,
          expenseDate: _date);
      expect(exp.exchangeRateScaled, 420000000);
      expect(exp.rateSource, kRateSourceProject);
      await db.close();
    });

    test('Default rate change does not alter historical expense', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          expenseDate: _date);
      await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          id: 'app',
          defaultExchangeRateScaled: const Value(999000000),
          createdAt: _ts,
          updatedAt: _ts));
      final found = await repo.getById(exp.id);
      expect(found!.exchangeRateScaled, 410000000);
      await db.close();
    });
  });

  group('soft-delete safety', () {
    test('Active expense blocks project deletion', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      expect(() => db.projectsDao.deleteProject(_projectId),
          throwsA(isA<Object>()));
      await db.close();
    });

    test('Soft-deleted expense still blocks project deletion', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.softDelete(exp.id);
      expect(() => db.projectsDao.deleteProject(_projectId),
          throwsA(isA<Object>()));
      await db.close();
    });

    test('Deleting expense never deletes project', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.softDelete(exp.id);
      final project = await db.projectsDao.getProjectById(_projectId);
      expect(project, isNotNull);
      await db.close();
    });
  });

  group('expense groups', () {
    test('Two currency lines share one expense_group_id', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      const groupId = 'grp-exp-0001';
      await repo.create(
          projectId: _projectId,
          expenseGroupId: groupId,
          category: 'materials',
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.create(
          projectId: _projectId,
          expenseGroupId: groupId,
          category: 'materials',
          originalAmountMinor: 50000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          expenseDate: _date);
      final expenses = await repo.listByProject(_projectId);
      expect(expenses.length, 2);
      expect(expenses.every((e) => e.expenseGroupId == groupId), true);
      final totalYer =
          expenses.fold<int>(0, (sum, e) => sum + e.convertedYerAmount);
      expect(totalYer, 150000 + 205000);
      await db.close();
    });

    test('Group soft delete is atomic', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      const groupId = 'grp-exp-0002';
      await repo.create(
          projectId: _projectId,
          expenseGroupId: groupId,
          category: 'materials',
          originalAmountMinor: 100000,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.create(
          projectId: _projectId,
          expenseGroupId: groupId,
          category: 'materials',
          originalAmountMinor: 50000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          expenseDate: _date);
      await repo.softDeleteGroup(groupId);
      final active = await repo.listByProject(_projectId);
      expect(active.length, 0);
      await db.close();
    });

    test('Group restore is atomic', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      const groupId = 'grp-exp-0003';
      await repo.create(
          projectId: _projectId,
          expenseGroupId: groupId,
          category: 'materials',
          originalAmountMinor: 100000,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo.create(
          projectId: _projectId,
          expenseGroupId: groupId,
          category: 'materials',
          originalAmountMinor: 50000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          expenseDate: _date);
      await repo.softDeleteGroup(groupId);
      await repo.restoreGroup(groupId);
      final active = await repo.listByProject(_projectId);
      expect(active.length, 2);
      await db.close();
    });
  });

  group('persistence', () {
    test('Expense persists after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p07_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found, isNotNull);
      expect(found!.originalAmountMinor, 150000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Soft-delete state persists after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p07_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      await repo1.softDelete(created.id);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final active = await repo2.listByProject(_projectId);
      expect(active.length, 0);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Exchange-rate snapshot persists after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p07_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          expenseDate: _date);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found!.exchangeRateScaled, 410000000);
      expect(found.convertedYerAmount, 410000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });

  group('mapping', () {
    test('Row maps exactly to entity', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: _expenseId,
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 150000,
          expenseDate: _date,
          createdAt: _ts));
      final row = await db.expensesDao.getExpenseById(_expenseId);
      final entity = ExpenseMapper.rowToEntity(row!);
      expect(entity.id, _expenseId);
      expect(entity.category, 'materials');
      expect(entity.originalAmountMinor, 150000);
      expect(entity.isDeleted, false);
      expect(entity.deletedAt, isNull);
      await db.close();
    });

    test('Nullable notes round-trip', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      final found = await repo.getById(created.id);
      expect(found!.notes, isNull);
      await db.close();
    });
  });

  group('interface compliance', () {
    test('LocalExpenseRepository implements ExpenseRepositoryInterface', () {
      final db = _createDb();
      final repo = _repo(db);
      expect(repo, isA<ExpenseRepositoryInterface>());
      db.close();
    });
  });

  group('transitional regression', () {
    test('Local Client → Project → Expense succeeds', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final exp = await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      expect(exp.projectId, _projectId);
      final found = await repo.getById(exp.id);
      expect(found, isNotNull);
      await db.close();
    });

    test('Orphan expense rejected', () async {
      final db = _createDb();
      final repo = _repo(db);
      expect(
        () => repo.create(
            projectId: 'nonexistent-0000-4000-8000-000000000000',
            category: 'materials',
            originalAmountMinor: 100,
            originalCurrency: kCurrencyYer,
            expenseDate: _date),
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
  });

  group('financial summary', () {
    test('Active total excludes soft-deleted', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      await repo.create(
          projectId: _projectId,
          category: 'materials',
          originalAmountMinor: 600,
          originalCurrency: kCurrencyYer,
          expenseDate: _date);
      final e2 = await repo.create(
          projectId: _projectId,
          category: 'labor',
          originalAmountMinor: 400,
          originalCurrency: kCurrencyYer,
          expenseDate: '2026-03-16');
      final total1 = await repo.totalActiveExpensesYer(_projectId);
      expect(total1, 1000);
      await repo.softDelete(e2.id);
      final total2 = await repo.totalActiveExpensesYer(_projectId);
      expect(total2, 600);
      await db.close();
    });
  });
}
