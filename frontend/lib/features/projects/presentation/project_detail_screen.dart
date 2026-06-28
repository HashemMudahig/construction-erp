import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/dio_provider.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/domain/expense_entity.dart';
import '../../expenses/presentation/expense_form_dialog.dart';
import '../../expenses/presentation/expense_providers.dart';
import '../../milestones/data/milestone_repository.dart';
import '../../milestones/domain/milestone_entity.dart';
import '../../milestones/presentation/milestone_form_dialog.dart';
import '../../milestones/presentation/milestone_providers.dart';
import '../../payments/data/payment_repository.dart';
import '../../payments/domain/payment_entity.dart';
import '../../payments/presentation/payment_form_dialog.dart';
import '../../payments/presentation/payment_providers.dart';
import 'project_providers.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectDetailProvider(id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.go('/projects/$id/edit'),
          ),
        ],
      ),
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString(), onRetry: () => ref.invalidate(projectDetailProvider(id))),
        data: (p) => _ProjectDetailBody(projectId: id, project: p, theme: theme, ref: ref),
      ),
    );
  }
}

class _ProjectDetailBody extends ConsumerWidget {
  const _ProjectDetailBody({required this.projectId, required this.project, required this.theme, required this.ref});
  final String projectId;
  final dynamic project;
  final ThemeData theme;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // Header card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(project.name,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Chip(label: Text(project.status)),
                    ],
                  ),
                  const Divider(height: 20),
                  _InfoRow(label: 'Budget', value: '${project.budget.toStringAsFixed(2)}'),
                  _InfoRow(label: 'Start', value: _fmt(project.startDate)),
                  _InfoRow(label: 'End', value: _fmt(project.endDate)),
                  if (project.description != null) _InfoRow(label: 'Description', value: project.description!),
                ],
              ),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Profitability'),
              Tab(text: 'Milestones'),
              Tab(text: 'Payments'),
              Tab(text: 'Expenses'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ProfitabilityTab(projectId: projectId),
                _MilestonesTab(projectId: projectId),
                _PaymentsTab(projectId: projectId),
                _ExpensesTab(projectId: projectId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _ProfitabilityTab extends ConsumerWidget {
  const _ProfitabilityTab({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profitAsync = ref.watch(_profitabilityProvider(projectId));
    return profitAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final d = data as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ProfitRow(label: 'Total payments', value: d['total_payments'] as String, color: Colors.green),
                      _ProfitRow(label: 'Total expenses', value: d['total_expenses'] as String, color: Colors.red),
                      const Divider(),
                      _ProfitRow(label: 'Balance', value: d['balance'] as String, color: Colors.blue, bold: true),
                      _ProfitRow(label: 'Profit margin', value: '${(d['profit_margin'] as String)}%', color: Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfitRow extends StatelessWidget {
  const _ProfitRow({required this.label, required this.value, required this.color, this.bold = false});
  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: bold ? FontWeight.bold : null)),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _MilestonesTab extends ConsumerWidget {
  const _MilestonesTab({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(milestonesByProjectProvider(projectId));
    return Stack(
      children: [
        milestonesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (milestones) {
            if (milestones.isEmpty) {
              return const Center(child: Text('No milestones yet'));
            }
            return ListView.separated(
              itemCount: milestones.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = milestones[i];
                return ListTile(
                  leading: _StatusIcon(status: m.status),
                  title: Text(m.title),
                  subtitle: Text('Due: ${_fmtDate(m.dueDate)}'),
                  trailing: Chip(label: Text(m.status)),
                  onTap: () => _showMilestoneForm(context, ref, projectId, m),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton(
            heroTag: 'milestone-fab',
            child: const Icon(Icons.add),
            onPressed: () => _showMilestoneForm(context, ref, projectId, null),
          ),
        ),
      ],
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsByProjectProvider(projectId));
    return Stack(
      children: [
        paymentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (payments) {
            if (payments.isEmpty) {
              return const Center(child: Text('No payments yet'));
            }
            final total = payments.fold<Decimal>(Decimal.zero, (sum, p) => sum + p.amount);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Total: ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = payments[i];
                      return ListTile(
                        leading: const Icon(Icons.payments_outlined, color: Colors.green),
                        title: Text(p.amount.toStringAsFixed(2)),
                        subtitle: Text('${_fmtDate(p.paymentDate)}  •  ${p.method}'),
                        onTap: () => _showPaymentForm(context, ref, projectId, p),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton(
            heroTag: 'payment-fab',
            child: const Icon(Icons.add),
            onPressed: () => _showPaymentForm(context, ref, projectId, null),
          ),
        ),
      ],
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesByProjectProvider(projectId));
    return Stack(
      children: [
        expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (expenses) {
            if (expenses.isEmpty) {
              return const Center(child: Text('No expenses yet'));
            }
            final total = expenses.fold<Decimal>(Decimal.zero, (sum, e) => sum + e.amount);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Total: ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = expenses[i];
                      return ListTile(
                        leading: const Icon(Icons.receipt_outlined, color: Colors.red),
                        title: Text(e.amount.toStringAsFixed(2)),
                        subtitle: Text('${_fmtDate(e.expenseDate)}  •  ${e.category}'),
                        onTap: () => _showExpenseForm(context, ref, projectId, e),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton(
            heroTag: 'expense-fab',
            child: const Icon(Icons.add),
            onPressed: () => _showExpenseForm(context, ref, projectId, null),
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'in_progress':
        return const Icon(Icons.timelapse, color: Colors.orange);
      case 'overdue':
        return const Icon(Icons.warning, color: Colors.red);
      default:
        return const Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
  }
}

void _showMilestoneForm(BuildContext context, WidgetRef ref, String projectId, MilestoneEntity? milestone) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => MilestoneFormDialog(projectId: projectId, milestone: milestone),
  );
  if (result == true) ref.invalidate(milestonesByProjectProvider(projectId));
}

void _showPaymentForm(BuildContext context, WidgetRef ref, String projectId, PaymentEntity? payment) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => PaymentFormDialog(projectId: projectId, payment: payment),
  );
  if (result == true) ref.invalidate(paymentsByProjectProvider(projectId));
}

void _showExpenseForm(BuildContext context, WidgetRef ref, String projectId, ExpenseEntity? expense) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ExpenseFormDialog(projectId: projectId, expense: expense),
  );
  if (result == true) ref.invalidate(expensesByProjectProvider(projectId));
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
            SizedBox(width: 90, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
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
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

/// Profitability future provider (family).
final _profitabilityProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/projects/$projectId/profitability');
  return res.data as Map<String, dynamic>;
});