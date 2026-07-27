import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_backup_repository.dart';
import '../domain/backup_models.dart';
import '../domain/backup_repository_interface.dart';

enum BackupMaintenanceState {
  idle,
  creatingBackup,
  validatingRestore,
  awaitingConfirmation,
  restoring,
  completed,
  failed,
}

class BackupRestoreState {
  const BackupRestoreState({
    this.operation = BackupMaintenanceState.idle,
    this.preview,
    this.message,
    this.result,
  });

  final BackupMaintenanceState operation;
  final BackupPreview? preview;
  final String? message;
  final BackupOperationResult? result;

  bool get isBusy =>
      operation == BackupMaintenanceState.creatingBackup ||
      operation == BackupMaintenanceState.validatingRestore ||
      operation == BackupMaintenanceState.restoring;
}

abstract interface class BackupFileSelectionService {
  Future<String?> selectBackupDestination(String suggestedName);
  Future<String?> selectBackupSource();
}

class SystemBackupFileSelectionService implements BackupFileSelectionService {
  const SystemBackupFileSelectionService();

  static const _type = XTypeGroup(
    label: 'Construction ERP backup',
    extensions: ['cerpbackup'],
    mimeTypes: ['application/zip'],
  );

  @override
  Future<String?> selectBackupDestination(String suggestedName) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [_type],
    );
    return location?.path;
  }

  @override
  Future<String?> selectBackupSource() async {
    final file = await openFile(acceptedTypeGroups: const [_type]);
    return file?.path;
  }
}

final backupRepositoryProvider = Provider<BackupRepositoryInterface>(
  (ref) => ref.watch(localBackupRepositoryProvider),
);

final backupFileSelectionProvider = Provider<BackupFileSelectionService>(
  (_) => const SystemBackupFileSelectionService(),
);

final backupRestoreProvider =
    NotifierProvider<BackupRestoreNotifier, BackupRestoreState>(
  BackupRestoreNotifier.new,
);

class BackupRestoreNotifier extends Notifier<BackupRestoreState> {
  @override
  BackupRestoreState build() {
    final repository = ref.read(backupRepositoryProvider);
    ref.onDispose(repository.cleanTemporaryFiles);
    return const BackupRestoreState();
  }

  Future<void> createBackup() async {
    if (state.isBusy) return;
    final now = DateTime.now().toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    final suggested = 'construction_erp_${now.year}-${two(now.month)}-'
        '${two(now.day)}_${two(now.hour)}${two(now.minute)}'
        '${two(now.second)}.cerpbackup';
    final destination = await ref
        .read(backupFileSelectionProvider)
        .selectBackupDestination(suggested);
    if (destination == null) {
      state = const BackupRestoreState();
      return;
    }
    state = const BackupRestoreState(
        operation: BackupMaintenanceState.creatingBackup);
    try {
      final result =
          await ref.read(backupRepositoryProvider).createBackup(destination);
      state = BackupRestoreState(
        operation: BackupMaintenanceState.completed,
        result: result,
        message: 'Backup created successfully.',
      );
    } catch (error) {
      state = BackupRestoreState(
        operation: BackupMaintenanceState.failed,
        message: error.toString(),
      );
    }
  }

  Future<void> selectRestore() async {
    if (state.isBusy) return;
    final source =
        await ref.read(backupFileSelectionProvider).selectBackupSource();
    if (source == null) {
      state = const BackupRestoreState();
      return;
    }
    state = const BackupRestoreState(
        operation: BackupMaintenanceState.validatingRestore);
    try {
      final preview =
          await ref.read(backupRepositoryProvider).inspectBackup(source);
      state = BackupRestoreState(
        operation: BackupMaintenanceState.awaitingConfirmation,
        preview: preview,
      );
    } catch (error) {
      state = BackupRestoreState(
        operation: BackupMaintenanceState.failed,
        message: error.toString(),
      );
    }
  }

  Future<void> confirmRestore() async {
    final preview = state.preview;
    if (preview == null ||
        state.operation != BackupMaintenanceState.awaitingConfirmation) {
      return;
    }
    state = BackupRestoreState(
      operation: BackupMaintenanceState.restoring,
      preview: preview,
    );
    try {
      final result =
          await ref.read(backupRepositoryProvider).restoreBackup(preview);
      state = BackupRestoreState(
        operation: BackupMaintenanceState.completed,
        result: result,
        message: 'Restore completed successfully.',
      );
    } catch (error) {
      state = BackupRestoreState(
        operation: BackupMaintenanceState.failed,
        message: error.toString(),
      );
    }
  }

  Future<void> cancelPreview() async {
    await ref.read(backupRepositoryProvider).cancelPendingRestore();
    state = const BackupRestoreState();
  }

  void clearResult() => state = const BackupRestoreState();
}
