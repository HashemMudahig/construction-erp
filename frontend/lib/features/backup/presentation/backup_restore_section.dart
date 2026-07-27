import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          title: isArabic ? 'النسخ الاحتياطي' : 'Backup',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isArabic
                  ? 'أنشئ نسخة كاملة من بيانات العمل والإعدادات واحفظها في مكان محمي.'
                  : 'Create a complete copy of local business data and settings, then store it in a protected location.'),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'ملفات النسخ الاحتياطي غير مشفرة ولا تتضمن كلمات مرور أو رموز دخول.'
                    : 'Backup files are not encrypted and contain no credentials.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state.isBusy ? null : notifier.createBackup,
                icon: const Icon(Icons.save_alt),
                label: Text(isArabic ? 'إنشاء نسخة احتياطية' : 'Create backup'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _BackupCard(
          icon: Icons.restore,
          title: isArabic ? 'الاسترجاع' : 'Restore',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isArabic
                  ? 'يستبدل الاسترجاع جميع البيانات المحلية الحالية؛ لا يدمج السجلات.'
                  : 'Restore replaces all current local data; it does not merge records.'),
              const SizedBox(height: 8),
              Text(isArabic
                  ? 'فشل التحقق لا يغير بياناتك الحالية.'
                  : 'Failed validation does not modify current data.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : notifier.selectRestore,
                icon: const Icon(Icons.folder_open),
                label: Text(isArabic ? 'اختيار نسخة' : 'Select backup'),
              ),
            ],
          ),
        ),
        if (state.isBusy) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            _progressLabel(state.operation, isArabic),
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
            _localizedMessage(state.message!, isArabic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: notifier.clearResult,
            child: Text(isArabic ? 'إغلاق' : 'Dismiss'),
          ),
        ],
      ],
    );
  }

  String _progressLabel(BackupMaintenanceState operation, bool isArabic) {
    return switch (operation) {
      BackupMaintenanceState.creatingBackup =>
        isArabic ? 'جارٍ إنشاء النسخة…' : 'Creating backup…',
      BackupMaintenanceState.validatingRestore =>
        isArabic ? 'جارٍ التحقق من النسخة…' : 'Validating backup…',
      BackupMaintenanceState.restoring =>
        isArabic ? 'جارٍ استبدال البيانات بأمان…' : 'Restoring safely…',
      _ => '',
    };
  }

  String _localizedMessage(String message, bool isArabic) {
    if (!isArabic) return message;
    if (message == 'Backup created successfully.') {
      return 'تم إنشاء النسخة الاحتياطية بنجاح.';
    }
    if (message == 'Restore completed successfully.') {
      return 'تم الاسترجاع بنجاح.';
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
      (isArabic ? 'العملاء' : 'Clients', counts.clients),
      (isArabic ? 'المشاريع' : 'Projects', counts.projects),
      (isArabic ? 'المراحل' : 'Milestones', counts.milestones),
      (isArabic ? 'الدفعات' : 'Payments', counts.payments),
      (isArabic ? 'المصروفات' : 'Expenses', counts.expenses),
      (isArabic ? 'الإعدادات' : 'Settings', counts.appSettings),
    ];
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isArabic ? 'معاينة النسخة' : 'Backup preview',
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
              isArabic
                  ? 'تحذير: سيؤدي التأكيد إلى استبدال جميع البيانات المحلية الحالية.'
                  : 'Warning: confirmation will replace all current local data.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: onConfirm,
                  child: Text(
                      isArabic ? 'استبدال البيانات' : 'Replace local data'),
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
