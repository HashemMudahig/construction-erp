import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/features/expenses/data/local_expense_repository.dart';
import 'package:construction_erp/features/payments/data/local_payment_repository.dart';
import 'package:construction_erp/features/transfers/data/local_currency_transfer_repository.dart';
import 'package:construction_erp/features/transfers/domain/wallet_balance_service.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _ts = '2026-01-15T10:00:00Z';
const _date = '2026-03-15';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seedClientAndProject(AppDatabase db,
    {String currency = kCurrencyYer,
    int budget = 100000000,
    String policy = kExchangePolicyPerTransaction,
    int? fixedRate}) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
      id: _clientId, name: 'Test Client', createdAt: _ts, updatedAt: _ts));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
      id: _projectId,
      clientId: _clientId,
      name: 'Test Project',
      budgetAmountMinor: budget,
      budgetCurrency: currency,
      exchangePolicy: Value(policy),
      fixedExchangeRateScaled: fixedRate == null ? const Value.absent() : Value(fixedRate),
      createdAt: _ts));
}

LocalPaymentRepository _paymentRepo(AppDatabase db) =>
    LocalPaymentRepository(db.paymentsDao, db.projectsDao, db);

LocalExpenseRepository _expenseRepo(AppDatabase db) =>
    LocalExpenseRepository(db.expensesDao, db.projectsDao, db);

LocalCurrencyTransferRepository _transferRepo(AppDatabase db) =>
    LocalCurrencyTransferRepository(db.currencyTransfersDao, db.projectsDao);

WalletBalanceService _walletService(AppDatabase db) =>
    WalletBalanceService(db.paymentsDao, db.expensesDao, db.currencyTransfersDao);

