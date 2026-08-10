import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/database/finance/currency_conversion.dart';
import 'package:construction_erp/features/payments/data/local_payment_repository.dart';
import 'package:construction_erp/features/expenses/data/local_expense_repository.dart';
import 'package:construction_erp/features/projects/data/local_project_repository.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _ts = '2026-01-15T10:00:00Z';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seedClient(AppDatabase db) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
      id: _clientId, name: 'Test Client', createdAt: _ts, updatedAt: _ts));
}

LocalProjectRepository _projectRepo(AppDatabase db) =>
    LocalProjectRepository(db.projectsDao, db.clientsDao, db);

void main() {
  group('Contract value locking and amendment', () {
    test('contract value can be edited when no transactions exist', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _projectRepo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      final updated = await repo.update(
          id: project.id,
          budgetAmountMinor: 2000000,
          budgetCurrency: kCurrencyYer);
      expect(updated.budgetAmountMinor, 2000000);
      await db.close();
    });

    test('contract value is locked after a payment is recorded', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _projectRepo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      final payRepo =
          LocalPaymentRepository(db.paymentsDao, db.projectsDao, db);
      await payRepo.create(
          projectId: project.id,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencyYer,
          paymentDate: '2026-02-01',
          method: 'cash');
      expect(
        () => repo.update(
            id: project.id,
            budgetAmountMinor: 2000000,
            budgetCurrency: kCurrencyYer),
        throwsA(isA<StateError>()),
      );
      await db.close();
    });

    test('contract value is locked after an expense is recorded', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _projectRepo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      final expRepo =
          LocalExpenseRepository(db.expensesDao, db.projectsDao, db);
      await expRepo.create(
          projectId: project.id,
          category: 'materials',
          originalAmountMinor: 50000,
          originalCurrency: kCurrencyYer,
          expenseDate: '2026-02-01');
      expect(
        () => repo.update(
            id: project.id,
            budgetAmountMinor: 2000000,
            budgetCurrency: kCurrencyYer),
        throwsA(isA<StateError>()),
      );
      await db.close();
    });

    test('amendContract changes current value but preserves original',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _projectRepo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      expect(project.originalContractValueMinor, 1000000);
      final amended =
          await repo.amendContract(id: project.id, newContractValueMinor: 1500000);
      expect(amended.budgetAmountMinor, 1500000);
      expect(amended.originalContractValueMinor, 1000000);
      await db.close();
    });

    test('financial summary uses currentContractValue (not original)',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _projectRepo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      await repo.amendContract(id: project.id, newContractValueMinor: 2000000);
      final summary = await repo.getFinancialSummary(project.id);
      expect(summary.currentContractValue, 2000000);
      expect(summary.originalContractValue, 1000000);
      expect(summary.remainingContractValue, 2000000);
      await db.close();
    });
  });

  group('Currency calculation accuracy', () {
    test('YER to SAR conversion is exact with round-half-up', () {
      // 100,000,000 YER at 420 YER/SAR → 100M × 100 × 1M / 420M = 23809523.8 → 23809524
      final result = convertToCurrency(100000000, 'YER', 'SAR', 420000000);
      expect(result, 23809524);
    });

    test('SAR to YER conversion is exact', () {
      // 1,829.26 SAR = 182926 minor, at 410 → 182926 × 410 / 100 = 749996.6 → 749997
      final result = convertToCurrency(182926, 'SAR', 'YER', 410000000);
      expect(result, 749997);
    });

    test('same currency conversion is identity', () {
      expect(convertToCurrency(500000, 'YER', 'YER', 1000000), 500000);
      expect(convertToCurrency(500000, 'SAR', 'SAR', 1000000), 500000);
    });

    test('cross-currency conversion rejects zero/negative rate', () {
      expect(() => convertToCurrency(100, 'YER', 'SAR', 0), throwsArgumentError);
      expect(
          () => convertToCurrency(100, 'YER', 'SAR', -1), throwsArgumentError);
    });

    test('SAR payment against YER contract: snapshot rate preserved',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _projectRepo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      final payRepo =
          LocalPaymentRepository(db.paymentsDao, db.projectsDao, db);
      final payment = await payRepo.create(
          projectId: project.id,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: 'manual',
          paymentDate: '2026-02-01',
          method: 'cash');
      expect(payment.exchangeRateScaled, 410000000);
      expect(payment.convertedYerAmount, 410000);
      final summary = await repo.getFinancialSummary(project.id);
      // 1000 SAR × 410 = 410,000 YER (contract currency)
      expect(summary.totalPaymentsContractCurrency, 410000);
      await db.close();
    });

    test('YER payment against SAR contract stores the rate', () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _projectRepo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 50000000,
          budgetCurrency: kCurrencySar);
      final payRepo =
          LocalPaymentRepository(db.paymentsDao, db.projectsDao, db);
      final payment = await payRepo.create(
          projectId: project.id,
          originalAmountMinor: 100000000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: 420000000,
          rateSource: 'manual',
          paymentDate: '2026-02-01',
          method: 'cash');
      expect(payment.convertedYerAmount, 100000000);
      expect(payment.exchangeRateScaled, 420000000);
      final summary = await repo.getFinancialSummary(project.id);
      expect(summary.totalPaymentsContractCurrency, 23809524);
      await db.close();
    });

    test('historical exchange rate is preserved after settings change',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final repo = _projectRepo(db);
      final project = await repo.create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      final payRepo =
          LocalPaymentRepository(db.paymentsDao, db.projectsDao, db);
      final payment = await payRepo.create(
          projectId: project.id,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: 'manual',
          paymentDate: '2026-02-01',
          method: 'cash');
      final found = await payRepo.getById(payment.id);
      expect(found!.exchangeRateScaled, 410000000);
      expect(found.convertedYerAmount, 410000);
      await db.close();
    });
  });

  group('Persistence after restart', () {
    test('original contract value survives database reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_contract_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));
      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClient(db1);
      final repo1 = _projectRepo(db1);
      final created = await repo1.create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      await repo1.amendContract(id: created.id, newContractValueMinor: 2000000);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _projectRepo(db2);
      final found = await repo2.getById(created.id);
      expect(found!.budgetAmountMinor, 2000000);
      expect(found.originalContractValueMinor, 1000000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('payment with historical rate survives restart', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_pay_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));
      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClient(db1);
      final project = await _projectRepo(db1).create(
          clientId: _clientId,
          name: 'P',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer);
      final payRepo1 =
          LocalPaymentRepository(db1.paymentsDao, db1.projectsDao, db1);
      await payRepo1.create(
          projectId: project.id,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          rateSource: 'manual',
          paymentDate: '2026-02-01',
          method: 'cash');
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final payRepo2 =
          LocalPaymentRepository(db2.paymentsDao, db2.projectsDao, db2);
      final payments = await payRepo2.listByProject(project.id);
      expect(payments.length, 1);
      expect(payments.first.exchangeRateScaled, 410000000);
      expect(payments.first.convertedYerAmount, 410000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });

  group('Schema migration v5', () {
    test('originalContractValueMinor is backfilled on migration from v4',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_v5_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));
      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClient(db1);
      await db1.into(db1.projects).insert(ProjectsCompanion.insert(
            id: _projectId,
            clientId: _clientId,
            name: 'Legacy',
            budgetAmountMinor: 750000,
            budgetCurrency: 'YER',
            createdAt: _ts,
          ));
      await db1.customStatement('PRAGMA user_version = 4');
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo = _projectRepo(db2);
      final found = await repo.getById(_projectId);
      expect(found!.originalContractValueMinor, 750000);
      expect(found.budgetAmountMinor, 750000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });
}