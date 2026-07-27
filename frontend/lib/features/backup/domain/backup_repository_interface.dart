import 'backup_models.dart';

abstract interface class BackupRepositoryInterface {
  Future<BackupOperationResult> createBackup(String destinationPath);

  Future<BackupPreview> inspectBackup(String sourcePath);

  Future<BackupOperationResult> restoreBackup(BackupPreview preview);

  Future<void> cancelPendingRestore();

  Future<void> cleanTemporaryFiles();
}
