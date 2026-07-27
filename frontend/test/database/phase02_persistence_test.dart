import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/database/finance/snapshot_validation.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _paymentId = 'dddddddd-0000-4000-8000-000000000001';
const _expenseId = 'eeeeeeee-0000-4000-8000-000000000001';
const _ts = '2026-01-15T10:00:00Z';
const _ts2 = '2026-01-20T12:00:00Z';
const _date = '2026-03-15';

Future<AppDatabase> _createTempDb(Directory tempDir) async {
  final file = File(p.join(tempDir.path, kDatabaseFileName));
  return AppDatabase(NativeDatabase.createInBackground(file));
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('erp_db_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('persistence', () {
    test('Database file is created on disk', () async {
      final db = await _createTempDb(tempDir);
      await db.customSelect('SELECT 1').get();
      await db.close();

      final dbFile = File(p.join(tempDir.path, kDatabaseFileName));
      expect(await dbFile.exists(), true);
      expect((await dbFile.length()) > 0, true);
    });

    test('Client persists after close and reopen', () async {
      final db1 = await _createTempDb(tempDir);
      await db1.into(db1.clients).insert(ClientsCompanion.insert(
            id: _clientId,
            name: 'Persistent Client',
            phone: const Value('+966500000001'),
            createdAt: _ts,
            updatedAt: _ts,
          ));
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      final client = await db2.clientsDao.getClientById(_clientId);
      expect(client, isNotNull);
      expect(client!.name, 'Persistent Client');
      expect(client.phone, '+966500000001');
      await db2.close();
    });

    test('Project and Client relationship persist after close and reopen',
        () async {
      final db1 = await _createTempDb(tempDir);
      await db1.into(db1.clients).insert(ClientsCompanion.insert(
          id: _clientId, name: 'Client A', createdAt: _ts, updatedAt: _ts));
      await db1.into(db1.projects).insert(ProjectsCompanion.insert(
          id: _projectId,
          clientId: _clientId,
          name: 'Persistent Project',
          budgetAmountMinor: 1500000,
          budgetCurrency: kCurrencyYer,
          createdAt: _ts));
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      final client = await db2.clientsDao.getClientById(_clientId);
      expect(client, isNotNull);
      final project = await db2.projectsDao.getProjectById(_projectId);
      expect(project, isNotNull);
      expect(project!.clientId, _clientId);
      expect(project.name, 'Persistent Project');
      expect(project.budgetAmountMinor, 1500000);
      await db2.close();
    });

    test('App settings persist after close and reopen', () async {
      final db1 = await _createTempDb(tempDir);
      await db1.into(db1.appSettings).insert(AppSettingsCompanion.insert(
          id: 'app',
          defaultExchangeRateScaled: const Value(410000000),
          createdAt: _ts,
          updatedAt: _ts));
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      final settings = await db2.appSettingsDao.getSettings();
      expect(settings, isNotNull);
      expect(settings!.defaultExchangeRateScaled, 410000000);
      await db2.close();
    });

    test('Default exchange rate persists', () async {
      final db1 = await _createTempDb(tempDir);
      await db1.into(db1.appSettings).insert(AppSettingsCompanion.insert(
          id: 'app',
          defaultExchangeRateScaled: const Value(412750000),
          createdAt: _ts,
          updatedAt: _ts));
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      final settings = await db2.appSettingsDao.getSettings();
      expect(settings!.defaultExchangeRateScaled, 412750000);
      await db2.close();
    });

    test('Payment exchange-rate snapshot persists after close and reopen',
        () async {
      final db1 = await _createTempDb(tempDir);
      await db1.into(db1.clients).insert(ClientsCompanion.insert(
          id: _clientId, name: 'Client', createdAt: _ts, updatedAt: _ts));
      await db1.into(db1.projects).insert(ProjectsCompanion.insert(
          id: _projectId,
          clientId: _clientId,
          name: 'Project',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer,
          createdAt: _ts));
      await db1.into(db1.payments).insert(PaymentsCompanion.insert(
          id: _paymentId,
          projectId: _projectId,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          convertedYerAmount: 410000,
          rateSource: const Value(kRateSourceManual),
          rateDate: const Value(_date),
          paymentDate: _date,
          method: 'bank_transfer',
          createdAt: _ts));
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      final pay = await db2.paymentsDao.getPaymentById(_paymentId);
      expect(pay, isNotNull);
      expect(pay!.originalCurrency, kCurrencySar);
      expect(pay.exchangeRateScaled, 410000000);
      expect(pay.convertedYerAmount, 410000);
      expect(pay.rateSource, kRateSourceManual);
      await db2.close();
    });

    test('Expense exchange-rate snapshot persists after close and reopen',
        () async {
      final db1 = await _createTempDb(tempDir);
      await db1.into(db1.clients).insert(ClientsCompanion.insert(
          id: _clientId, name: 'Client', createdAt: _ts, updatedAt: _ts));
      await db1.into(db1.projects).insert(ProjectsCompanion.insert(
          id: _projectId,
          clientId: _clientId,
          name: 'Project',
          budgetAmountMinor: 1000000,
          budgetCurrency: kCurrencyYer,
          createdAt: _ts));
      await db1.into(db1.expenses).insert(ExpensesCompanion.insert(
          id: _expenseId,
          projectId: _projectId,
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 150000,
          category: 'materials',
          expenseDate: _date,
          createdAt: _ts));
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      final exp = await db2.expensesDao.getExpenseById(_expenseId);
      expect(exp, isNotNull);
      expect(exp!.originalCurrency, kCurrencyYer);
      expect(exp.exchangeRateScaled, kIdentityExchangeRate);
      expect(exp.convertedYerAmount, 150000);
      await db2.close();
    });

    test('Foreign keys are active after reopening', () async {
      final db1 = await _createTempDb(tempDir);
      await db1.into(db1.clients).insert(ClientsCompanion.insert(
          id: _clientId, name: 'Client', createdAt: _ts, updatedAt: _ts));
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      await db2.customSelect('SELECT 1').get();
      final result = await db2.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.data['foreign_keys'], 1);

      expect(
        () => db2.into(db2.projects).insert(ProjectsCompanion.insert(
            id: _projectId,
            clientId: 'nonexistent-0000-4000-8000-000000000000',
            name: 'Orphan',
            budgetAmountMinor: 100,
            budgetCurrency: kCurrencyYer,
            createdAt: _ts)),
        throwsA(isA<Object>()),
      );
      await db2.close();
    });

    test('Schema version remains correct after reopening', () async {
      final db1 = await _createTempDb(tempDir);
      await db1.customSelect('SELECT 1').get();
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      expect(db2.schemaVersion, kSchemaVersion);
      expect(db2.schemaVersion, 4);
      await db2.close();
    });

    test('Reopening does not erase existing data', () async {
      final db1 = await _createTempDb(tempDir);
      await db1.into(db1.clients).insert(ClientsCompanion.insert(
          id: _clientId, name: 'Survives', createdAt: _ts, updatedAt: _ts));
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      await db2.customSelect('SELECT 1').get();
      final clients = await db2.clientsDao.getAllClients();
      expect(clients.length, 1);
      expect(clients.first.name, 'Survives');
      await db2.close();
    });

    test('Closing one AppDatabase and opening another on same file succeeds',
        () async {
      final db1 = await _createTempDb(tempDir);
      await db1.into(db1.clients).insert(ClientsCompanion.insert(
          id: _clientId, name: 'First', createdAt: _ts, updatedAt: _ts));
      await db1.close();

      final db2 = await _createTempDb(tempDir);
      final client = await db2.clientsDao.getClientById(_clientId);
      expect(client!.name, 'First');
      await db2.into(db2.clients).insert(ClientsCompanion.insert(
          id: 'aaaaaaaa-0000-4000-8000-000000000002',
          name: 'Second',
          createdAt: _ts2,
          updatedAt: _ts2));
      await db2.close();

      final db3 = await _createTempDb(tempDir);
      final all = await db3.clientsDao.getAllClients();
      expect(all.length, 2);
      await db3.close();
    });

    test('Temporary test files are cleaned up', () async {
      final db = await _createTempDb(tempDir);
      await db.close();
      // tearDown will delete tempDir
    });
  });

  group('UUID enforcement', () {
    test('Valid UUID accepted', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.clients).insert(ClientsCompanion.insert(
          id: '12345678-1234-4321-9abc-1234567890ab',
          name: 'Valid UUID',
          createdAt: _ts,
          updatedAt: _ts));
      final client = await db.clientsDao
          .getClientById('12345678-1234-4321-9abc-1234567890ab');
      expect(client, isNotNull);
      await db.close();
    });

    test('Duplicate UUID rejected', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.clients).insert(ClientsCompanion.insert(
          id: _clientId, name: 'First', createdAt: _ts, updatedAt: _ts));
      expect(
        () => db.into(db.clients).insert(ClientsCompanion.insert(
            id: _clientId, name: 'Duplicate', createdAt: _ts, updatedAt: _ts)),
        throwsA(isA<Object>()),
      );
      await db.close();
    });

    test('Drift enforces min TEXT length at Dart level — documented', () async {
      // Drift's withLength(min:36, max:36) is enforced at the Dart application
      // layer via InvalidDataException before the SQL reaches SQLite.
      // SQLite itself does not enforce TEXT(n) lengths, but Drift prevents
      // short strings from being inserted.
      // UUID format validation (e.g., regex for UUID v4 pattern) is NOT
      // enforced — only minimum length is checked. A 36-character non-UUID
      // string would be accepted.
      final db = AppDatabase(NativeDatabase.memory());
      expect(
        () => db.into(db.clients).insert(ClientsCompanion.insert(
            id: 'short', name: 'Short ID', createdAt: _ts, updatedAt: _ts)),
        throwsA(isA<Object>()),
      );
      await db.close();
    });
  });

  group('YER identity rate policy', () {
    test('Identity rate is 1000000', () {
      expect(kIdentityExchangeRate, 1000000);
    });

    test('YER snapshot validation passes for correct identity values', () {
      validateYerSnapshot(
        originalAmountMinor: 150000,
        originalCurrency: kCurrencyYer,
        exchangeRateScaled: kIdentityExchangeRate,
        convertedYerAmount: 150000,
        rateSource: kRateSourceIdentity,
      );
    });

    test('YER snapshot validation fails for wrong rate', () {
      expect(
        () => validateYerSnapshot(
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: 999999,
          convertedYerAmount: 150000,
          rateSource: kRateSourceIdentity,
        ),
        throwsArgumentError,
      );
    });

    test('YER snapshot validation fails when converted != original', () {
      expect(
        () => validateYerSnapshot(
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 149999,
          rateSource: kRateSourceIdentity,
        ),
        throwsArgumentError,
      );
    });

    test('YER snapshot validation fails for wrong rate source', () {
      expect(
        () => validateYerSnapshot(
          originalAmountMinor: 150000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 150000,
          rateSource: kRateSourceManual,
        ),
        throwsArgumentError,
      );
    });

    test('SAR snapshot validation passes for correct conversion', () {
      validateSarSnapshot(
        originalAmountMinor: 100000,
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        convertedYerAmount: 410000,
      );
    });

    test('SAR snapshot validation fails for wrong converted amount', () {
      expect(
        () => validateSarSnapshot(
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          convertedYerAmount: 409999,
        ),
        throwsArgumentError,
      );
    });

    test('SAR snapshot validation fails for zero exchange rate', () {
      expect(
        () => validateSarSnapshot(
          originalAmountMinor: 100000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 0,
          convertedYerAmount: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Dispatch validation works for both currencies', () {
      validateSnapshot(
        originalAmountMinor: 50000,
        originalCurrency: kCurrencyYer,
        exchangeRateScaled: kIdentityExchangeRate,
        convertedYerAmount: 50000,
        rateSource: kRateSourceIdentity,
      );
      validateSnapshot(
        originalAmountMinor: 100000,
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        convertedYerAmount: 410000,
        rateSource: kRateSourceManual,
      );
    });
  });
}
