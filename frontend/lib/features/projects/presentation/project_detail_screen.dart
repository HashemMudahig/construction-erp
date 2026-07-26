import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../expenses/domain/expense_entity.dart';
import '../../expenses/presentation/expense_form_dialog.dart';
import '../../expenses/presentation/expense_providers.dart';
import '../../milestones/domain/milestone_entity.dart';
import '../../milestones/presentation/milestone_form_dialog.dart';
import '../../milestones/presentation/milestone_providers.dart';
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
        title: Text(context.tr('project_detail')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: context.tr('edit'),
            onPressed: () => context.go('/projects/$id/edit'),
          ),
        ],
      ),
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(projectDetailProvider(id))),
        data: (p) => _ProjectDetailBody(
            projectId: id, project: p, theme: theme, ref: ref),
      ),
    );
  }
}

class _ProjectDetailBody extends ConsumerWidget {
  const _ProjectDetailBody(
      {required this.projectId,
      required this.project,
      required this.theme,
      required this.ref});
  final String projectId;
  final dynamic project;
  final ThemeData theme;
  final WidgetRef ref;

  String _localizedStatus(BuildContext context, String s) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (s == 'active') return isAr ? 'نشط' : 'Active';
    if (s == 'completed') return isAr ? 'مكتمل' : 'Completed';
    if (s == 'on_hold') return isAr ? 'معلق' : 'On Hold';
    if (s == 'cancelled') return isAr ? 'ملغى' : 'Cancelled';
    if (s == 'planning') return isAr ? 'تخطيط' : 'Planning';
    return s.replaceAll('_', ' ');
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'on_hold':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(project.status);

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // ── Header card ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _localizedStatus(context, project.status),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Budget / Start / End row
                  Row(
                    children: [
                      _HeaderStat(
                        label: context.tr('budget'),
                        value:
                            '${project.budgetAmountMinor} ${project.budgetCurrency}',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      const SizedBox(width: 16),
                      _HeaderStat(
                        label: context.tr('start_date'),
                        value: _fmt(project.startDate),
                        icon: Icons.calendar_today_outlined,
                      ),
                      const SizedBox(width: 16),
                      _HeaderStat(
                        label: context.tr('end_date'),
                        value: _fmt(project.endDate),
                        icon: Icons.flag_outlined,
                      ),
                    ],
                  ),
                  if (project.description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      project.description!,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ── Tab bar ──
          const SizedBox(height: 8),
          TabBar(
            isScrollable: false,
            tabs: [
              Tab(text: context.tr('profitability')),
              Tab(text: context.tr('tab_milestones')),
              Tab(text: context.tr('tab_payments')),
              Tab(text: context.tr('tab_expenses')),
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

class _HeaderStat extends StatelessWidget {
  const _HeaderStat(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Profitability Tab ────────────────────────────────────────────────────────

class _ProfitabilityTab extends ConsumerWidget {
  const _ProfitabilityTab({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profitAsync = ref.watch(projectFinancialSummaryProvider(projectId));
    return profitAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfitCard(
              label: context.tr('total_payments'),
              value: '${data.totalPaymentsYer} YER',
              color: Colors.green,
              icon: Icons.payments_outlined,
            ),
            const SizedBox(height: 12),
            _ProfitCard(
              label: context.tr('total_expenses'),
              value: '${data.totalExpensesYer} YER',
              color: Colors.red,
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _ProfitCard(
              label: context.tr('balance'),
              value: '${data.balance} YER',
              color: Colors.blue,
              icon: Icons.account_balance_outlined,
              isLarge: true,
            ),
            const SizedBox(height: 12),
            _ProfitCard(
              label: context.tr('profit_margin'),
              value: '${(data.profitMargin * 100).toStringAsFixed(1)}%',
              color: Colors.orange,
              icon: Icons.trending_up,
            ),
          ],
        );
      },
    );
  }
}

class _ProfitCard extends StatelessWidget {
  const _ProfitCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isLarge = false,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style:
                  TextStyle(color: color.withValues(alpha: 0.8), fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isLarge ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Milestones Tab ───────────────────────────────────────────────────────────

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
              return Center(child: Text(context.tr('no_milestones')));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: milestones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = milestones[i];
                return _MilestoneCard(
                    milestone: m,
                    onTap: () =>
                        _showMilestoneForm(context, ref, projectId, m));
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
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

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone, required this.onTap});
  final MilestoneEntity milestone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    String localStatus = milestone.status;
    if (milestone.status == 'completed') {
      localStatus = isAr ? 'مكتمل' : 'Completed';
    }
    if (milestone.status == 'in_progress') {
      localStatus = isAr ? 'قيد التنفيذ' : 'In Progress';
    }
    if (milestone.status == 'overdue') localStatus = isAr ? 'متأخر' : 'Overdue';
    if (milestone.status == 'pending') localStatus = isAr ? 'معلق' : 'Pending';

    return Card(
      child: ListTile(
        leading: _StatusIcon(status: milestone.status),
        title: Text(milestone.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${context.tr('due')}: ${_fmtDate(milestone.dueDate)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusBg(milestone.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(localStatus,
              style: TextStyle(
                  fontSize: 12,
                  color: _statusFg(milestone.status),
                  fontWeight: FontWeight.bold)),
        ),
        onTap: onTap,
      ),
    );
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'in_progress':
        return const Color(0xFFFEF3C7);
      case 'overdue':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusFg(String s) {
    switch (s) {
      case 'completed':
        return const Color(0xFF166534);
      case 'in_progress':
        return const Color(0xFF92400E);
      case 'overdue':
        return const Color(0xFF991B1B);
      default:
        return const Color(0xFF475569);
    }
  }
}

// ─── Payments Tab ─────────────────────────────────────────────────────────────

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
              return Center(child: Text(context.tr('no_payments')));
            }
            final totalYer =
                payments.fold<int>(0, (sum, p) => sum + p.convertedYerAmount);
            return Column(
              children: [
                _TotalBanner(
                    label: context.tr('total'),
                    value: '$totalYer YER',
                    color: Colors.green),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = payments[i];
                      return _TransactionCard(
                        amount:
                            '${p.originalAmountMinor} ${p.originalCurrency}',
                        subtitle: '${_fmtDate(p.paymentDate)}  •  ${p.method}',
                        icon: Icons.payments_outlined,
                        color: Colors.green,
                        onTap: () =>
                            _showPaymentForm(context, ref, projectId, p),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
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

// ─── Expenses Tab ─────────────────────────────────────────────────────────────

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
              return Center(child: Text(context.tr('no_expenses')));
            }
            final totalYer =
                expenses.fold<int>(0, (sum, e) => sum + e.convertedYerAmount);
            return Column(
              children: [
                _TotalBanner(
                    label: context.tr('total'),
                    value: '$totalYer YER',
                    color: Colors.red),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = expenses[i];
                      return _TransactionCard(
                        amount:
                            '${e.originalAmountMinor} ${e.originalCurrency}',
                        subtitle:
                            '${_fmtDate(e.expenseDate)}  •  ${e.category}',
                        icon: Icons.receipt_outlined,
                        color: Colors.red,
                        onTap: () =>
                            _showExpenseForm(context, ref, projectId, e),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
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

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _TotalBanner extends StatelessWidget {
  const _TotalBanner(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      );
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(amount,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          trailing:
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          onTap: onTap,
        ),
      );
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

void _showMilestoneForm(BuildContext context, WidgetRef ref, String projectId,
    MilestoneEntity? milestone) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) =>
        MilestoneFormDialog(projectId: projectId, milestone: milestone),
  );
  if (result == true) ref.invalidate(milestonesByProjectProvider(projectId));
}

void _showPaymentForm(BuildContext context, WidgetRef ref, String projectId,
    PaymentEntity? payment) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => PaymentFormDialog(projectId: projectId, payment: payment),
  );
  if (result == true) ref.invalidate(paymentsByProjectProvider(projectId));
}

void _showExpenseForm(BuildContext context, WidgetRef ref, String projectId,
    ExpenseEntity? expense) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ExpenseFormDialog(projectId: projectId, expense: expense),
  );
  if (result == true) ref.invalidate(expensesByProjectProvider(projectId));
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
            FilledButton(onPressed: onRetry, child: Text(context.tr('retry'))),
          ],
        ),
      );
}
