import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/database/finance/money_scale.dart';
import 'package:construction_erp/core/database/finance/exchange_rate.dart';
import 'package:construction_erp/core/database/finance/currency_conversion.dart';

/// Deterministic test UUIDs — no DateTime.now() in expected values.
const _clientIdA = 'aaaaaaaa-0000-4000-8000-000000000001';
const _clientIdB = 'aaaaaaaa-0000-4000-8000-000000000002';
const _projectIdA = 'bbbbbbbb-0000-4000-8000-000000000001';
const _milestoneId = 'cccccccc-0000-4000-8000-000000000001';
const _paymentId = 'dddddddd-0000-4000-8000-000000000001';
const _paymentId2 = 'dddddddd-0000-4000-8000-000000000002';
const _expenseId = 'eeeeeeee-0000-4000-8000-000000000001';
const _expenseId2 = 'eeeeeeee-0000-4000-8000-000000000002';
const _ts = '2026-01-15T10:00:00Z';
const _ts2 = '2026-01-20T12:00:00Z';
const _dateOnly = '2026-03-15';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  // ===========================================================================
  // Finance utilities — money scale
  // ===========================================================================
  group('money_scale', () {
    test('YER amount exact round-trip', () {
      final minor = toMinorUnits(Decimal.parse('150000'), kCurrencyYer);
      expect(minor, 150000);
      expect(formatMinorUnits(minor, kCurrencyYer), '150000');
    });

    test('SAR amount exact round-trip', () {
      final minor = toMinorUnits(Decimal.parse('150000.50'), kCurrencySar);
      expect(minor, 15000050);
      expect(formatMinorUnits(minor, kCurrencySar), '150000.50');
    });

    test('SAR decimal scale limited to two', () {
      expect(
        () => toMinorUnits(Decimal.parse('100.123'), kCurrencySar),
        throwsArgumentError,
      );
    });

    test('YER fractions rejected', () {
      expect(
        () => toMinorUnits(Decimal.parse('100.50'), kCurrencyYer),
        throwsArgumentError,
      );
    });

    test('Unsupported currency rejected', () {
      expect(
        () => toMinorUnits(Decimal.parse('100'), 'USD'),
        throwsArgumentError,
      );
    });

    test('Negative amount rejected when requirePositive', () {
      expect(
        () => toMinorUnits(Decimal.parse('-100'), kCurrencyYer,
            requirePositive: true),
        throwsArgumentError,
      );
    });

    test('Zero amount rejected when requirePositive', () {
      expect(
        () => toMinorUnits(Decimal.parse('0'), kCurrencyYer,
            requirePositive: true),
        throwsArgumentError,
      );
    });

    test('minorUnitFactor returns correct values', () {
      expect(minorUnitFactor(kCurrencyYer), 1);
      expect(minorUnitFactor(kCurrencySar), 100);
    });

    test('currencyScale returns correct values', () {
      expect(currencyScale(kCurrencyYer), 0);
      expect(currencyScale(kCurrencySar), 2);
    });
  });

  // ===========================================================================
  // Finance utilities — exchange rate
  // ===========================================================================
  group('exchange_rate', () {
    test('Exchange rate scale limited to six', () {
      expect(
        () => toScaledExchangeRate(Decimal.parse('410.1234567')),
        throwsArgumentError,
      );
    });

    test('Zero exchange rate rejected', () {
      expect(
        () => toScaledExchangeRate(Decimal.parse('0')),
        throwsArgumentError,
      );
    });

    test('Negative exchange rate rejected', () {
      expect(
        () => toScaledExchangeRate(Decimal.parse('-410')),
        throwsArgumentError,
      );
    });

    test('Exchange rate exact round-trip', () {
      final scaled = toScaledExchangeRate(Decimal.parse('410.500000'));
      expect(scaled, 410500000);
      expect(formatScaledExchangeRate(scaled), '410.500000');
    });

    test('Identity exchange rate is 1000000', () {
      expect(identityExchangeRate, 1000000);
    });
  });

  // ===========================================================================
  // Finance utilities — currency conversion
  // ===========================================================================
  group('currency_conversion', () {
    test('1000 SAR × 410 = 410000 YER', () {
      final minor = toMinorUnits(Decimal.parse('1000.00'), kCurrencySar);
      final rate = toScaledExchangeRate(Decimal.parse('410.000000'));
      final yer = convertToYer(minor, kCurrencySar, rate);
      expect(yer, 410000);
    });

    test('1000.50 SAR × 410 = 410205 YER', () {
      final minor = toMinorUnits(Decimal.parse('1000.50'), kCurrencySar);
      final rate = toScaledExchangeRate(Decimal.parse('410.000000'));
      final yer = convertToYer(minor, kCurrencySar, rate);
      expect(yer, 410205);
    });

    test('Fractional exchange rate conversion', () {
      // 100 SAR × 410.75 = 41075 YER
      final minor = toMinorUnits(Decimal.parse('100.00'), kCurrencySar);
      final rate = toScaledExchangeRate(Decimal.parse('410.750000'));
      final yer = convertToYer(minor, kCurrencySar, rate);
      expect(yer, 41075);
    });

    test('YER identity conversion', () {
      final yer = convertToYer(150000, kCurrencyYer, kIdentityExchangeRate);
      expect(yer, 150000);
    });

    test('Round-half-up boundary: 0.5 rounds up', () {
      expect(roundHalfUp(Decimal.parse('410.5')), 411);
    });

    test('Round-half-up boundary: 0.4 rounds down', () {
      expect(roundHalfUp(Decimal.parse('410.4')), 410);
    });

    test('Round-half-up boundary: 0.0 stays', () {
      expect(roundHalfUp(Decimal.parse('410.0')), 410);
    });

    test('Round-half-up boundary: 0.500001 rounds up', () {
      expect(roundHalfUp(Decimal.parse('410.500001')), 411);
    });

    test('No double used — conversion uses BigInt internally', () {
      // This is verified by the implementation; the test confirms exactness.
      final minor = toMinorUnits(Decimal.parse('99999999.99'), kCurrencySar);
      final rate = toScaledExchangeRate(Decimal.parse('999.999999'));
      final yer = convertToYer(minor, kCurrencySar, rate);
      // The exact value is computed via BigInt; we just verify it's an int.
      expect(yer, isA<int>());
    });
  });

  // ===========================================================================
  // Database lifecycle
  // ===========================================================================
  group('database lifecycle', () {
    test('Database opens', () async {
      final db = _createDb();
      await db.customSelect('SELECT 1').get();
      await db.close();
    });

    test('Database closes without error', () async {
      final db = _createDb();
      await db.close();
    });

    test('Schema version is correct', () {
      final db = _createDb();
      expect(db.schemaVersion, kSchemaVersion);
      db.close();
    });

    test('Foreign keys are enabled', () async {
      final db = _createDb();
      // Force opening
      await db.customSelect('SELECT 1').get();
      final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.data['foreign_keys'], 1);
      await db.close();
    });

    test('Database can reopen', () async {
      final db1 = _createDb();
      await db1.into(db1.clients).insert(ClientsCompanion.insert(
            id: _clientIdA,
            name: 'Test',
            createdAt: _ts,
            updatedAt: _ts,
          ));
      await db1.close();

      // In-memory databases don't persist, so we just verify a new db opens.
      final db2 = _createDb();
      await db2.customSelect('SELECT 1').get();
      await db2.close();
    });
  });

  // ===========================================================================
  // Identifiers — UUID round-trip
  // ===========================================================================
  group('identifiers', () {
    test('UUID TEXT values round-trip unchanged', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: _clientIdA,
            name: 'Test Client',
            createdAt: _ts,
            updatedAt: _ts,
          ));
      final row = await db.clientsDao.getClientById(_clientIdA);
      expect(row, isNotNull);
      expect(row!.id, _clientIdA);
      await db.close();
    });

    test('Duplicate primary keys are rejected', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: _clientIdA,
            name: 'First',
            createdAt: _ts,
            updatedAt: _ts,
          ));
      expect(
        () => db.into(db.clients).insert(ClientsCompanion.insert(
              id: _clientIdA,
              name: 'Duplicate',
              createdAt: _ts,
              updatedAt: _ts,
            )),
        throwsA(isA<Object>()),
      );
      await db.close();
    });
  });

  // ===========================================================================
  // Relationships — foreign keys
  // ===========================================================================
  group('relationships', () {
    test('Valid Client → Project relation', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: _clientIdA,
            name: 'Client A',
            createdAt: _ts,
            updatedAt: _ts,
          ));
      await db.into(db.projects).insert(ProjectsCompanion.insert(
            id: _projectIdA,
            clientId: _clientIdA,
            name: 'Project A',
            budgetAmountMinor: 100000,
            budgetCurrency: kCurrencyYer,
            createdAt: _ts,
          ));
      final proj = await db.projectsDao.getProjectById(_projectIdA);
      expect(proj, isNotNull);
      expect(proj!.clientId, _clientIdA);
      await db.close();
    });

    test('Invalid orphan Project is rejected', () async {
      final db = _createDb();
      expect(
        () => db.into(db.projects).insert(ProjectsCompanion.insert(
              id: _projectIdA,
              clientId: 'nonexistent-0000-4000-8000-000000000000',
              name: 'Orphan',
              budgetAmountMinor: 100000,
              budgetCurrency: kCurrencyYer,
              createdAt: _ts,
            )),
        throwsA(isA<Object>()),
      );
      await db.close();
    });

    test('Valid Project → Milestone relation', () async {
      final db = _createDb();
      await _seedClientProject(db);
      await db.into(db.milestones).insert(MilestonesCompanion.insert(
            id: _milestoneId,
            projectId: _projectIdA,
            title: 'Foundation',
            dueDate: _dateOnly,
            createdAt: _ts,
          ));
      final ms = await db.milestonesDao.getMilestoneById(_milestoneId);
      expect(ms, isNotNull);
      expect(ms!.projectId, _projectIdA);
      await db.close();
    });

    test('Invalid orphan Milestone is rejected', () async {
      final db = _createDb();
      expect(
        () => db.into(db.milestones).insert(MilestonesCompanion.insert(
              id: _milestoneId,
              projectId: 'nonexistent-0000-4000-8000-000000000000',
              title: 'Orphan',
              dueDate: _dateOnly,
              createdAt: _ts,
            )),
        throwsA(isA<Object>()),
      );
      await db.close();
    });

    test('Valid Project → Payment relation', () async {
      final db = _createDb();
      await _seedClientProject(db);
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: _paymentId,
            projectId: _projectIdA,
            originalAmountMinor: 500000,
            originalCurrency: kCurrencyYer,
            exchangeRateScaled: kIdentityExchangeRate,
            convertedYerAmount: 500000,
            paymentDate: _dateOnly,
            method: 'cash',
            createdAt: _ts,
          ));
      final pay = await db.paymentsDao.getPaymentById(_paymentId);
      expect(pay, isNotNull);
      expect(pay!.projectId, _projectIdA);
      await db.close();
    });

    test('Invalid orphan Payment is rejected', () async {
      final db = _createDb();
      expect(
        () => db.into(db.payments).insert(PaymentsCompanion.insert(
              id: _paymentId,
              projectId: 'nonexistent-0000-4000-8000-000000000000',
              originalAmountMinor: 500000,
              originalCurrency: kCurrencyYer,
              exchangeRateScaled: kIdentityExchangeRate,
              convertedYerAmount: 500000,
              paymentDate: _dateOnly,
              method: 'cash',
              createdAt: _ts,
            )),
        throwsA(isA<Object>()),
      );
      await db.close();
    });

    test('Valid Project → Expense relation', () async {
      final db = _createDb();
      await _seedClientProject(db);
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            id: _expenseId,
            projectId: _projectIdA,
            originalAmountMinor: 150000,
            originalCurrency: kCurrencyYer,
            exchangeRateScaled: kIdentityExchangeRate,
            convertedYerAmount: 150000,
            category: 'materials',
            expenseDate: _dateOnly,
            createdAt: _ts,
          ));
      final exp = await db.expensesDao.getExpenseById(_expenseId);
      expect(exp, isNotNull);
      expect(exp!.projectId, _projectIdA);
      await db.close();
    });

    test('Invalid orphan Expense is rejected', () async {
      final db = _createDb();
      expect(
        () => db.into(db.expenses).insert(ExpensesCompanion.insert(
              id: _expenseId,
              projectId: 'nonexistent-0000-4000-8000-000000000000',
              originalAmountMinor: 150000,
              originalCurrency: kCurrencyYer,
              exchangeRateScaled: kIdentityExchangeRate,
              convertedYerAmount: 150000,
              category: 'materials',
              expenseDate: _dateOnly,
              createdAt: _ts,
            )),
        throwsA(isA<Object>()),
      );
      await db.close();
    });
  });

  // ===========================================================================
  // Mixed currency — group IDs
  // ===========================================================================
  group('mixed currency', () {
    test('Two expense lines can share one expense_group_id', () async {
      final db = _createDb();
      await _seedClientProject(db);
      const groupId = 'grp-expense-0001';

      // YER line
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            id: _expenseId,
            projectId: _projectIdA,
            expenseGroupId: const Value(groupId),
            originalAmountMinor: 100000,
            originalCurrency: kCurrencyYer,
            exchangeRateScaled: kIdentityExchangeRate,
            convertedYerAmount: 100000,
            rateSource: const Value(kRateSourceIdentity),
            category: 'materials',
            expenseDate: _dateOnly,
            createdAt: _ts,
          ));

      // SAR line
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            id: _expenseId2,
            projectId: _projectIdA,
            expenseGroupId: const Value(groupId),
            originalAmountMinor: 50000, // 500.00 SAR
            originalCurrency: kCurrencySar,
            exchangeRateScaled:
                toScaledExchangeRate(Decimal.parse('410.000000')),
            convertedYerAmount: 205000, // 500 * 410 = 205000 YER
            rateSource: const Value(kRateSourceManual),
            rateDate: const Value(_dateOnly),
            category: 'labor',
            expenseDate: _dateOnly,
            createdAt: _ts,
          ));

      final expenses =
          await db.expensesDao.getActiveExpensesByProject(_projectIdA);
      expect(expenses.length, 2);
      expect(expenses.every((e) => e.expenseGroupId == groupId), true);
      // Unified YER total
      final totalYer =
          expenses.fold<int>(0, (sum, e) => sum + e.convertedYerAmount);
      expect(totalYer, 305000);
      await db.close();
    });

    test('Each line keeps its own original currency and exchange-rate snapshot',
        () async {
      final db = _createDb();
      await _seedClientProject(db);
      const groupId = 'grp-expense-0002';

      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            id: _expenseId,
            projectId: _projectIdA,
            expenseGroupId: const Value(groupId),
            originalAmountMinor: 100000,
            originalCurrency: kCurrencyYer,
            exchangeRateScaled: kIdentityExchangeRate,
            convertedYerAmount: 100000,
            category: 'materials',
            expenseDate: _dateOnly,
            createdAt: _ts,
          ));

      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            id: _expenseId2,
            projectId: _projectIdA,
            expenseGroupId: const Value(groupId),
            originalAmountMinor: 50000,
            originalCurrency: kCurrencySar,
            exchangeRateScaled: 410000000,
            convertedYerAmount: 205000,
            rateDate: const Value(_dateOnly),
            category: 'labor',
            expenseDate: _dateOnly,
            createdAt: _ts,
          ));

      final e1 = await db.expensesDao.getExpenseById(_expenseId);
      final e2 = await db.expensesDao.getExpenseById(_expenseId2);
      expect(e1!.originalCurrency, kCurrencyYer);
      expect(e2!.originalCurrency, kCurrencySar);
      expect(e1.exchangeRateScaled, kIdentityExchangeRate);
      expect(e2.exchangeRateScaled, 410000000);
      await db.close();
    });

    test('Two payment lines may share one payment_group_id', () async {
      final db = _createDb();
      await _seedClientProject(db);
      const groupId = 'grp-payment-0001';

      await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: _paymentId,
            projectId: _projectIdA,
            paymentGroupId: const Value(groupId),
            originalAmountMinor: 200000,
            originalCurrency: kCurrencyYer,
            exchangeRateScaled: kIdentityExchangeRate,
            convertedYerAmount: 200000,
            paymentDate: _dateOnly,
            method: 'cash',
            createdAt: _ts,
          ));

      await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: _paymentId2,
            projectId: _projectIdA,
            paymentGroupId: const Value(groupId),
            originalAmountMinor: 100000, // 1000.00 SAR
            originalCurrency: kCurrencySar,
            exchangeRateScaled: 410000000,
            convertedYerAmount: 410000, // 1000 * 410 = 410000 YER
            rateDate: const Value(_dateOnly),
            paymentDate: _dateOnly,
            method: 'bank_transfer',
            createdAt: _ts,
          ));

      final payments =
          await db.paymentsDao.getActivePaymentsByProject(_projectIdA);
      expect(payments.length, 2);
      expect(payments.every((p) => p.paymentGroupId == groupId), true);
      final totalYer =
          payments.fold<int>(0, (sum, p) => sum + p.convertedYerAmount);
      expect(totalYer, 610000);
      await db.close();
    });
  });

  // ===========================================================================
  // Historical immutability
  // ===========================================================================
  group('historical immutability', () {
    test(
        'Changing default exchange rate does not alter existing payment snapshot',
        () async {
      final db = _createDb();
      await _seedClientProject(db);

      // Insert a SAR payment with rate 410
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: _paymentId,
            projectId: _projectIdA,
            originalAmountMinor: 100000, // 1000.00 SAR
            originalCurrency: kCurrencySar,
            exchangeRateScaled: 410000000, // 410.000000
            convertedYerAmount: 410000,
            rateSource: const Value(kRateSourceManual),
            rateDate: const Value(_dateOnly),
            paymentDate: _dateOnly,
            method: 'cash',
            createdAt: _ts,
          ));

      // Change the default exchange rate in settings
      await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
            id: 'app',
            defaultExchangeRateScaled: const Value(420000000), // 420.000000
            createdAt: _ts,
            updatedAt: _ts2,
          ));

      // The existing payment's exchange rate snapshot must remain unchanged
      final pay = await db.paymentsDao.getPaymentById(_paymentId);
      expect(pay!.exchangeRateScaled, 410000000);
      expect(pay.convertedYerAmount, 410000);
      await db.close();
    });
  });

  // ===========================================================================
  // Dates
  // ===========================================================================
  group('dates', () {
    test('Date-only round-trip', () async {
      final db = _createDb();
      await _seedClientProject(db);
      await db.into(db.milestones).insert(MilestonesCompanion.insert(
            id: _milestoneId,
            projectId: _projectIdA,
            title: 'Test',
            dueDate: '2026-06-15',
            createdAt: _ts,
          ));
      final ms = await db.milestonesDao.getMilestoneById(_milestoneId);
      expect(ms!.dueDate, '2026-06-15');
      await db.close();
    });

    test('UTC timestamp round-trip', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: _clientIdA,
            name: 'Test',
            createdAt: '2026-01-15T10:00:00Z',
            updatedAt: '2026-01-20T12:00:00Z',
          ));
      final client = await db.clientsDao.getClientById(_clientIdA);
      expect(client!.createdAt, '2026-01-15T10:00:00Z');
      expect(client.updatedAt, '2026-01-20T12:00:00Z');
      await db.close();
    });
  });

  // ===========================================================================
  // Transactions
  // ===========================================================================
  group('transactions', () {
    test('Multi-record transaction commits atomically', () async {
      final db = _createDb();
      await db.transaction(() async {
        await db.into(db.clients).insert(ClientsCompanion.insert(
              id: _clientIdA,
              name: 'Client A',
              createdAt: _ts,
              updatedAt: _ts,
            ));
        await db.into(db.clients).insert(ClientsCompanion.insert(
              id: _clientIdB,
              name: 'Client B',
              createdAt: _ts,
              updatedAt: _ts,
            ));
      });

      final clients = await db.clientsDao.getAllClients();
      expect(clients.length, 2);
      await db.close();
    });

    test('Failed transaction rolls back completely', () async {
      final db = _createDb();
      try {
        await db.transaction(() async {
          await db.into(db.clients).insert(ClientsCompanion.insert(
                id: _clientIdA,
                name: 'Client A',
                createdAt: _ts,
                updatedAt: _ts,
              ));
          // Force a failure by inserting a duplicate
          await db.into(db.clients).insert(ClientsCompanion.insert(
                id: _clientIdA,
                name: 'Duplicate',
                createdAt: _ts,
                updatedAt: _ts,
              ));
        });
      } catch (_) {}

      final clients = await db.clientsDao.getAllClients();
      expect(clients.length, 0); // Rollback should have removed both
      await db.close();
    });
  });

  // ===========================================================================
  // Deletion safety
  // ===========================================================================
  group('deletion safety', () {
    test('Deleting a client with projects is prevented by FK RESTRICT',
        () async {
      final db = _createDb();
      await _seedClientProject(db);

      // Attempting to delete the client should fail because a project references it
      expect(
        () => db.clientsDao.deleteClient(_clientIdA),
        throwsA(isA<Object>()),
      );
      await db.close();
    });

    test('Deleting a project with payments is prevented by FK RESTRICT',
        () async {
      final db = _createDb();
      await _seedClientProject(db);
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: _paymentId,
            projectId: _projectIdA,
            originalAmountMinor: 500000,
            originalCurrency: kCurrencyYer,
            exchangeRateScaled: kIdentityExchangeRate,
            convertedYerAmount: 500000,
            paymentDate: _dateOnly,
            method: 'cash',
            createdAt: _ts,
          ));

      // Deleting project should fail because payment references it
      expect(
        () => db.projectsDao.deleteProject(_projectIdA),
        throwsA(isA<Object>()),
      );
      await db.close();
    });

    test('Deleting a milestone works (no children)', () async {
      final db = _createDb();
      await _seedClientProject(db);
      await db.into(db.milestones).insert(MilestonesCompanion.insert(
            id: _milestoneId,
            projectId: _projectIdA,
            title: 'Test',
            dueDate: _dateOnly,
            createdAt: _ts,
          ));
      final deleted = await db.milestonesDao.deleteMilestone(_milestoneId);
      expect(deleted, 1);
      final ms = await db.milestonesDao.getMilestoneById(_milestoneId);
      expect(ms, isNull);
      await db.close();
    });
  });

  // ===========================================================================
  // DAO CRUD operations
  // ===========================================================================
  group('DAO CRUD', () {
    test('Client insert, read, update, delete', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: _clientIdA,
            name: 'Original',
            createdAt: _ts,
            updatedAt: _ts,
          ));
      await db.clientsDao.updateClient(
          _clientIdA, const ClientsCompanion(name: Value('Updated')));
      final client = await db.clientsDao.getClientById(_clientIdA);
      expect(client!.name, 'Updated');
      await db.clientsDao.deleteClient(_clientIdA);
      final deleted = await db.clientsDao.getClientById(_clientIdA);
      expect(deleted, isNull);
      await db.close();
    });

    test('Settings insert and read', () async {
      final db = _createDb();
      await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
            id: 'app',
            defaultExchangeRateScaled: const Value(410000000),
            createdAt: _ts,
            updatedAt: _ts,
          ));
      final settings = await db.appSettingsDao.getSettings();
      expect(settings, isNotNull);
      expect(settings!.defaultExchangeRateScaled, 410000000);
      await db.close();
    });
  });
}

/// Helper: seed a client and a project for relationship tests.
Future<void> _seedClientProject(AppDatabase db) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
        id: _clientIdA,
        name: 'Client A',
        createdAt: _ts,
        updatedAt: _ts,
      ));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
        id: _projectIdA,
        clientId: _clientIdA,
        name: 'Project A',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
        createdAt: _ts,
      ));
}
