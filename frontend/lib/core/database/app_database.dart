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
import 'daos/clients_dao.dart';
import 'daos/projects_dao.dart';
import 'daos/milestones_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/app_settings_dao.dart';

part 'app_database.g.dart';

/// Local SQLite database for the Construction ERP application.
///
/// Managed by [databaseProvider]. Do not instantiate directly outside tests.
///
/// Schema versioning:
/// - Version 1: Initial schema (clients, projects, milestones, payments,
///   expenses, app_settings).
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
  ],
  daos: [
    ClientsDao,
    ProjectsDao,
    MilestonesDao,
    PaymentsDao,
    ExpensesDao,
    AppSettingsDao,
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
      },
      beforeOpen: (details) async {
        // Enable foreign keys on every connection.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
