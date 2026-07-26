import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'client_providers.dart';
import '../../../core/localization/app_localizations.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientDetailProvider(id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('client_details')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: Localizations.localeOf(context).languageCode == 'ar'
                ? 'تعديل'
                : 'Edit',
            onPressed: () => context.go('/clients/$id/edit'),
          ),
        ],
      ),
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(clientDetailProvider(id))),
        data: (c) {
          final isAr = Localizations.localeOf(context).languageCode == 'ar';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.name,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          Chip(
                            label: Text(c.archived
                                ? (isAr ? 'مؤرشف' : 'Archived')
                                : (isAr ? 'نشط' : 'Active')),
                            backgroundColor: c.archived
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.primaryContainer,
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                          label: context.tr('phone'), value: c.phone ?? '—'),
                      _InfoRow(
                          label: context.tr('email'), value: c.email ?? '—'),
                      _InfoRow(
                          label: isAr ? 'العنوان' : 'Address',
                          value: c.address ?? '—'),
                      _InfoRow(
                          label: isAr ? 'ملاحظات' : 'Notes',
                          value: c.notes ?? '—'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'المشاريع المرتبطة' : 'Linked projects',
                      style: theme.textTheme.titleMedium),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.tr('add_project')),
                    onPressed: () => context.go('/projects/new?client_id=$id'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 90,
                child:
                    Text(label, style: Theme.of(context).textTheme.bodySmall)),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: onRetry,
                child: Text(Localizations.localeOf(context).languageCode == 'ar'
                    ? 'إعادة المحاولة'
                    : 'Retry')),
          ],
        ),
      );
}
