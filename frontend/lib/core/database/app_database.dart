import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_constants.dart';
import 'tables/clients_table.dart';
import 'tables/projects_table.dart';
import 'tables/milestones_table.dart';
import 'tables/payments_table.dart';
import 'tables/expenses_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/currency_transfers_table.dart';
import 'daos/clients_dao.dart';
import 'daos/projects_dao.dart';
import 'daos/milestones_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/app_settings_dao.dart';
import 'daos/currency_transfers_dao.dart';

part 'app_database.g.dart';

/// Local SQLite database for the Construction ERP application.
///
/// Managed by [databaseProvider]. Do not instantiate directly outside tests.
///
/// Schema versioning:
/// - Version 1: Initial schema (clients, projects, milestones, payments,
///   expenses, app_settings).
/// - Version 2: Add soft-delete fields to payments table.
/// - Version 3: Add soft-delete fields to expenses table.
/// - Version 4: Move the verified locale preference into app_settings.
/// - Version 5: Preserve the original contract value separately from the
///   current (possibly amended) contract value.
/// - Version 6: Add the currency_transfers table for multi-currency wallet
///   transfer records.
/// - Future versions: Add migration steps in [MigrationStrategy.onUpgrade].
///
/// Foreign keys are enabled via [beforeOpen] callback on every connection.
///
/// All financial values use scaled INTEGER storage (ADR-005). No REAL columns.
@DriftDatabase(
  tables: [
    Clients,
    Projects,
    Milestones,
    Payments,
    Expenses,
    AppSettings,
    CurrencyTransfers,
  ],
  daos: [
    ClientsDao,
    ProjectsDao,
    MilestonesDao,
    PaymentsDao,
    ExpensesDao,
    AppSettingsDao,
    CurrencyTransfersDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Creates an [AppDatabase] using a [NativeDatabase] at the given [name].
  ///
  /// For tests, pass [name] as an in-memory path or use [forTesting].
  AppDatabase(super.e);

  /// Creates an [AppDatabase] for testing with an in-memory connection.
  AppDatabase.forTesting(super.executor);

  /// Creates an [AppDatabase] using a file in the app's documents directory.
  ///
  /// This is the production constructor used by [databaseProvider].
  static Future<AppDatabase> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, kDatabaseFileName));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  int get schemaVersion => kSchemaVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Schema v2: Add soft-delete fields to payments table.
        if (from < 2) {
          await m.addColumn(payments, payments.isDeleted);
          await m.addColumn(payments, payments.deletedAt);
        }
        // Schema v3: Add soft-delete fields to expenses table.
        if (from < 3) {
          await m.addColumn(expenses, expenses.isDeleted);
          await m.addColumn(expenses, expenses.deletedAt);
        }
        // Schema v4: Move the verified locale preference into app_settings.
        if (from < 4) {
          await m.addColumn(appSettings, appSettings.localeCode);
        }
        // Schema v5: Preserve the original contract value separately from the
        // current (possibly amended) contract value. Backfill existing rows
        // with their current budget so the original is not lost. Guarded for
        // idempotency when restoring a backup whose file already has the
        // column but whose user_version is older.
        if (from < 5) {
          final cols = await customSelect(
            'PRAGMA table_info(projects)',
            readsFrom: {projects},
          ).get();
          final hasOriginal = cols.any(
              (r) => r.read<String>('name') == 'original_contract_value_minor');
          if (!hasOriginal) {
            await m.addColumn(projects, projects.originalContractValueMinor);
          }
          await customStatement(
            'UPDATE projects SET original_contract_value_minor = budget_amount_minor '
            'WHERE original_contract_value_minor = 0 OR original_contract_value_minor IS NULL',
          );
        }
        // Schema v6: Add the currency_transfers table. Guarded for
        // idempotency when restoring a backup whose file already has the
        // table but whose user_version is older.
        if (from < 6) {
          final cols = await customSelect(
            'PRAGMA table_info(currency_transfers)',
            readsFrom: {currencyTransfers},
          ).get();
          if (cols.isEmpty) {
            await m.createTable(currencyTransfers);
          }
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys on every connection.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
