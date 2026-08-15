import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/database/daos/dashboard_dao.dart';
import 'package:construction_erp/features/dashboard/data/local_dashboard_repository.dart';
import 'package:construction_erp/features/projects/data/local_project_repository.dart';
import 'package:construction_erp/features/transfers/data/local_currency_transfer_repository.dart';
import 'package:construction_erp/features/transfers/domain/wallet_balance_service.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _ts = '2026-01-01T00:00:00Z';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seedClient(AppDatabase db) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
      id: _clientId, name: 'Owner', createdAt: _ts, updatedAt: _ts));
}

LocalProjectRepository _projectRepo(AppDatabase db) =>
    LocalProjectRepository(db.projectsDao, db.clientsDao, db);

LocalDashboardRepository _dashboard(AppDatabase db) => LocalDashboardRepository(
      DashboardDao(db),
      WalletBalanceService(
        db.paymentsDao,
        db.expensesDao,
        db.currencyTransfersDao,
      ),
    );

LocalCurrencyTransferRepository _transferRepo(AppDatabase db) =>
    LocalCurrencyTransferRepository(db.currencyTransfersDao, db.projectsDao);

void main() {
  group('Dashboard global wallet balances', () {
    test('TEST 1: no projects -> SAR = 0, YER = 0', () async {
      final db = _createDb();
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      expect(wallets.balanceFor(kCurrencySar), 0);
      expect(wallets.balanceFor(kCurrencyYer), 0);
      await db.close();
    });

    test('TEST 2: one project with SAR payment -> SAR = 10,000, YER = 0',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final project = await _projectRepo(db).create(
        clientId: _clientId,
        name: 'SAR Project',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencySar,
      );
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 1000000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 410000000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      expect(wallets.balanceFor(kCurrencySar), 1000000);
      expect(wallets.balanceFor(kCurrencyYer), 0);
      await db.close();
    });

    test('TEST 3: one project with YER payment -> YER = 600,000, SAR = 0',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final project = await _projectRepo(db).create(
        clientId: _clientId,
        name: 'YER Project',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 600000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 600000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      expect(wallets.balanceFor(kCurrencySar), 0);
      expect(wallets.balanceFor(kCurrencyYer), 600000);
      await db.close();
    });

    test('TEST 4: mixed currencies -> SAR = 10,000, YER = 600,000 (NOT added)',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final project = await _projectRepo(db).create(
        clientId: _clientId,
        name: 'Mixed',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 1000000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          convertedYerAmount: 410000000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000002',
          projectId: project.id,
          originalAmountMinor: 600000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 600000,
          paymentDate: '2026-02-02',
          method: 'cash',
          createdAt: _ts));
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      expect(wallets.balanceFor(kCurrencySar), 1000000);
      expect(wallets.balanceFor(kCurrencyYer), 600000);
      // Currencies must never be mixed into a single YER total.
      expect(wallets.balanceFor(kCurrencyYer), isNot(410600000));
      await db.close();
    });

    test('TEST 5: expense -> YER = 400,000', () async {
      final db = _createDb();
      await _seedClient(db);
      final project = await _projectRepo(db).create(
        clientId: _clientId,
        name: 'Expense Test',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 600000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 600000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'dddddddd-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 200000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 200000,
          category: 'labor',
          expenseDate: '2026-02-05',
          createdAt: _ts));
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      expect(wallets.balanceFor(kCurrencyYer), 400000);
      expect(wallets.balanceFor(kCurrencySar), 0);
      await db.close();
    });

    test('TEST 6: currency transfer -> SAR = 9,000, YER = 410,000', () async {
      final db = _createDb();
      await _seedClient(db);
      final project = await _projectRepo(db).create(
        clientId: _clientId,
        name: 'Transfer Test',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 1000000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 410000000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      await _transferRepo(db).create(
          projectId: project.id,
          sourceCurrency: kCurrencySar,
          targetCurrency: kCurrencyYer,
          sourceAmountMinor: 100000,
          exchangeRateScaled: 410000000,
          date: '2026-02-10');
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      expect(wallets.balanceFor(kCurrencySar), 900000);
      expect(wallets.balanceFor(kCurrencyYer), 410000);
      await db.close();
    });

    test('TEST 7: multiple projects -> global aggregation', () async {
      final db = _createDb();
      await _seedClient(db);
      await db.into(db.clients).insert(ClientsCompanion.insert(
          id: 'aaaaaaaa-0000-4000-8000-000000000002',
          name: 'Owner 2',
          createdAt: _ts,
          updatedAt: _ts));
      final repo = _projectRepo(db);
      final p1 = await repo.create(
        clientId: _clientId,
        name: 'P1',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      final p2 = await repo.create(
        clientId: 'aaaaaaaa-0000-4000-8000-000000000002',
        name: 'P2',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: p1.id,
          originalAmountMinor: 500000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 500000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000002',
          projectId: p2.id,
          originalAmountMinor: 300000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          convertedYerAmount: 123000000,
          paymentDate: '2026-02-02',
          method: 'cash',
          createdAt: _ts));
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      expect(wallets.balanceFor(kCurrencyYer), 500000);
      expect(wallets.balanceFor(kCurrencySar), 300000);
      await db.close();
    });

    test('TEST 8: negative wallet -> YER = -100,000', () async {
      final db = _createDb();
      await _seedClient(db);
      final project = await _projectRepo(db).create(
        clientId: _clientId,
        name: 'Negative',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 100000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 100000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'dddddddd-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 200000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 200000,
          category: 'materials',
          expenseDate: '2026-02-05',
          createdAt: _ts));
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      expect(wallets.balanceFor(kCurrencyYer), -100000);
      await db.close();
    });

    test(
        'TEST 9: legacy converted_yer_amount anomaly does NOT affect wallet',
        () async {
      final db = _createDb();
      await _seedClient(db);
      final project = await _projectRepo(db).create(
        clientId: _clientId,
        name: 'Legacy',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      // Insert a payment with a deliberately inflated converted_yer_amount
      // (simulating the historical scaling bug). The wallet must use
      // original_amount_minor, NOT converted_yer_amount.
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 120000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 4100000000000,
          convertedYerAmount: 4920000000000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      // Wallet uses original_amount_minor (120,000 SAR minor = 1,200.00 SAR).
      expect(wallets.balanceFor(kCurrencySar), 120000);
      // YER wallet must NOT be 4,920,000,000,000.
      expect(wallets.balanceFor(kCurrencyYer), 0);
      expect(wallets.balanceFor(kCurrencyYer), isNot(4920000000000));
      await db.close();
    });

    test('TEST 10: soft-deleted transactions are excluded', () async {
      final db = _createDb();
      await _seedClient(db);
      final project = await _projectRepo(db).create(
        clientId: _clientId,
        name: 'SoftDelete',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      // Active payment.
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 500000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 500000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      // Soft-deleted payment (must be excluded).
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000002',
          projectId: project.id,
          originalAmountMinor: 999000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 999000,
          paymentDate: '2026-02-02',
          method: 'cash',
          createdAt: _ts,
          isDeleted: const Value(true)));
      // Soft-deleted expense (must be excluded).
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'dddddddd-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 999000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 999000,
          category: 'materials',
          expenseDate: '2026-02-03',
          createdAt: _ts,
          isDeleted: const Value(true)));
      // Soft-deleted transfer (must be excluded).
      await db.into(db.currencyTransfers).insert(CurrencyTransfersCompanion.insert(
          id: 'eeeeeeee-0000-4000-8000-000000000001',
          projectId: project.id,
          sourceCurrency: kCurrencySar,
          targetCurrency: kCurrencyYer,
          sourceAmountMinor: 100000,
          targetAmountMinor: 41000000,
          exchangeRateScaled: 410000000,
          date: '2026-02-04',
          createdAt: _ts,
          isDeleted: const Value(true)));
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      expect(wallets.balanceFor(kCurrencyYer), 500000);
      expect(wallets.balanceFor(kCurrencySar), 0);
      await db.close();
    });
  });

  group('Dashboard global wallet — currency independence invariant', () {
    test('SAR and YER are never added together', () async {
      final db = _createDb();
      await _seedClient(db);
      final project = await _projectRepo(db).create(
        clientId: _clientId,
        name: 'Invariant',
        budgetAmountMinor: 1000000,
        budgetCurrency: kCurrencyYer,
      );
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000001',
          projectId: project.id,
          originalAmountMinor: 1000000,
          originalCurrency: kCurrencySar,
          exchangeRateScaled: 410000000,
          convertedYerAmount: 410000000,
          paymentDate: '2026-02-01',
          method: 'cash',
          createdAt: _ts));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'cccccccc-0000-4000-8000-000000000002',
          projectId: project.id,
          originalAmountMinor: 500000,
          originalCurrency: kCurrencyYer,
          exchangeRateScaled: kIdentityExchangeRate,
          convertedYerAmount: 500000,
          paymentDate: '2026-02-02',
          method: 'cash',
          createdAt: _ts));
      final wallets = await _dashboard(db).getGlobalWalletBalances();
      // The wallet must keep SAR and YER separate — the converted analytical
      // total (410,500,000) must never appear as a single balance.
      expect(wallets.balanceFor(kCurrencySar), 1000000);
      expect(wallets.balanceFor(kCurrencyYer), 500000);
      expect(wallets.balances, hasLength(2));
      expect(wallets.balances.every((e) => e.currency == kCurrencySar ||
          e.currency == kCurrencyYer), true);
      await db.close();
    });
  });
}