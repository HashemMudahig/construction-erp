import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../domain/backup_exceptions.dart';
import '../domain/backup_manifest.dart';

const kMaximumBackupArchiveBytes = 256 * 1024 * 1024;
const kMaximumExtractedDatabaseBytes = 512 * 1024 * 1024;

class ExtractedBackup {
  const ExtractedBackup({
    required this.manifest,
    required this.databaseFile,
  });

  final BackupManifest manifest;
  final File databaseFile;
}

class BackupArchiveService {
  const BackupArchiveService();

  Future<void> createArchive({
    required File output,
    required File database,
    required BackupManifest manifest,
  }) async {
    final manifestFile =
        File(p.join(database.parent.path, kBackupManifestEntryName));
    await manifestFile.writeAsString(
      manifest.toCanonicalJson(),
      encoding: utf8,
      flush: true,
    );
    final encoder = ZipFileEncoder();
    try {
      encoder.create(output.path);
      await encoder.addFile(manifestFile, kBackupManifestEntryName);
      await encoder.addFile(database, kBackupDatabaseEntryName);
      await encoder.close();
    } catch (_) {
      if (await output.exists()) await output.delete();
      throw const BackupException('The backup archive could not be created.');
    } finally {
      if (await manifestFile.exists()) await manifestFile.delete();
    }
  }

  Future<ExtractedBackup> inspectAndExtract(
    File archiveFile,
    Directory destination,
  ) async {
    if (!await archiveFile.exists() ||
        await archiveFile.length() == 0 ||
        await archiveFile.length() > kMaximumBackupArchiveBytes) {
      throw const BackupValidationException(
          'The selected backup file has an invalid size.');
    }
    Archive archive;
    try {
      archive = ZipDecoder()
          .decodeBytes(await archiveFile.readAsBytes(), verify: true);
    } catch (_) {
      throw const BackupValidationException(
          'The selected backup archive is corrupt.');
    }
    final files = archive.where((entry) => entry.isFile).toList();
    for (final entry in files) {
      if (!_isSafeEntryName(entry.name)) {
        throw const BackupValidationException(
            'The backup contains an unsafe archive path.');
      }
    }
    final manifests =
        files.where((entry) => entry.name == kBackupManifestEntryName).toList();
    final databases =
        files.where((entry) => entry.name == kBackupDatabaseEntryName).toList();
    if (manifests.length != 1 || databases.length != 1 || files.length != 2) {
      throw const BackupValidationException(
          'The backup must contain exactly one manifest and one database.');
    }
    final databaseEntry = databases.single;
    if (databaseEntry.size <= 0 ||
        databaseEntry.size > kMaximumExtractedDatabaseBytes) {
      throw const BackupValidationException(
          'The extracted database size is not allowed.');
    }
    BackupManifest manifest;
    try {
      manifest =
          BackupManifest.fromJsonString(utf8.decode(manifests.single.content));
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupValidationException(
          'The backup manifest encoding is invalid.');
    }
    await destination.create(recursive: true);
    final databaseFile =
        File(p.join(destination.path, kBackupDatabaseEntryName));
    await databaseFile.writeAsBytes(databaseEntry.content, flush: true);
    return ExtractedBackup(manifest: manifest, databaseFile: databaseFile);
  }

  bool _isSafeEntryName(String name) {
    if (name.isEmpty ||
        p.isAbsolute(name) ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(name) ||
        name.contains('\\') ||
        name.split('/').contains('..')) {
      return false;
    }
    return name == p.basename(name);
  }
}
