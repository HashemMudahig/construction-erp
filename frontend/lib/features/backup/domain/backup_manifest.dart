import 'dart:convert';

import '../../../core/database/database_constants.dart';
import 'backup_exceptions.dart';

const kBackupFormatVersion = 1;
const kBackupApplicationId = 'construction_erp';
const kBackupDatabaseEntryName = 'construction_erp.db';
const kBackupManifestEntryName = 'manifest.json';

class BackupRecordCounts {
  const BackupRecordCounts({
    required this.clients,
    required this.projects,
    required this.milestones,
    required this.payments,
    required this.expenses,
    required this.appSettings,
  });

  final int clients;
  final int projects;
  final int milestones;
  final int payments;
  final int expenses;
  final int appSettings;

  Map<String, Object> toJson() => {
        'clients': clients,
        'projects': projects,
        'milestones': milestones,
        'payments': payments,
        'expenses': expenses,
        'appSettings': appSettings,
      };

  factory BackupRecordCounts.fromJson(Object? value) {
    final json = _object(value, 'recordCounts');
    return BackupRecordCounts(
      clients: _nonNegativeInt(json, 'clients'),
      projects: _nonNegativeInt(json, 'projects'),
      milestones: _nonNegativeInt(json, 'milestones'),
      payments: _nonNegativeInt(json, 'payments'),
      expenses: _nonNegativeInt(json, 'expenses'),
      appSettings: _nonNegativeInt(json, 'appSettings'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BackupRecordCounts &&
      clients == other.clients &&
      projects == other.projects &&
      milestones == other.milestones &&
      payments == other.payments &&
      expenses == other.expenses &&
      appSettings == other.appSettings;

  @override
  int get hashCode => Object.hash(
      clients, projects, milestones, payments, expenses, appSettings);
}

class BackupManifest {
  const BackupManifest({
    required this.backupFormatVersion,
    required this.applicationId,
    required this.createdAtUtc,
    required this.databaseEntryName,
    required this.databaseSchemaVersion,
    required this.databaseSizeBytes,
    required this.databaseSha256,
    required this.recordCounts,
    this.applicationVersion,
  });

  final int backupFormatVersion;
  final String applicationId;
  final DateTime createdAtUtc;
  final String databaseEntryName;
  final int databaseSchemaVersion;
  final int databaseSizeBytes;
  final String databaseSha256;
  final BackupRecordCounts recordCounts;
  final String? applicationVersion;

  Map<String, Object> toJson() => {
        'backupFormatVersion': backupFormatVersion,
        'applicationId': applicationId,
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
        'databaseEntryName': databaseEntryName,
        'databaseSchemaVersion': databaseSchemaVersion,
        'databaseSizeBytes': databaseSizeBytes,
        'databaseSha256': databaseSha256,
        if (applicationVersion != null)
          'applicationVersion': applicationVersion!,
        'recordCounts': recordCounts.toJson(),
      };

  String toCanonicalJson() => jsonEncode(toJson());

  factory BackupManifest.fromJsonString(String source) {
    try {
      return BackupManifest.fromJson(jsonDecode(source));
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupValidationException('The backup manifest is invalid.');
    }
  }

  factory BackupManifest.fromJson(Object? value) {
    final json = _object(value, 'manifest');
    final format = _positiveInt(json, 'backupFormatVersion');
    if (format != kBackupFormatVersion) {
      throw const BackupValidationException(
          'The backup format version is not supported.');
    }
    final applicationId = _string(json, 'applicationId');
    if (applicationId != kBackupApplicationId) {
      throw const BackupValidationException(
          'This backup belongs to a different application.');
    }
    final entry = _string(json, 'databaseEntryName');
    if (entry != kBackupDatabaseEntryName) {
      throw const BackupValidationException(
          'The backup database entry is invalid.');
    }
    final schema = _positiveInt(json, 'databaseSchemaVersion');
    if (schema > kSchemaVersion) {
      throw const BackupValidationException(
          'The backup requires a newer application version.');
    }
    if (schema < 1) {
      throw const BackupValidationException(
          'The backup database schema is not supported.');
    }
    final timestampText = _string(json, 'createdAtUtc');
    final timestamp = DateTime.tryParse(timestampText);
    if (timestamp == null ||
        !timestamp.isUtc ||
        !timestampText.toUpperCase().endsWith('Z')) {
      throw const BackupValidationException(
          'The backup creation timestamp is invalid.');
    }
    final checksum = _string(json, 'databaseSha256').toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum)) {
      throw const BackupValidationException('The backup checksum is invalid.');
    }
    return BackupManifest(
      backupFormatVersion: format,
      applicationId: applicationId,
      createdAtUtc: timestamp,
      databaseEntryName: entry,
      databaseSchemaVersion: schema,
      databaseSizeBytes: _positiveInt(json, 'databaseSizeBytes'),
      databaseSha256: checksum,
      recordCounts: BackupRecordCounts.fromJson(json['recordCounts']),
      applicationVersion: json['applicationVersion'] == null
          ? null
          : _string(json, 'applicationVersion'),
    );
  }
}

Map<String, Object?> _object(Object? value, String name) {
  if (value is! Map) {
    throw BackupValidationException('$name must be a JSON object.');
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw BackupValidationException('Missing or invalid manifest field: $key.');
  }
  return value;
}

int _positiveInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int || value <= 0) {
    throw BackupValidationException('Missing or invalid manifest field: $key.');
  }
  return value;
}

int _nonNegativeInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int || value < 0) {
    throw BackupValidationException('Missing or invalid record count: $key.');
  }
  return value;
}