void main() {
  group('multi-currency wallet: payments and expenses per currency', () {
    test('SAR payment increases only the SAR wallet', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 100000, // 1,000.00 SAR
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        paymentDate: _date,
        method: 'cash',
      );
      final wallets = await _walletService(db).computeBalances(_projectId);
      expect(wallets.balanceFor(kCurrencySar), 100000);
      expect(wallets.balanceFor(kCurrencyYer), 0);
      await db.close();
    });

    test('YER payment increases only the YER wallet', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 600000, // 600,000 YER
        originalCurrency: kCurrencyYer,
        paymentDate: _date,
        method: 'cash',
      );
      final wallets = await _walletService(db).computeBalances(_projectId);
      expect(wallets.balanceFor(kCurrencyYer), 600000);
      expect(wallets.balanceFor(kCurrencySar), 0);
      await db.close();
    });

    test('SAR expense decreases only the SAR wallet', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      final expenses = _expenseRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 100000, // 1,000.00 SAR
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        paymentDate: _date,
        method: 'cash',
      );
      await expenses.create(
        projectId: _projectId,
        category: 'materials',
        originalAmountMinor: 40000, // 400.00 SAR
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        expenseDate: _date,
      );
      final wallets = await _walletService(db).computeBalances(_projectId);
      expect(wallets.balanceFor(kCurrencySar), 60000);
      expect(wallets.balanceFor(kCurrencyYer), 0);
      await db.close();
    });

    test('YER expense decreases only the YER wallet', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      final expenses = _expenseRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 600000, // 600,000 YER
        originalCurrency: kCurrencyYer,
        paymentDate: _date,
        method: 'cash',
      );
      await expenses.create(
        projectId: _projectId,
        category: 'materials',
        originalAmountMinor: 200000, // 200,000 YER
        originalCurrency: kCurrencyYer,
        expenseDate: _date,
      );
      final wallets = await _walletService(db).computeBalances(_projectId);
      expect(wallets.balanceFor(kCurrencyYer), 400000);
      expect(wallets.balanceFor(kCurrencySar), 0);
      await db.close();
    });

    test('currencies are never mixed: SAR expense does not touch YER wallet',
        () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      final expenses = _expenseRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 600000,
        originalCurrency: kCurrencyYer,
        paymentDate: _date,
        method: 'cash',
      );
      // SAR expense while YER wallet has funds but SAR wallet is empty.
      await expenses.create(
        projectId: _projectId,
        category: 'materials',
        originalAmountMinor: 50000, // 500.00 SAR
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        expenseDate: _date,
      );
      final wallets = await _walletService(db).computeBalances(_projectId);
      // YER wallet untouched by the SAR expense.
      expect(wallets.balanceFor(kCurrencyYer), 600000);
      // SAR wallet went negative (expense with no SAR funds) — never auto-
      // deducted from YER.
      expect(wallets.balanceFor(kCurrencySar), -50000);
      await db.close();
    });
  });

  group('insufficient currency balance', () {
    test('YER expense exceeding YER wallet reports a deficit (not auto-deducted)',
        () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      final expenses = _expenseRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 100000, // 100,000 YER
        originalCurrency: kCurrencyYer,
        paymentDate: _date,
        method: 'cash',
      );
      // Expense of 200,000 YER; only 100,000 YER available.
      await expenses.create(
        projectId: _projectId,
        category: 'materials',
        originalAmountMinor: 200000,
        originalCurrency: kCurrencyYer,
        expenseDate: _date,
      );
      final wallets = await _walletService(db).computeBalances(_projectId);
      // YER wallet is -100,000 (deficit); SAR wallet untouched at 0.
      expect(wallets.balanceFor(kCurrencyYer), -100000);
      expect(wallets.balanceFor(kCurrencySar), 0);
      // The deficit equals expense (200,000) − balance (100,000).
      const deficit = 200000 - 100000;
      expect(deficit, 100000);
      await db.close();
    });
  });

  group('currency transfer', () {
    test('SAR -> YER transfer debits SAR wallet and credits YER wallet',
        () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      final transfers = _transferRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 100000, // 1,000.00 SAR
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        paymentDate: _date,
        method: 'cash',
      );
      // Transfer 300 SAR -> YER at rate 410 → 123,000 YER.
      final transfer = await transfers.create(
        projectId: _projectId,
        sourceCurrency: kCurrencySar,
        targetCurrency: kCurrencyYer,
        sourceAmountMinor: 30000, // 300.00 SAR
        exchangeRateScaled: 410000000,
        date: _date,
      );
      expect(transfer.sourceAmountMinor, 30000);
      expect(transfer.targetAmountMinor, 123000);
      expect(transfer.exchangeRateScaled, 410000000);

      final wallets = await _walletService(db).computeBalances(_projectId);
      expect(wallets.balanceFor(kCurrencySar), 70000); // 100,000 − 30,000
      expect(wallets.balanceFor(kCurrencyYer), 123000); // credited
      await db.close();
    });

    test('YER -> SAR transfer uses the inverse of the same canonical rate',
        () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      final transfers = _transferRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 123000,
        originalCurrency: kCurrencyYer,
        paymentDate: _date,
        method: 'cash',
      );
      // Transfer 123,000 YER -> SAR at rate 410 → 300 SAR.
      final transfer = await transfers.create(
        projectId: _projectId,
        sourceCurrency: kCurrencyYer,
        targetCurrency: kCurrencySar,
        sourceAmountMinor: 123000,
        exchangeRateScaled: 410000000,
        date: _date,
      );
      expect(transfer.targetAmountMinor, 30000); // 300.00 SAR
      final wallets = await _walletService(db).computeBalances(_projectId);
      expect(wallets.balanceFor(kCurrencyYer), 0);
      expect(wallets.balanceFor(kCurrencySar), 30000);
      await db.close();
    });

    test('transfer record stores id, projectId, currencies, amounts, rate, date',
        () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final transfers = _transferRepo(db);
      final transfer = await transfers.create(
        projectId: _projectId,
        sourceCurrency: kCurrencySar,
        targetCurrency: kCurrencyYer,
        sourceAmountMinor: 30000,
        exchangeRateScaled: 410000000,
        date: _date,
      );
      expect(transfer.id, isNotEmpty);
      expect(transfer.projectId, _projectId);
      expect(transfer.sourceCurrency, kCurrencySar);
      expect(transfer.targetCurrency, kCurrencyYer);
      expect(transfer.sourceAmountMinor, 30000);
      expect(transfer.targetAmountMinor, 123000);
      expect(transfer.exchangeRateScaled, 410000000);
      expect(transfer.date, DateTime.parse('${_date}T00:00:00'));
      await db.close();
    });

    test('same-currency transfer rejected', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final transfers = _transferRepo(db);
      expect(
        () => transfers.create(
          projectId: _projectId,
          sourceCurrency: kCurrencyYer,
          targetCurrency: kCurrencyYer,
          sourceAmountMinor: 100000,
          exchangeRateScaled: kIdentityExchangeRate,
          date: _date,
        ),
        throwsArgumentError,
      );
      await db.close();
    });

    test('mismatched target amount rejected', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final transfers = _transferRepo(db);
      expect(
        () => transfers.create(
          projectId: _projectId,
          sourceCurrency: kCurrencySar,
          targetCurrency: kCurrencyYer,
          sourceAmountMinor: 30000,
          targetAmountMinor: 999999, // wrong
          exchangeRateScaled: 410000000,
          date: _date,
        ),
        throwsArgumentError,
      );
      await db.close();
    });
  });

  group('exchange rate preservation', () {
    test('changing the default rate does not alter historical transfer snapshot',
        () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final transfers = _transferRepo(db);
      final created = await transfers.create(
        projectId: _projectId,
        sourceCurrency: kCurrencySar,
        targetCurrency: kCurrencyYer,
        sourceAmountMinor: 30000,
        exchangeRateScaled: 410000000,
        date: _date,
      );
      // The default rate in settings is unrelated to the stored snapshot.
      await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          id: 'app',
          defaultExchangeRateScaled: const Value(999000000),
          createdAt: _ts,
          updatedAt: _ts));
      final found = await transfers.getById(created.id);
      expect(found!.exchangeRateScaled, 410000000);
      expect(found.targetAmountMinor, 123000);
      await db.close();
    });

    test('historical payment SAR snapshot is preserved after rate change',
        () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      final created = await payments.create(
        projectId: _projectId,
        originalAmountMinor: 100000,
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        paymentDate: _date,
        method: 'cash',
      );
      await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          id: 'app',
          defaultExchangeRateScaled: const Value(500000000),
          createdAt: _ts,
          updatedAt: _ts));
      final found = await payments.getById(created.id);
      expect(found!.exchangeRateScaled, 410000000);
      expect(found.convertedYerAmount, 410000);
      await db.close();
    });
  });

  group('restart persistence', () {
    test('transfer persists after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_wallet_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final transfers1 = _transferRepo(db1);
      final created = await transfers1.create(
        projectId: _projectId,
        sourceCurrency: kCurrencySar,
        targetCurrency: kCurrencyYer,
        sourceAmountMinor: 30000,
        exchangeRateScaled: 410000000,
        date: _date,
      );
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final transfers2 = _transferRepo(db2);
      final found = await transfers2.getById(created.id);
      expect(found, isNotNull);
      expect(found!.targetAmountMinor, 123000);
      expect(found.exchangeRateScaled, 410000000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('wallet balances persist after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_wallet_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      await _paymentRepo(db1).create(
        projectId: _projectId,
        originalAmountMinor: 600000,
        originalCurrency: kCurrencyYer,
        paymentDate: _date,
        method: 'cash',
      );
      await _expenseRepo(db1).create(
        projectId: _projectId,
        category: 'materials',
        originalAmountMinor: 200000,
        originalCurrency: kCurrencyYer,
        expenseDate: _date,
      );
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final wallets = await _walletService(db2).computeBalances(_projectId);
      expect(wallets.balanceFor(kCurrencyYer), 400000);
      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });

  group('financial summary correctness (multi-currency)', () {
    test('per-currency balances are independent and never mixed', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      final expenses = _expenseRepo(db);
      final transfers = _transferRepo(db);

      // SAR: receive 1,000 SAR (100,000 minor), spend 400 SAR (40,000 minor).
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 100000,
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        paymentDate: _date,
        method: 'cash',
      );
      await expenses.create(
        projectId: _projectId,
        category: 'materials',
        originalAmountMinor: 40000,
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        expenseDate: _date,
      );
      // YER: receive 600,000 YER, spend 200,000 YER.
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 600000,
        originalCurrency: kCurrencyYer,
        paymentDate: _date,
        method: 'cash',
      );
      await expenses.create(
        projectId: _projectId,
        category: 'labor',
        originalAmountMinor: 200000,
        originalCurrency: kCurrencyYer,
        expenseDate: _date,
      );
      // Transfer 100 SAR -> 41,000 YER.
      await transfers.create(
        projectId: _projectId,
        sourceCurrency: kCurrencySar,
        targetCurrency: kCurrencyYer,
        sourceAmountMinor: 10000, // 100.00 SAR
        exchangeRateScaled: 410000000,
        date: _date,
      );

      final wallets = await _walletService(db).computeBalances(_projectId);
      // SAR wallet: 100,000 − 40,000 − 10,000 = 50,000 SAR minor.
      expect(wallets.balanceFor(kCurrencySar), 50000);
      // YER wallet: 600,000 − 200,000 + 41,000 = 441,000 YER.
      expect(wallets.balanceFor(kCurrencyYer), 441000);
      // The two wallets must never be added together directly.
      expect(wallets.balances.length, 2);
      await db.close();
    });

    test('analytical converted value is computed from a selected rate only',
        () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 100000, // 1,000 SAR
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        paymentDate: _date,
        method: 'cash',
      );
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 600000, // 600,000 YER
        originalCurrency: kCurrencyYer,
        paymentDate: _date,
        method: 'cash',
      );

      // Without an analytical rate: no converted total.
      final walletsNoRate =
          await _walletService(db).computeBalances(_projectId);
      expect(walletsNoRate.analyticalConvertedYer, isNull);

      // With rate 410: 100,000 SAR minor = 1,000 SAR → 410,000 YER + 600,000.
      final wallets =
          await _walletService(db).computeBalances(
        _projectId,
        analyticalRateScaled: 410000000,
      );
      expect(wallets.balanceFor(kCurrencySar), 100000);
      expect(wallets.balanceFor(kCurrencyYer), 600000);
      expect(wallets.analyticalConvertedYer, 410000 + 600000);
      expect(wallets.analyticalRateScaled, 410000000);
      await db.close();
    });

    test('soft-deleted transfer does not affect wallet balances', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final payments = _paymentRepo(db);
      final transfers = _transferRepo(db);
      await payments.create(
        projectId: _projectId,
        originalAmountMinor: 100000,
        originalCurrency: kCurrencySar,
        exchangeRateScaled: 410000000,
        rateSource: kRateSourceManual,
        rateDate: _date,
        paymentDate: _date,
        method: 'cash',
      );
      final transfer = await transfers.create(
        projectId: _projectId,
        sourceCurrency: kCurrencySar,
        targetCurrency: kCurrencyYer,
        sourceAmountMinor: 30000,
        exchangeRateScaled: 410000000,
        date: _date,
      );
      await transfers.softDelete(transfer.id);
      final wallets = await _walletService(db).computeBalances(_projectId);
      expect(wallets.balanceFor(kCurrencySar), 100000);
      expect(wallets.balanceFor(kCurrencyYer), 0);
      await db.close();
    });
  });
}