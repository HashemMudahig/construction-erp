import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'project_providers.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  String? _statusFilter;

  static const _statuses = ['planning', 'active', 'completed', 'on_hold', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add project',
            onPressed: () => context.go('/projects/new'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    value: _statusFilter,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All statuses')),
                      ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      ref.read(projectsListProvider.notifier).setFilters(status: v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString(), onRetry: () => ref.invalidate(projectsListProvider)),
        data: (projects) {
          if (projects.isEmpty) {
            return _EmptyView(
              message: 'No projects yet. Add your first project.',
              cta: 'Add project',
              onCta: () => context.go('/projects/new'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(projectsListProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: projects.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = projects[i];
                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${p.budget.toStringAsFixed(2)}  •  ${p.status}'),
                  trailing: _StatusChip(status: p.status, theme: theme),
                  onTap: () => context.go('/projects/${p.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.theme});
  final String status;
  final ThemeData theme;

  Color _color() {
    switch (status) {
      case 'active':
        return Colors.green.shade100;
      case 'completed':
        return Colors.blue.shade100;
      case 'on_hold':
        return Colors.orange.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) => Chip(label: Text(status), backgroundColor: _color());
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
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message, required this.cta, required this.onCta});
  final String message;
  final String cta;
  final VoidCallback onCta;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_outlined, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onCta, child: Text(cta)),
          ],
        ),
      );
}