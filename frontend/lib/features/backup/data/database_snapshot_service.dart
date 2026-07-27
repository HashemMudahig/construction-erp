import 'dart:io';

import '../../../core/database/app_database.dart';
import '../domain/backup_exceptions.dart';
import '../domain/backup_manifest.dart';

class DatabaseSnapshotService {
  const DatabaseSnapshotService();

  Future<File> createSnapshot(AppDatabase database, File destination) async {
    if (await destination.exists()) await destination.delete();
    final escaped = destination.path.replaceAll("'", "''");
    try {
      await database.customStatement("VACUUM INTO '$escaped'");
    } catch (_) {
      throw const BackupException(
          'A consistent local database snapshot could not be created.');
    }
    if (!await destination.exists() || await destination.length() == 0) {
      throw const BackupException('The database snapshot is empty.');
    }
    return destination;
  }

  Future<BackupRecordCounts> validateAndCount(AppDatabase database) async {
    final integrity =
        await database.customSelect('PRAGMA integrity_check').get();
    if (integrity.length != 1 ||
        integrity.single.data.values.single.toString().toLowerCase() != 'ok') {
      throw const BackupValidationException(
          'The backup database failed its integrity check.');
    }
    final foreignKeys =
        await database.customSelect('PRAGMA foreign_key_check').get();
    if (foreignKeys.isNotEmpty) {
      throw const BackupValidationException(
          'The backup database contains invalid relationships.');
    }
    await _requireCoreTables(database);
    return BackupRecordCounts(
      clients: await _count(database, 'clients'),
      projects: await _count(database, 'projects'),
      milestones: await _count(database, 'milestones'),
      payments: await _count(database, 'payments'),
      expenses: await _count(database, 'expenses'),
      appSettings: await _count(database, 'app_settings'),
    );
  }

  Future<int> readSchemaVersion(AppDatabase database) async {
    final row = await database.customSelect('PRAGMA user_version').getSingle();
    return row.data.values.single as int;
  }

  Future<void> _requireCoreTables(AppDatabase database) async {
    const expected = {
      'clients',
      'projects',
      'milestones',
      'payments',
      'expenses',
      'app_settings',
    };
    final rows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    final found = rows.map((row) => row.read<String>('name')).toSet();
    if (!found.containsAll(expected)) {
      throw const BackupValidationException(
          'The backup database is missing required data tables.');
    }
  }

  Future<int> _count(AppDatabase database, String table) async {
    final row = await database
        .customSelect('SELECT COUNT(*) AS total FROM $table')
        .getSingle();
    return row.read<int>('total');
  }
}
