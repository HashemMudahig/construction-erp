import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/database/database_provider.dart';
import 'package:construction_erp/features/expenses/data/local_expense_repository.dart';
import 'package:construction_erp/features/payments/data/local_payment_repository.dart';
import 'package:construction_erp/features/settings/data/local_settings_repository.dart';
import 'package:construction_erp/features/settings/domain/app_settings.dart';
import 'package:construction_erp/features/settings/presentation/settings_provider.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _paymentId = 'cccccccc-0000-4000-8000-000000000001';
const _expenseId = 'dddddddd-0000-4000-8000-000000000001';
const _timestamp = '2026-01-01T00:00:00Z';

LocalSettingsRepository _repository(AppDatabase db) => LocalSettingsRepository(
      db.appSettingsDao,
      utcNow: () => DateTime.utc(2026, 1, 1),
    );

Future<void> _seedProject(AppDatabase db, {bool fixed = false}) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
        id: _clientId,
        name: 'Client',
        createdAt: _timestamp,
        updatedAt: _timestamp,
      ));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
        id: _projectId,
        clientId: _clientId,
        name: 'Project',
        budgetAmountMinor: 0,
        budgetCurrency: 'SAR',
        exchangePolicy: Value(fixed ? 'fixed' : 'per_transaction'),
        fixedExchangeRateScaled:
            fixed ? const Value(400000000) : const Value(null),
        createdAt: _timestamp,
      ));
}

