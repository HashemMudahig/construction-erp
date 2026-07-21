import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'project_providers.dart';
import '../../../core/localization/app_localizations.dart';

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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.folder, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(context.tr('projects')),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, size: 22),
              tooltip: context.tr('add_project'),
              color: Colors.white,
              onPressed: () => context.go('/projects/new'),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: Localizations.localeOf(context).languageCode == 'ar' ? 'تصفية حسب الحالة' : 'Filter by Status',
                      isDense: true,
                      prefixIcon: const Icon(Icons.filter_list, size: 22),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    value: _statusFilter,
                    items: [
                      DropdownMenuItem(value: null, child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'جميع الحالات' : 'All statuses')),
                      ..._statuses.map((s) {
                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                        String label = s.replaceAll('_', ' ');
                        if (s == 'active') label = isAr ? 'نشط' : 'Active';
                        if (s == 'completed') label = isAr ? 'مكتمل' : 'Completed';
                        if (s == 'on_hold') label = isAr ? 'معلق' : 'On Hold';
                        if (s == 'cancelled') label = isAr ? 'ملغى' : 'Cancelled';
                        return DropdownMenuItem(value: s, child: Text(label));
                      }),
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
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            return _EmptyView(
              message: isAr ? 'لا يوجد مشاريع بعد. أضف مشروعك الأول.' : 'No projects yet. Add your first project.',
              cta: context.tr('add_project'),
              onCta: () => context.go('/projects/new'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(projectsListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = projects[i];
                return _ProjectCard(project: p, theme: theme, onTap: () => context.go('/projects/${p.id}'));
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final dynamic project;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.theme, required this.onTap});

  (Color bg, Color fg) _statusColors() {
    switch (project.status) {
      case 'active':
        return (const Color(0xFFDCFCE7), const Color(0xFF166534));
      case 'completed':
        return (const Color(0xFFDBEAFE), const Color(0xFF1E40AF));
      case 'on_hold':
        return (const Color(0xFFFED7AA), const Color(0xFF9A3412));
      case 'cancelled':
        return (const Color(0xFFFEE2E2), const Color(0xFF991B1B));
      default:
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors();
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder, color: Colors.deepOrange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${project.budget.toStringAsFixed(2)} ${context.tr('currency')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatStatus(context, project.status).toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStatus(BuildContext context, String s) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (s == 'active') return isAr ? 'نشط' : 'Active';
    if (s == 'completed') return isAr ? 'مكتمل' : 'Completed';
    if (s == 'on_hold') return isAr ? 'معلق' : 'On Hold';
    if (s == 'cancelled') return isAr ? 'ملغى' : 'Cancelled';
    return s.replaceAll('_', ' ');
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'إعادة المحاولة' : 'Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message, required this.cta, required this.onCta});
  final String message;
  final String cta;
  final VoidCallback onCta;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.folder_outlined, size: 48, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onCta,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(cta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}