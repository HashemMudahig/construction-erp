import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/uuid/uuid_util.dart';
import 'package:construction_erp/features/payments/data/local_payment_repository.dart';
import 'package:construction_erp/features/payments/data/payment_mapper.dart';
import 'package:construction_erp/features/payments/domain/payment_repository_interface.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _paymentId = 'dddddddd-0000-4000-8000-000000000001';
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

LocalPaymentRepository _repo(AppDatabase db) =>
    LocalPaymentRepository(db.paymentsDao, db.projectsDao, db);

void main() {
  group('LocalPaymentRepository CRUD', () {
    test('Create YER payment', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500000,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      expect(pay.originalAmountMinor, 500000);
      expect(pay.originalCurrency, kCurrencyYer);
      expect(pay.exchangeRateScaled, kIdentityExchangeRate);
      expect(pay.convertedYerAmount, 500000);
      expect(pay.rateSource, kRateSourceIdentity);
      expect(UuidUtil.isValid(pay.id), true);
      await db.close();
    });

    test('Create SAR payment with rate', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          paymentDate: _date,
          method: 'bank_transfer');
      expect(pay.originalAmountMinor, 100000);
      expect(pay.originalCurrency, kCurrencySar);
      expect(pay.exchangeRateScaled, 410000000);
      expect(pay.convertedYerAmount, 410000);
      await db.close();
    });

    test('Get payment by ID', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      final found = await repo.getById(created.id);
      expect(found, isNotNull);
      expect(found!.originalAmountMinor, 500);
      await db.close();
    });

    test('List active payments by project', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      await repo.create(
          projectId: _projectId,
          originalAmountMinor: 100,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await repo.create(
          projectId: _projectId,
          originalAmountMinor: 200,
          originalCurrency: kCurrencyYer,
          paymentDate: '2026-03-16',
          method: 'cash');
      final list = await repo.listByProject(_projectId);
      expect(list.length, 2);
      await db.close();
    });

    test('Update payment', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      final updated =
          await repo.update(id: created.id, originalAmountMinor: 600);
      expect(updated.originalAmountMinor, 600);
      await db.close();
    });

    test('Soft-delete payment', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await repo.softDelete(created.id);
      // Active list should not contain it
      final active = await repo.listByProject(_projectId);
      expect(active.length, 0);
      // But getById returns null (not found in active)
      final found = await repo.getById(created.id);
      expect(found, isNull);
      await db.close();
    });

    test('Soft-deleted payment excluded from financial total', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500000,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await repo.softDelete(created.id);
      final total = await repo.totalActivePaymentsYer(_projectId);
      expect(total, 0);
      await db.close();
    });

    test('Restore payment', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
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
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
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
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await repo.softDelete(created.id);
      await repo.restore(created.id);
      await repo.restore(created.id); // Should not throw
      await db.close();
    });
  });

  group('currency and conversion', () {
    test('1000 SAR × 410 = 410000 YER', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          paymentDate: _date,
          method: 'cash');
      expect(pay.convertedYerAmount, 410000);
      await db.close();
    });

    test('1000.50 SAR × 410 = 410205 YER', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 100050,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          paymentDate: _date,
          method: 'cash');
      expect(pay.convertedYerAmount, 410205);
      await db.close();
    });

    test('YER identity rate enforced', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500000,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      expect(pay.exchangeRateScaled, kIdentityExchangeRate);
      expect(pay.rateSource, kRateSourceIdentity);
      expect(pay.convertedYerAmount, pay.originalAmountMinor);
      await db.close();
    });

    test('SAR requires positive rate', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      expect(
        () => repo.create(
            projectId: _projectId,
            originalAmountMinor: 100000,
            originalCurrency: kCurrencySar,
            paymentDate: _date,
            method: 'cash'),
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
            originalAmountMinor: 100,
            originalCurrency: 'USD',
            paymentDate: _date,
            method: 'cash'),
        throwsArgumentError,
      );
      await db.close();
    });

    test('Invalid method rejected', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      expect(
        () => repo.create(
            projectId: _projectId,
            originalAmountMinor: 100,
            originalCurrency: kCurrencyYer,
            paymentDate: _date,
            method: 'invalid'),
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
            originalAmountMinor: 0,
            originalCurrency: kCurrencyYer,
            paymentDate: _date,
            method: 'cash'),
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
      // No explicit rate provided — should use project fixed rate
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 50000,
          originalCurrency: kCurrencySar,
          paymentDate: _date,
          method: 'cash');
      expect(pay.exchangeRateScaled, 420000000);
      expect(pay.rateSource, kRateSourceProject);
      await db.close();
    });

    test('Default rate change does not alter historical payment', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          paymentDate: _date,
          method: 'cash');
      // Change default rate in settings
      await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          id: 'app',
          defaultExchangeRateScaled: const Value(999000000),
          createdAt: _ts,
          updatedAt: _ts));
      // Payment should be unchanged
      final found = await repo.getById(pay.id);
      expect(found!.exchangeRateScaled, 410000000);
      expect(found.convertedYerAmount, 410000);
      await db.close();
    });
  });

  group('soft-delete safety', () {
    test('Active payment blocks project hard deletion', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      // Try to delete project
      expect(
        () => db.projectsDao.deleteProject(_projectId),
        throwsA(isA<Object>()),
      );
      await db.close();
    });

    test('Soft-deleted payment still blocks project hard deletion', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await repo.softDelete(pay.id);
      // Project deletion should still be blocked (FK RESTRICT)
      expect(
        () => db.projectsDao.deleteProject(_projectId),
        throwsA(isA<Object>()),
      );
      await db.close();
    });

    test('Deleting payment never deletes project', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await repo.softDelete(pay.id);
      final project = await db.projectsDao.getProjectById(_projectId);
      expect(project, isNotNull);
      await db.close();
    });
  });

  group('payment groups', () {
    test('Two currency lines share one payment_group_id', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      const groupId = 'grp-pay-0001';
      await repo.create(
          projectId: _projectId,
          paymentGroupId: groupId,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await repo.create(
          projectId: _projectId,
          paymentGroupId: groupId,
          originalAmountMinor: 50000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          paymentDate: _date,
          method: 'cash');
      final payments = await repo.listByProject(_projectId);
      expect(payments.length, 2);
      expect(payments.every((p) => p.paymentGroupId == groupId), true);
      final totalYer =
          payments.fold<int>(0, (sum, p) => sum + p.convertedYerAmount);
      expect(totalYer, 100000 + 205000);
      await db.close();
    });

    test('Group soft delete is atomic', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      const groupId = 'grp-pay-0002';
      await repo.create(
          projectId: _projectId,
          paymentGroupId: groupId,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await repo.create(
          projectId: _projectId,
          paymentGroupId: groupId,
          originalAmountMinor: 50000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          paymentDate: _date,
          method: 'cash');
      await repo.softDeleteGroup(groupId);
      final active = await repo.listByProject(_projectId);
      expect(active.length, 0);
      await db.close();
    });

    test('Group restore is atomic', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      const groupId = 'grp-pay-0003';
      await repo.create(
          projectId: _projectId,
          paymentGroupId: groupId,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await repo.create(
          projectId: _projectId,
          paymentGroupId: groupId,
          originalAmountMinor: 50000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          paymentDate: _date,
          method: 'cash');
      await repo.softDeleteGroup(groupId);
      await repo.restoreGroup(groupId);
      final active = await repo.listByProject(_projectId);
      expect(active.length, 2);
      await db.close();
    });
  });

  group('persistence', () {
    test('Payment persists after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p06_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId,
          originalAmountMinor: 500000,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found, isNotNull);
      expect(found!.originalAmountMinor, 500000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Soft-delete state persists after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p06_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId,
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
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
      final tempDir = await Directory.systemTemp.createTemp('erp_p06_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: kRateSourceManual,
          rateDate: _date,
          paymentDate: _date,
          method: 'bank_transfer');
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
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: _paymentId,
          projectId: _projectId,
          originalAmountMinor: 500000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 500000,
          paymentDate: _date,
          method: 'cash',
          createdAt: _ts));
      final row = await db.paymentsDao.getPaymentById(_paymentId);
      final entity = PaymentMapper.rowToEntity(row!);
      expect(entity.id, _paymentId);
      expect(entity.projectId, _projectId);
      expect(entity.originalAmountMinor, 500000);
      expect(entity.originalCurrency, kCurrencyYer);
      expect(entity.exchangeRateScaled, kIdentityExchangeRate);
      expect(entity.convertedYerAmount, 500000);
      expect(entity.method, 'cash');
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
          originalAmountMinor: 500,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      final found = await repo.getById(created.id);
      expect(found!.notes, isNull);
      await db.close();
    });
  });

  group('interface compliance', () {
    test('LocalPaymentRepository implements PaymentRepositoryInterface', () {
      final db = _createDb();
      final repo = _repo(db);
      expect(repo, isA<PaymentRepositoryInterface>());
      db.close();
    });
  });

  group('transitional regression', () {
    test('Local Client → Project → Payment succeeds', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final pay = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 500000,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      expect(pay.projectId, _projectId);
      final found = await repo.getById(pay.id);
      expect(found, isNotNull);
      await db.close();
    });

    test('Orphan payment rejected', () async {
      final db = _createDb();
      final repo = _repo(db);
      expect(
        () => repo.create(
            projectId: 'nonexistent-0000-4000-8000-000000000000',
            originalAmountMinor: 100,
            originalCurrency: kCurrencyYer,
            paymentDate: _date,
            method: 'cash'),
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
          originalAmountMinor: 600,
          originalCurrency: kCurrencyYer,
          paymentDate: _date,
          method: 'cash');
      final p2 = await repo.create(
          projectId: _projectId,
          originalAmountMinor: 400,
          originalCurrency: kCurrencyYer,
          paymentDate: '2026-03-16',
          method: 'cash');
      final total1 = await repo.totalActivePaymentsYer(_projectId);
      expect(total1, 1000);
      await repo.softDelete(p2.id);
      final total2 = await repo.totalActivePaymentsYer(_projectId);
      expect(total2, 600);
      await db.close();
    });
  });
}