void main() {
  test('active provider resolves to LocalSettingsRepository without Dio',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    expect(
      container.read(settingsRepositoryProvider),
      isA<LocalSettingsRepository>(),
    );
    container.dispose();
    await db.close();
  });

  test('empty database receives exact defaults idempotently', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = _repository(db);
    final first = await repo.loadSettings();
    final second = await repo.loadSettings();
    expect(first, AppSettingsEntity.defaults);
    expect(second, first);
    expect(await db.select(db.appSettings).get(), hasLength(1));
    await db.close();
  });

  test('existing valid values are not overwritten by seeding', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          id: 'app',
          defaultExchangeRateScaled: const Value(425500000),
          localeCode: const Value('ar'),
          createdAt: _timestamp,
          updatedAt: _timestamp,
        ));
    final settings = await _repository(db).loadSettings();
    expect(settings.defaultSarToYerRateScaled, 425500000);
    expect(settings.localeCode, 'ar');
    await db.close();
  });

  test('unknown rows cannot alter canonical typed settings', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = _repository(db);
    await repo.loadSettings();
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          id: 'other',
          defaultExchangeRateScaled: const Value(999000000),
          localeCode: const Value('ar'),
          createdAt: _timestamp,
          updatedAt: _timestamp,
        ));
    expect(await repo.loadSettings(), AppSettingsEntity.defaults);
    await db.close();
  });

  test('malformed stored values use safe defaults', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          id: 'app',
          defaultExchangeRateScaled: const Value(-1),
          localeCode: const Value('unsupported'),
          createdAt: _timestamp,
          updatedAt: _timestamp,
        ));
    expect(await _repository(db).loadSettings(), AppSettingsEntity.defaults);
    await db.close();
  });

  group('exchange rate validation', () {
    test('positive exact rate is accepted and repeated save is deterministic',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = _repository(db);
      final first = await repo.updateDefaultSarToYerRate('412.750001');
      final second = await repo.updateDefaultSarToYerRate('412.750001');
      expect(first.defaultSarToYerRateScaled, 412750001);
      expect(second, first);
      await db.close();
    });

    test('zero, negative, malformed, and excess precision are rejected',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = _repository(db);
      for (final value in ['0', '-1', 'abc', '410.0000001']) {
        expect(
          repo.updateDefaultSarToYerRate(value),
          throwsA(isA<SettingsValidationException>()),
        );
      }
      await db.close();
    });

    test('invalid update preserves previous valid value', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = _repository(db);
      await repo.updateDefaultSarToYerRate('420');
      await expectLater(
        repo.updateDefaultSarToYerRate('0'),
        throwsA(isA<SettingsValidationException>()),
      );
      expect((await repo.loadSettings()).defaultSarToYerRateScaled, 420000000);
      await db.close();
    });
  });

  test('supported locales persist and unsupported locale is rejected',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = _repository(db);
    expect((await repo.updateLocale('ar')).localeCode, 'ar');
    expect((await repo.updateLocale('en')).localeCode, 'en');
    expect(
      repo.updateLocale('fr'),
      throwsA(isA<SettingsValidationException>()),
    );
    await db.close();
  });

  test('settings persist after file reopen', () async {
    final directory = await Directory.systemTemp.createTemp('phase10_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/settings.sqlite');
    final first = AppDatabase(NativeDatabase(file));
    await _repository(first).updateDefaultSarToYerRate('430.125');
    await _repository(first).updateLocale('ar');
    await first.close();
    final second = AppDatabase(NativeDatabase(file));
    final settings = await _repository(second).loadSettings();
    expect(settings.defaultSarToYerRateScaled, 430125000);
    expect(settings.localeCode, 'ar');
    await second.close();
  });

  test('schema v3 migrates non-destructively and seeds locale default',
      () async {
    final directory = await Directory.systemTemp.createTemp('phase10_v3_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/migration.sqlite');
    final legacy = AppDatabase(NativeDatabase(file));
    await legacy.into(legacy.appSettings).insert(AppSettingsCompanion.insert(
          id: 'app',
          defaultExchangeRateScaled: const Value(415000000),
          createdAt: _timestamp,
          updatedAt: _timestamp,
        ));
    await legacy.customStatement(
      'ALTER TABLE app_settings DROP COLUMN locale_code',
    );
    await legacy.customStatement('PRAGMA user_version = 3');
    await legacy.close();
    final db = AppDatabase(NativeDatabase(file));
    final settings = await _repository(db).loadSettings();
    expect(settings.defaultSarToYerRateScaled, 415000000);
    expect(settings.localeCode, 'en');
    expect(db.schemaVersion, 6);
    await db.close();
  });

  test('rate update never changes historical snapshots or fixed project rate',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    await _seedProject(db, fixed: true);
    await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: _paymentId,
          projectId: _projectId,
          originalAmountMinor: 10000,
          originalCurrency: 'SAR',
          exchangeRateScaled: 400000000,
          convertedYerAmount: 40000,
          paymentDate: '2026-01-01',
          method: 'cash',
          createdAt: _timestamp,
        ));
    await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: _expenseId,
          projectId: _projectId,
          originalAmountMinor: 5000,
          originalCurrency: 'SAR',
          exchangeRateScaled: 400000000,
          convertedYerAmount: 20000,
          category: 'labor',
          expenseDate: '2026-01-01',
          createdAt: _timestamp,
        ));
    await _repository(db).updateDefaultSarToYerRate('450');
    final project = await db.projectsDao.getProjectById(_projectId);
    final payment = await db.paymentsDao.getPaymentById(_paymentId);
    final expense = await db.expensesDao.getExpenseById(_expenseId);
    expect(project!.fixedExchangeRateScaled, 400000000);
    expect(payment!.exchangeRateScaled, 400000000);
    expect(payment.convertedYerAmount, 40000);
    expect(expense!.exchangeRateScaled, 400000000);
    expect(expense.convertedYerAmount, 20000);
    await db.close();
  });

  test('new per-transaction SAR payment and expense use updated default',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    await _seedProject(db);
    final settings = _repository(db);
    await settings.updateDefaultSarToYerRate('420');
    final paymentRepo = LocalPaymentRepository(
      db.paymentsDao,
      db.projectsDao,
      db,
      settings,
    );
    final expenseRepo = LocalExpenseRepository(
      db.expensesDao,
      db.projectsDao,
      db,
      settings,
    );
    final payment = await paymentRepo.create(
      projectId: _projectId,
      originalAmountMinor: 10000,
      originalCurrency: 'SAR',
      paymentDate: '2026-02-01',
      method: 'cash',
    );
    final expense = await expenseRepo.create(
      projectId: _projectId,
      category: 'labor',
      originalAmountMinor: 5000,
      originalCurrency: 'SAR',
      expenseDate: '2026-02-01',
    );
    expect(payment.exchangeRateScaled, 420000000);
    expect(payment.convertedYerAmount, 42000);
    expect(payment.rateSource, 'default');
    expect(expense.exchangeRateScaled, 420000000);
    expect(expense.convertedYerAmount, 21000);
    expect(expense.rateSource, 'default');
    await db.close();
  });

  test('YER remains identity and manual rates remain available', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await _seedProject(db);
    final repo = LocalPaymentRepository(
      db.paymentsDao,
      db.projectsDao,
      db,
      _repository(db),
    );
    final yer = await repo.create(
      projectId: _projectId,
      originalAmountMinor: 100,
      originalCurrency: 'YER',
      paymentDate: '2026-02-01',
      method: 'cash',
    );
    final manual = await repo.create(
      projectId: _projectId,
      originalAmountMinor: 10000,
      originalCurrency: 'SAR',
      exchangeRateScaled: 430000000,
      rateSource: 'manual',
      paymentDate: '2026-02-01',
      method: 'cash',
    );
    // YER payment against a SAR contract is cross-currency: the YER/SAR rate
    // is resolved from settings (default 410000000) so the contract-currency
    // aggregation can convert YER→SAR on read. The YER snapshot stays equal
    // to the original YER amount (identity for YER reporting).
    expect(yer.exchangeRateScaled, 410000000);
    expect(yer.convertedYerAmount, 100);
    expect(manual.exchangeRateScaled, 430000000);
    expect(manual.rateSource, 'manual');
    await db.close();
  });
}
