import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:intl/intl.dart';

import '../domain/backup_manifest.dart';
import 'backup_restore_provider.dart';

class BackupRestoreSection extends ConsumerWidget {
  const BackupRestoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final state = ref.watch(backupRestoreProvider);
    final notifier = ref.read(backupRestoreProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackupCard(
          icon: Icons.backup_outlined,
          title: context.tr('backup'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('backup_desc')),
              const SizedBox(height: 8),
              Text(
                context.tr('backup_warning'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state.isBusy ? null : notifier.createBackup,
                icon: const Icon(Icons.save_alt),
                label: Text(context.tr('create_backup')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _BackupCard(
          icon: Icons.restore,
          title: context.tr('restore'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('restore_desc1')),
              const SizedBox(height: 8),
              Text(context.tr('restore_desc2')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : notifier.selectRestore,
                icon: const Icon(Icons.folder_open),
                label: Text(context.tr('select_backup')),
              ),
            ],
          ),
        ),
        if (state.isBusy) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            _progressLabel(context, state.operation),
            textAlign: TextAlign.center,
          ),
        ],
        if (state.preview != null &&
            state.operation == BackupMaintenanceState.awaitingConfirmation) ...[
          const SizedBox(height: 16),
          _RestorePreview(
            manifest: state.preview!.manifest,
            isArabic: isArabic,
            onCancel: notifier.cancelPreview,
            onConfirm: notifier.confirmRestore,
          ),
        ],
        if (state.message != null) ...[
          const SizedBox(height: 16),
          SelectableText(
            _localizedMessage(context, state.message!),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: notifier.clearResult,
            child: Text(context.tr('dismiss')),
          ),
        ],
      ],
    );
  }

  String _progressLabel(BuildContext context, BackupMaintenanceState operation) {
    return switch (operation) {
      BackupMaintenanceState.creatingBackup =>
        context.tr('creating_backup'),
      BackupMaintenanceState.validatingRestore =>
        context.tr('validating_backup'),
      BackupMaintenanceState.restoring =>
        context.tr('restoring_safely'),
      _ => '',
    };
  }

  String _localizedMessage(BuildContext context, String message) {

    if (message == 'Backup created successfully.') {
      return context.tr('backup_created_successfully');
    }
    if (message == 'Restore completed successfully.') {
      return context.tr('restore_completed_successfully');
    }
    return message;
  }
}

class _RestorePreview extends StatelessWidget {
  const _RestorePreview({
    required this.manifest,
    required this.isArabic,
    required this.onCancel,
    required this.onConfirm,
  });

  final BackupManifest manifest;
  final bool isArabic;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final counts = manifest.recordCounts;
    final rows = <(String, int)>[
      (context.tr('clients'), counts.clients),
      (context.tr('projects'), counts.projects),
      (context.tr('milestones'), counts.milestones),
      (context.tr('payments'), counts.payments),
      (context.tr('expenses'), counts.expenses),
      (context.tr('app_settings'), counts.appSettings),
    ];
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('backup_preview'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(DateFormat.yMMMd().add_Hm().format(manifest.createdAtUtc)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final row in rows)
                  Chip(label: Text('${row.$1}: ${row.$2}')),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('restore_warning'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(context.tr('cancel')),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: onConfirm,
                  child: Text(
                      context.tr('replace_local_data')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
