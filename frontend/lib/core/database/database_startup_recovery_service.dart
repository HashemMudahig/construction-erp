import 'dart:io';

import 'package:drift/native.dart';

import 'app_database.dart';
import 'database_constants.dart';

enum DatabaseStartupRecoveryKind {
  noRecoveryNeeded,
  staleIncomingCleaned,
  staleRollbackCleaned,
  rollbackRestored,
  incomingPromoted,
}

class DatabaseStartupRecoveryResult {
  const DatabaseStartupRecoveryResult(this.kind);

  final DatabaseStartupRecoveryKind kind;
}

class DatabaseStartupRecoveryException implements Exception {
  const DatabaseStartupRecoveryException(
    this.message, {
    this.cause,
  });

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Resolves interrupted restore remnants before the production database is
/// exposed to Riverpod or any repository.
class DatabaseStartupRecoveryService {
  const DatabaseStartupRecoveryService();

  Future<DatabaseStartupRecoveryResult> recover(File canonical) async {
    final rollback = File('${canonical.path}.pre_restore');
    final incoming = File('${canonical.path}.incoming');
    final canonicalExists = await canonical.exists();
    final rollbackExists = await rollback.exists();
    final incomingExists = await incoming.exists();

    if (!canonicalExists && !rollbackExists && !incomingExists) {
      return const DatabaseStartupRecoveryResult(
        DatabaseStartupRecoveryKind.noRecoveryNeeded,
      );
    }

    if (canonicalExists && await _isValid(canonical)) {
      if (rollbackExists) {
        await _deleteDatabaseFiles(rollback);
        if (incomingExists) await _deleteDatabaseFiles(incoming);
        return const DatabaseStartupRecoveryResult(
          DatabaseStartupRecoveryKind.staleRollbackCleaned,
        );
      }
      if (incomingExists) {
        await _deleteDatabaseFiles(incoming);
        return const DatabaseStartupRecoveryResult(
          DatabaseStartupRecoveryKind.staleIncomingCleaned,
        );
      }
      return const DatabaseStartupRecoveryResult(
        DatabaseStartupRecoveryKind.noRecoveryNeeded,
      );
    }

    if (rollbackExists && await _isValid(rollback)) {
      if (canonicalExists) await _quarantine(canonical);
      await _promote(rollback, canonical);
      if (!await _isValid(canonical)) {
        throw const DatabaseStartupRecoveryException(
          'The local database could not be recovered safely.',
        );
      }
      if (incomingExists) await _deleteDatabaseFiles(incoming);
      return const DatabaseStartupRecoveryResult(
        DatabaseStartupRecoveryKind.rollbackRestored,
      );
    }

    if (incomingExists && await _isValid(incoming)) {
      if (canonicalExists) await _quarantine(canonical);
      await _promote(incoming, canonical);
      if (!await _isValid(canonical)) {
        throw const DatabaseStartupRecoveryException(
          'The incoming local database could not be recovered safely.',
        );
      }
      return const DatabaseStartupRecoveryResult(
        DatabaseStartupRecoveryKind.incomingPromoted,
      );
    }

    throw const DatabaseStartupRecoveryException(
      'Local data could not be opened. Restore a verified backup.',
    );
  }

  Future<bool> _isValid(File file) async {
    if (!await file.exists() || await file.length() == 0) return false;
    AppDatabase? database;
    try {
      database = AppDatabase(NativeDatabase(file));
      await database.customSelect('SELECT 1').getSingle();
      final integrity =
          await database.customSelect('PRAGMA integrity_check').getSingle();
      if (integrity.data.values.single.toString().toLowerCase() != 'ok') {
        return false;
      }
      final foreignKeys =
          await database.customSelect('PRAGMA foreign_key_check').get();
      if (foreignKeys.isNotEmpty) return false;
      final version =
          await database.customSelect('PRAGMA user_version').getSingle();
      if ((version.data.values.single as int) != kSchemaVersion) return false;
      const requiredTables = {
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
      final tables = rows.map((row) => row.read<String>('name')).toSet();
      return tables.containsAll(requiredTables);
    } catch (_) {
      return false;
    } finally {
      await database?.close();
    }
  }

  Future<void> _promote(File source, File canonical) async {
    await _deleteSidecars(canonical);
    await source.rename(canonical.path);
    await _deleteSidecars(source);
  }

  Future<void> _quarantine(File canonical) async {
    await _deleteSidecars(canonical);
    final quarantine = File(
      '${canonical.path}.corrupt_${DateTime.now().toUtc().microsecondsSinceEpoch}',
    );
    await canonical.rename(quarantine.path);
  }

  Future<void> _deleteDatabaseFiles(File file) async {
    if (await file.exists()) await file.delete();
    await _deleteSidecars(file);
  }

  Future<void> _deleteSidecars(File file) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('${file.path}$suffix');
      if (await sidecar.exists()) await sidecar.delete();
    }
  }
}
