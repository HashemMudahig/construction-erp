import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_provider.dart';
import '../domain/backup_exceptions.dart';
import '../domain/backup_manifest.dart';
import '../domain/backup_models.dart';
import '../domain/backup_repository_interface.dart';
import 'backup_archive_service.dart';
import 'backup_checksum_service.dart';
import 'database_snapshot_service.dart';

typedef ActiveDatabaseReader = AppDatabase Function();
typedef ActiveDatabaseCloser = Future<void> Function();
typedef ActiveDatabaseReopener = Future<AppDatabase> Function();
typedef ActiveDatabaseFileResolver = Future<File> Function();

class LocalBackupRepository implements BackupRepositoryInterface {
  LocalBackupRepository({
    required ActiveDatabaseReader activeDatabase,
    required ActiveDatabaseCloser closeActiveDatabase,
    required ActiveDatabaseReopener reopenActiveDatabase,
    required ActiveDatabaseFileResolver resolveActiveDatabaseFile,
    required Future<Directory> Function() temporaryDirectory,
    BackupArchiveService archiveService = const BackupArchiveService(),
    BackupChecksumService checksumService = const BackupChecksumService(),
    DatabaseSnapshotService snapshotService = const DatabaseSnapshotService(),
    DateTime Function()? utcClock,
    String Function()? tokenFactory,
  })  : _activeDatabase = activeDatabase,
        _closeActiveDatabase = closeActiveDatabase,
        _reopenActiveDatabase = reopenActiveDatabase,
        _resolveActiveDatabaseFile = resolveActiveDatabaseFile,
        _temporaryDirectory = temporaryDirectory,
        _archiveService = archiveService,
        _checksumService = checksumService,
        _snapshotService = snapshotService,
        _utcClock = utcClock ?? (() => DateTime.now().toUtc()),
        _tokenFactory = tokenFactory ?? (() => const Uuid().v4());

  final ActiveDatabaseReader _activeDatabase;
  final ActiveDatabaseCloser _closeActiveDatabase;
  final ActiveDatabaseReopener _reopenActiveDatabase;
  final ActiveDatabaseFileResolver _resolveActiveDatabaseFile;
  final Future<Directory> Function() _temporaryDirectory;
  final BackupArchiveService _archiveService;
  final BackupChecksumService _checksumService;
  final DatabaseSnapshotService _snapshotService;
  final DateTime Function() _utcClock;
  final String Function() _tokenFactory;
  final Map<String, _ValidatedRestore> _pending = {};
  bool _busy = false;

  @override
  Future<BackupOperationResult> createBackup(String destinationPath) =>
      _exclusive(() async {
        final destination = File(destinationPath.endsWith('.cerpbackup')
            ? destinationPath
            : '$destinationPath.cerpbackup');
        if (await destination.exists()) {
          throw const BackupException(
              'A backup already exists at the selected destination.');
        }
        final work = await _newWorkDirectory('create');
        try {
          final snapshot = File(p.join(work.path, kBackupDatabaseEntryName));
          await _snapshotService.createSnapshot(_activeDatabase(), snapshot);
          final snapshotDatabase =
              AppDatabase(NativeDatabase.createInBackground(snapshot));
          late BackupRecordCounts counts;
          try {
            counts = await _snapshotService.validateAndCount(snapshotDatabase);
          } finally {
            await snapshotDatabase.close();
          }
          final size = await snapshot.length();
          final manifest = BackupManifest(
            backupFormatVersion: kBackupFormatVersion,
            applicationId: kBackupApplicationId,
            createdAtUtc: _utcClock().toUtc(),
            databaseEntryName: kBackupDatabaseEntryName,
            databaseSchemaVersion: kSchemaVersion,
            databaseSizeBytes: size,
            databaseSha256: await _checksumService.sha256File(snapshot),
            applicationVersion: '1.0.0+1',
            recordCounts: counts,
          );
          final temporaryArchive = File(p.join(work.path, 'backup.cerpbackup'));
          await _archiveService.createArchive(
            output: temporaryArchive,
            database: snapshot,
            manifest: manifest,
          );
          await destination.parent.create(recursive: true);
          await temporaryArchive.copy(destination.path);
          if (!await destination.exists() || await destination.length() == 0) {
            throw const BackupException(
                'The backup could not be saved at the selected destination.');
          }
          return BackupOperationResult(
            displayPath: destination.path,
            manifest: manifest,
          );
        } finally {
          await _deleteDirectory(work);
        }
      });

