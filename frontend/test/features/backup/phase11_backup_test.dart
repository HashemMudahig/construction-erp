import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/features/backup/data/backup_archive_service.dart';
import 'package:construction_erp/features/backup/data/backup_checksum_service.dart';
import 'package:construction_erp/features/backup/data/local_backup_repository.dart';
import 'package:construction_erp/features/backup/domain/backup_exceptions.dart';
import 'package:construction_erp/features/backup/domain/backup_manifest.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const counts = BackupRecordCounts(
    clients: 1,
    projects: 2,
    milestones: 3,
    payments: 4,
    expenses: 5,
    appSettings: 1,
  );
  final created = DateTime.utc(2026, 7, 26, 11, 30);
  final manifest = BackupManifest(
    backupFormatVersion: kBackupFormatVersion,
    applicationId: kBackupApplicationId,
    createdAtUtc: created,
    databaseEntryName: kBackupDatabaseEntryName,
    databaseSchemaVersion: kSchemaVersion,
    databaseSizeBytes: 42,
    databaseSha256: 'a' * 64,
    recordCounts: counts,
    applicationVersion: '1.0.0+1',
  );

  group('manifest', () {
    test('canonical serialization is deterministic and round-trips', () {
      final first = manifest.toCanonicalJson();
      expect(manifest.toCanonicalJson(), first);
      final parsed = BackupManifest.fromJsonString(first);
      expect(parsed.createdAtUtc, created);
      expect(parsed.recordCounts, counts);
      expect(parsed.databaseSha256, 'a' * 64);
    });

    test('contains no credential fields', () {
      final json = manifest.toCanonicalJson().toLowerCase();
      expect(json, isNot(contains('jwt')));
      expect(json, isNot(contains('password')));
      expect(json, isNot(contains('token')));
    });

    for (final key in [
      'backupFormatVersion',
      'applicationId',
      'createdAtUtc',
      'databaseEntryName',
      'databaseSchemaVersion',
      'databaseSizeBytes',
      'databaseSha256',
      'recordCounts',
    ]) {
      test('missing $key is rejected', () {
        final json = Map<String, Object>.from(manifest.toJson())..remove(key);
        expect(
          () => BackupManifest.fromJson(json),
          throwsA(isA<BackupValidationException>()),
        );
      });
    }

    test('unsupported format, app, and future schema are rejected', () {
      for (final patch in [
        {'backupFormatVersion': 2},
        {'applicationId': 'other'},
        {'databaseSchemaVersion': kSchemaVersion + 1},
      ]) {
        expect(
          () => BackupManifest.fromJson({...manifest.toJson(), ...patch}),
          throwsA(isA<BackupValidationException>()),
        );
      }
    });

    test('invalid timestamp has no current-time fallback', () {
      expect(
        () => BackupManifest.fromJson(
            {...manifest.toJson(), 'createdAtUtc': 'not-a-date'}),
        throwsA(isA<BackupValidationException>()),
      );
      expect(
        () => BackupManifest.fromJson(
            {...manifest.toJson(), 'createdAtUtc': '2026-07-26T11:30:00'}),
        throwsA(isA<BackupValidationException>()),
      );
    });
  });

  group('checksum and archive', () {
    late Directory temp;
    setUp(() => temp = Directory.systemTemp.createTempSync('phase11_archive_'));
    tearDown(() => temp.deleteSync(recursive: true));

    test('SHA-256 streams deterministically and changes with bytes', () async {
      final file = File(p.join(temp.path, 'data'))..writeAsStringSync('one');
      const service = BackupChecksumService();
      final first = await service.sha256File(file);
      expect(await service.sha256File(file), first);
      file.writeAsStringSync('two');
      expect(await service.sha256File(file), isNot(first));
    });

    test('valid archive contains exactly manifest and database', () async {
      final database = File(p.join(temp.path, kBackupDatabaseEntryName))
        ..writeAsBytesSync(List.filled(42, 1));
      final output = File(p.join(temp.path, 'valid.cerpbackup'));
      await const BackupArchiveService().createArchive(
        output: output,
        database: database,
        manifest: manifest,
      );
      final extracted = await const BackupArchiveService()
          .inspectAndExtract(output, Directory(p.join(temp.path, 'out')));
      expect(extracted.manifest.recordCounts, counts);
      expect(await extracted.databaseFile.length(), 42);
    });

    for (final badName in [
      '../construction_erp.db',
      '/construction_erp.db',
      r'C:\construction_erp.db',
      'nested/construction_erp.db',
    ]) {
      test('unsafe archive path $badName is rejected', () async {
        final archive = Archive()
          ..addFile(ArchiveFile.string(
              kBackupManifestEntryName, manifest.toCanonicalJson()))
          ..addFile(ArchiveFile.bytes(badName, [1]));
        final file = File(p.join(temp.path, 'unsafe.cerpbackup'))
          ..writeAsBytesSync(ZipEncoder().encode(archive));
        expect(
          () => const BackupArchiveService()
              .inspectAndExtract(file, Directory(p.join(temp.path, 'unsafe'))),
          throwsA(isA<BackupValidationException>()),
        );
      });
    }

    test('missing and unexpected entries are rejected', () async {
      final variants = [
        Archive()..addFile(ArchiveFile.bytes(kBackupDatabaseEntryName, [1])),
        Archive()
          ..addFile(ArchiveFile.string(
              kBackupManifestEntryName, manifest.toCanonicalJson()))
          ..addFile(ArchiveFile.bytes(kBackupDatabaseEntryName, [1]))
          ..addFile(ArchiveFile.bytes('extra.txt', [1])),
      ];
      for (var index = 0; index < variants.length; index++) {
        final file = File(p.join(temp.path, 'invalid$index.cerpbackup'))
          ..writeAsBytesSync(ZipEncoder().encode(variants[index]));
        expect(
          () => const BackupArchiveService().inspectAndExtract(
              file, Directory(p.join(temp.path, 'out$index'))),
          throwsA(isA<BackupValidationException>()),
        );
      }
    });

    test('corrupt archive is rejected and extraction stays empty', () async {
      final file = File(p.join(temp.path, 'corrupt.cerpbackup'))
        ..writeAsStringSync('not zip');
      final output = Directory(p.join(temp.path, 'corrupt_out'));
      expect(
        () => const BackupArchiveService().inspectAndExtract(file, output),
        throwsA(isA<BackupValidationException>()),
      );
      expect(output.existsSync(), isFalse);
    });
  });

  group('file-backed backup and restore', () {
    late Directory temp;
    late File activeFile;
    late AppDatabase activeDatabase;
    late LocalBackupRepository repository;
    var reopenCalls = 0;
    var failNextReopen = false;

    setUp(() async {
      reopenCalls = 0;
      failNextReopen = false;
      temp = Directory.systemTemp.createTempSync('phase11_repository_');
      activeFile = File(p.join(temp.path, kDatabaseFileName));
      activeDatabase =
          AppDatabase(NativeDatabase.createInBackground(activeFile));
      await _seedAll(activeDatabase);
      repository = LocalBackupRepository(
        activeDatabase: () => activeDatabase,
        closeActiveDatabase: () => activeDatabase.close(),
        reopenActiveDatabase: () async {
          reopenCalls++;
          if (failNextReopen) {
            failNextReopen = false;
            throw StateError('simulated reopen failure');
          }
          activeDatabase =
              AppDatabase(NativeDatabase.createInBackground(activeFile));
          await activeDatabase.customSelect('SELECT 1').getSingle();
          return activeDatabase;
        },
        resolveActiveDatabaseFile: () async => activeFile,
        temporaryDirectory: () async => temp,
        utcClock: () => created,
        tokenFactory: _tokens(),
      );
    });

    tearDown(() async {
      try {
        await activeDatabase.close();
      } catch (_) {}
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    test('backup snapshot preserves every local table and no sidecars',
        () async {
      final destination = p.join(temp.path, 'all-data.cerpbackup');
      final result = await repository.createBackup(destination);
      expect(
          result.manifest.recordCounts,
          const BackupRecordCounts(
            clients: 1,
            projects: 1,
            milestones: 1,
            payments: 2,
            expenses: 2,
            appSettings: 1,
          ));
      expect(File(destination).existsSync(), isTrue);
      final names = ZipDecoder()
          .decodeBytes(File(destination).readAsBytesSync())
          .map((entry) => entry.name);
      expect(names,
          containsAll([kBackupManifestEntryName, kBackupDatabaseEntryName]));
      expect(names.any((name) => name.endsWith('-wal')), isFalse);
      expect(names.any((name) => name.endsWith('-shm')), isFalse);
      expect((await activeDatabase.clientsDao.getAllClients()).length, 1);
    });

    test('inspection validates without mutating current data', () async {
      final destination = p.join(temp.path, 'preview.cerpbackup');
      await repository.createBackup(destination);
      await activeDatabase.clientsDao.insertClient(ClientsCompanion.insert(
        id: '22222222-2222-4222-8222-222222222222',
        name: 'Current only',
        createdAt: DateTime.utc(2026).toIso8601String(),
        updatedAt: DateTime.utc(2026).toIso8601String(),
      ));
      final preview = await repository.inspectBackup(destination);
      expect(preview.manifest.recordCounts.clients, 1);
      expect((await activeDatabase.clientsDao.getAllClients()).length, 2);
      await repository.cancelPendingRestore();
      expect((await activeDatabase.clientsDao.getAllClients()).length, 2);
    });

    test('supported v3 backup migrates only its staging copy', () async {
      final legacyFile = File(p.join(temp.path, 'legacy.db'));
      final legacy = AppDatabase(NativeDatabase(legacyFile));
      await _seedAll(legacy);
      await legacy
          .customStatement('ALTER TABLE app_settings DROP COLUMN locale_code');
      await legacy.customStatement('PRAGMA user_version = 3');
      await legacy.close();
      final legacyManifest = BackupManifest(
        backupFormatVersion: kBackupFormatVersion,
        applicationId: kBackupApplicationId,
        createdAtUtc: created,
        databaseEntryName: kBackupDatabaseEntryName,
        databaseSchemaVersion: 3,
        databaseSizeBytes: await legacyFile.length(),
        databaseSha256:
            await const BackupChecksumService().sha256File(legacyFile),
        recordCounts: const BackupRecordCounts(
          clients: 1,
          projects: 1,
          milestones: 1,
          payments: 2,
          expenses: 2,
          appSettings: 1,
        ),
      );
      final archive = File(p.join(temp.path, 'legacy.cerpbackup'));
      await const BackupArchiveService().createArchive(
        output: archive,
        database: legacyFile,
        manifest: legacyManifest,
      );
      final preview = await repository.inspectBackup(archive.path);
      expect(preview.isMigrationRequired, isTrue);
      expect(preview.manifest.databaseSchemaVersion, 3);
      expect((await activeDatabase.clientsDao.getAllClients()).length, 1);
      await repository.cancelPendingRestore();
    });

    test('restore replaces rather than merges and survives reopen', () async {
      final destination = p.join(temp.path, 'replace.cerpbackup');
      await repository.createBackup(destination);
      await activeDatabase.clientsDao.insertClient(ClientsCompanion.insert(
        id: '22222222-2222-4222-8222-222222222222',
        name: 'Removed by restore',
        createdAt: DateTime.utc(2026).toIso8601String(),
        updatedAt: DateTime.utc(2026).toIso8601String(),
      ));
      final preview = await repository.inspectBackup(destination);
      await repository.restoreBackup(preview);
      expect(reopenCalls, 1);
      expect((await activeDatabase.clientsDao.getAllClients()).length, 1);
      expect(
          (await activeDatabase.paymentsDao.getAllPaymentsByProject(
                  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'))
              .length,
          2);
      expect(
          (await activeDatabase.expensesDao.getAllExpensesByProject(
                  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'))
              .length,
          2);
      await activeDatabase.close();
      activeDatabase =
          AppDatabase(NativeDatabase.createInBackground(activeFile));
      expect((await activeDatabase.clientsDao.getAllClients()).length, 1);
      expect(File('${activeFile.path}.pre_restore').existsSync(), isFalse);
    });

    test('checksum mismatch rejects restore and leaves current data', () async {
      final destination = p.join(temp.path, 'tamper.cerpbackup');
      await repository.createBackup(destination);
      final archive =
          ZipDecoder().decodeBytes(File(destination).readAsBytesSync());
      final database =
          archive.firstWhere((entry) => entry.name == kBackupDatabaseEntryName);
      final bytes = database.content;
      bytes[0] = bytes[0] ^ 0xff;
      File(destination).writeAsBytesSync(ZipEncoder().encode(archive));
      expect(
        () => repository.inspectBackup(destination),
        throwsA(isA<BackupValidationException>()),
      );
      expect((await activeDatabase.clientsDao.getAllClients()).length, 1);
    });

    test('reopen failure rolls back and retains original current data',
        () async {
      final destination = p.join(temp.path, 'rollback.cerpbackup');
      await repository.createBackup(destination);
      await activeDatabase.clientsDao.insertClient(ClientsCompanion.insert(
        id: '22222222-2222-4222-8222-222222222222',
        name: 'Must survive failed restore',
        createdAt: DateTime.utc(2026).toIso8601String(),
        updatedAt: DateTime.utc(2026).toIso8601String(),
      ));
      final preview = await repository.inspectBackup(destination);
      failNextReopen = true;
      await expectLater(
        repository.restoreBackup(preview),
        throwsA(isA<BackupException>()),
      );
      expect(reopenCalls, 2);
      expect((await activeDatabase.clientsDao.getAllClients()).length, 2);
      expect(File('${activeFile.path}.pre_restore').existsSync(), isFalse);
      expect(File('${activeFile.path}.incoming').existsSync(), isFalse);
    });

    test('concurrent operation is rejected', () async {
      final first = repository.createBackup(p.join(temp.path, 'first'));
      expect(
        () => repository.createBackup(p.join(temp.path, 'second')),
        throwsA(isA<BackupBusyException>()),
      );
      await first;
    });
  });
}

String Function() _tokens() {
  var value = 0;
  return () => 'token_${value++}';
}

Future<void> _seedAll(AppDatabase db) async {
  final now = DateTime.utc(2026, 7, 26);
  final timestamp = now.toIso8601String();
  const date = '2026-07-26';
  const clientId = '11111111-1111-4111-8111-111111111111';
  const projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  await db.clientsDao.insertClient(ClientsCompanion.insert(
    id: clientId,
    name: 'Client',
    createdAt: timestamp,
    updatedAt: timestamp,
  ));
  await db.projectsDao.insertProject(ProjectsCompanion.insert(
    id: projectId,
    clientId: clientId,
    name: 'Project',
    budgetAmountMinor: 100000,
    budgetCurrency: kCurrencyYer,
    createdAt: timestamp,
  ));
  await db.milestonesDao.insertMilestone(MilestonesCompanion.insert(
    id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    projectId: projectId,
    title: 'Milestone',
    dueDate: date,
    createdAt: timestamp,
  ));
  for (final deleted in [false, true]) {
    await db.paymentsDao.insertPayment(PaymentsCompanion.insert(
      id: deleted
          ? 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2'
          : 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
      projectId: projectId,
      originalAmountMinor: 100,
      originalCurrency: kCurrencyYer,
      exchangeRateScaled: kIdentityExchangeRate,
      convertedYerAmount: 100,
      paymentDate: date,
      method: 'cash',
      isDeleted: Value(deleted),
      deletedAt: Value(deleted ? timestamp : null),
      createdAt: timestamp,
    ));
    await db.expensesDao.insertExpense(ExpensesCompanion.insert(
      id: deleted
          ? 'dddddddd-dddd-4ddd-8ddd-ddddddddddd2'
          : 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1',
      projectId: projectId,
      category: 'materials',
      originalAmountMinor: 50,
      originalCurrency: kCurrencyYer,
      exchangeRateScaled: kIdentityExchangeRate,
      convertedYerAmount: 50,
      expenseDate: date,
      isDeleted: Value(deleted),
      deletedAt: Value(deleted ? timestamp : null),
      createdAt: timestamp,
    ));
  }
  await db.appSettingsDao.insertSettings(AppSettingsCompanion.insert(
    id: 'app',
    defaultExchangeRateScaled: const Value(kDefaultSarToYerRateScaled),
    localeCode: const Value(kDefaultLocaleCode),
    createdAt: timestamp,
    updatedAt: timestamp,
  ));
}
