import 'backup_manifest.dart';

class BackupPreview {
  const BackupPreview({
    required this.validationToken,
    required this.displayName,
    required this.manifest,
    required this.isMigrationRequired,
  });

  final String validationToken;
  final String displayName;
  final BackupManifest manifest;
  final bool isMigrationRequired;
}

class BackupOperationResult {
  const BackupOperationResult({
    required this.displayPath,
    required this.manifest,
  });

  final String displayPath;
  final BackupManifest manifest;
}