  @override
  Future<BackupPreview> inspectBackup(String sourcePath) =>
      _exclusive(() async {
        await cancelPendingRestore();
        final work = await _newWorkDirectory('inspect');
        try {
          final selected = File(sourcePath);
          final controlled = File(p.join(work.path, 'selected.cerpbackup'));
          await selected.copy(controlled.path);
          final extracted =
              await _archiveService.inspectAndExtract(controlled, work);
          if (await extracted.databaseFile.length() !=
              extracted.manifest.databaseSizeBytes) {
            throw const BackupValidationException(
                'The backup database size does not match its manifest.');
          }
          final checksum =
              await _checksumService.sha256File(extracted.databaseFile);
          if (checksum != extracted.manifest.databaseSha256) {
            throw const BackupValidationException(
                'The backup checksum does not match.');
          }
          final staging = AppDatabase(
              NativeDatabase.createInBackground(extracted.databaseFile));
          late BackupRecordCounts counts;
          try {
            await staging.customSelect('SELECT 1').getSingle();
            final schema = await _snapshotService.readSchemaVersion(staging);
            if (schema != kSchemaVersion) {
              throw const BackupValidationException(
                  'The backup database could not be migrated safely.');
            }
            counts = await _snapshotService.validateAndCount(staging);
          } finally {
            await staging.close();
          }
          if (counts != extracted.manifest.recordCounts) {
            throw const BackupValidationException(
                'The backup record counts do not match its manifest.');
          }
          final token = _tokenFactory();
          _pending[token] = _ValidatedRestore(
            directory: work,
            databaseFile: extracted.databaseFile,
            manifest: extracted.manifest,
            sourceDisplayName: p.basename(sourcePath),
          );
          return BackupPreview(
            validationToken: token,
            displayName: p.basename(sourcePath),
            manifest: extracted.manifest,
            isMigrationRequired:
                extracted.manifest.databaseSchemaVersion < kSchemaVersion,
          );
        } catch (_) {
          await _deleteDirectory(work);
          rethrow;
        }
      });

  @override
  Future<BackupOperationResult> restoreBackup(BackupPreview preview) =>
      _exclusive(() async {
        final validated = _pending.remove(preview.validationToken);
        if (validated == null ||
            validated.manifest.databaseSha256 !=
                preview.manifest.databaseSha256) {
          throw const BackupValidationException(
              'The restore preview is no longer valid.');
        }
        final active = await _resolveActiveDatabaseFile();
        final rollback = File('${active.path}.pre_restore');
        final incoming = File('${active.path}.incoming');
        await validated.databaseFile.copy(incoming.path);
        var activeMoved = false;
        try {
          await _closeActiveDatabase();
          await _deleteSidecars(active);
          if (await rollback.exists()) await rollback.delete();
          if (await active.exists()) {
            await active.rename(rollback.path);
            activeMoved = true;
          }
          await incoming.rename(active.path);
          final reopened = await _reopenActiveDatabase();
          final counts = await _snapshotService.validateAndCount(reopened);
          final schema = await _snapshotService.readSchemaVersion(reopened);
          if (schema != kSchemaVersion ||
              counts != validated.manifest.recordCounts) {
            throw const BackupValidationException(
                'The restored database failed its final validation.');
          }
          if (await rollback.exists()) await rollback.delete();
          await _deleteDirectory(validated.directory);
          return BackupOperationResult(
            displayPath: validated.sourceDisplayName,
            manifest: validated.manifest,
          );
        } catch (_) {
          try {
            await _closeActiveDatabase();
          } catch (_) {}
          if (await active.exists()) await active.delete();
          if (activeMoved && await rollback.exists()) {
            await rollback.rename(active.path);
          }
          if (await incoming.exists()) await incoming.delete();
          final original = await _reopenActiveDatabase();
          await _snapshotService.validateAndCount(original);
          await _deleteDirectory(validated.directory);
          throw const BackupException(
              'Restore failed. The original local data was retained.');
        } finally {
          if (await incoming.exists()) await incoming.delete();
        }
      });

  @override
  Future<void> cancelPendingRestore() async {
    final values = _pending.values.toList();
    _pending.clear();
    for (final pending in values) {
      await _deleteDirectory(pending.directory);
    }
  }

  @override
  Future<void> cleanTemporaryFiles() => cancelPendingRestore();

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    if (_busy) throw const BackupBusyException();
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  Future<Directory> _newWorkDirectory(String operation) async {
    final root = await _temporaryDirectory();
    return Directory(
      p.join(
          root.path, 'construction_erp_backup_${operation}_${_tokenFactory()}'),
    )..createSync(recursive: true);
  }

  Future<void> _deleteDirectory(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _deleteSidecars(File active) async {
    for (final suffix in const ['-wal', '-shm']) {
      final sidecar = File('${active.path}$suffix');
      if (await sidecar.exists()) await sidecar.delete();
    }
  }
}

class _ValidatedRestore {
  const _ValidatedRestore({
    required this.directory,
    required this.databaseFile,
    required this.manifest,
    required this.sourceDisplayName,
  });

  final Directory directory;
  final File databaseFile;
  final BackupManifest manifest;
  final String sourceDisplayName;
}

final localBackupRepositoryProvider =
    Provider<BackupRepositoryInterface>((ref) {
  return LocalBackupRepository(
    activeDatabase: () => ref.read(databaseProvider),
    closeActiveDatabase: () async {
      await ref.read(databaseProvider).close();
      ref.invalidate(databaseProvider);
    },
    reopenActiveDatabase: () async {
      final database = ref.read(databaseProvider);
      await database.customSelect('SELECT 1').getSingle();
      return database;
    },
    resolveActiveDatabaseFile: resolveDatabaseFile,
    temporaryDirectory: getTemporaryDirectory,
  );
});
