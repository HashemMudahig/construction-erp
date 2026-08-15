import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/localized_business_labels.dart';
import '../../expenses/domain/expense_entity.dart';
import '../../expenses/presentation/expense_form_dialog.dart';
import '../../expenses/presentation/expense_providers.dart';
import '../../milestones/domain/milestone_entity.dart';
import '../../milestones/presentation/milestone_form_dialog.dart';
import '../../milestones/presentation/milestone_providers.dart';
import '../../payments/domain/payment_entity.dart';
import '../../payments/presentation/payment_form_dialog.dart';
import '../../payments/presentation/payment_providers.dart';
import '../../transfers/presentation/currency_transfer_dialog.dart';
import '../../transfers/presentation/currency_transfer_providers.dart';
import 'project_providers.dart';
import '../domain/project_repository_interface.dart';
import 'project_financial_presentation.dart';
import '../../../core/database/finance/money_scale.dart';
import '../../../core/database/finance/exchange_rate.dart';
import '../../../core/database/finance/currency_conversion.dart';
import '../../../core/database/database_constants.dart';

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
    return context.tr('status_$s');
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
      length: 5,
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
                        label: context.tr('contract_value'),
                        value: formatCurrencyDisplay(
                            project.budgetAmountMinor,
                            project.budgetCurrency),
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
              Tab(text: context.tr('financial_summary_tab')),
              Tab(text: context.tr('tab_milestones')),
              Tab(text: context.tr('tab_payments')),
              Tab(text: context.tr('tab_expenses')),
              Tab(text: context.tr('currency_transfer')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ProfitabilityTab(projectId: projectId, project: project),
                _MilestonesTab(projectId: projectId),
                _PaymentsTab(projectId: projectId),
                _ExpensesTab(projectId: projectId),
                _TransfersTab(projectId: projectId),
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
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11)),
              ),
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

class _ProfitabilityTab extends ConsumerStatefulWidget {
  const _ProfitabilityTab({required this.projectId, required this.project});
  final String projectId;
  final dynamic project;

  @override
  ConsumerState<_ProfitabilityTab> createState() => _ProfitabilityTabState();
}

class _ProfitabilityTabState extends ConsumerState<_ProfitabilityTab> {
  bool _showAnalytical = false;
  String _analyticalRate = '410.000000';

  @override
  Widget build(BuildContext context) {
    final profitAsync =
        ref.watch(projectFinancialSummaryProvider(widget.projectId));
    final walletsAsync =
        ref.watch(projectWalletBalancesProvider(widget.projectId));

    return profitAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${context.tr('error')} $e')),
      data: (data) {
        return walletsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('${context.tr('error')} $e')),
          data: (wallets) {
            final remainingContract = data.remainingContractValue;
            final isOverpayment = remainingContract < 0;
            final costOverrun = calculateCostOverrun(
              contractValueYer: data.contractCurrency == 'YER'
                  ? (widget.project.budgetAmountMinor as int)
                  : null,
              totalExpensesYer: data.contractCurrency == 'YER'
                  ? data.totalExpensesContractCurrency
                  : null,
            );

            int? analyticalRateScaled;
            int? analyticalConverted;
            if (_showAnalytical) {
              final parsed =
                  double.tryParse(_analyticalRate.trim()) ??
                  double.tryParse(_analyticalRate.trim().replaceAll(',', '.'));
              if (parsed != null && parsed > 0) {
                try {
                  analyticalRateScaled =
                      toScaledExchangeRateFromString(
                          _analyticalRate.trim());
                  analyticalConverted = wallets
                      .balanceFor('YER') +
                      convertToYer(wallets.balanceFor('SAR'), 'SAR',
                          analyticalRateScaled);
                } catch (_) {
                  analyticalRateScaled = null;
                }
              }
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfitCard(
                  label: context.tr('contract_value'),
                  value: formatDisplayAmount(
                      widget.project.budgetAmountMinor,
                      widget.project.budgetCurrency),
                  color: Colors.blueGrey,
                  icon: Icons.assignment_outlined,
                ),
                const SizedBox(height: 12),
                _ProfitCard(
                  label: context.tr('payments_received'),
                  value: _groupedCurrencyDisplay(data.paymentsByCurrency),
                  color: Colors.green,
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                _ProfitCard(
                  label: context.tr('expenses'),
                  value: _groupedCurrencyDisplay(data.expensesByCurrency),
                  color: Colors.red,
                  icon: Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 12),
                _ProfitCard(
                  label: context.tr('remaining_contract_value'),
                  value: formatDisplayAmount(
                      remainingContract, data.contractCurrency),
                  color: isOverpayment ? Colors.purple : Colors.blue,
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 16),
                // Per-currency wallet balances — never mixed.
                _WalletBalancesCard(wallets: wallets),
                const SizedBox(height: 8),
                // Optional analytical converted value, clearly marked.
                _AnalyticalValueCard(
                  showAnalytical: _showAnalytical,
                  onToggle: (v) => setState(() => _showAnalytical = v),
                  rate: _analyticalRate,
                  onRateChanged: (v) => setState(() => _analyticalRate = v),
                  analyticalConverted: analyticalConverted,
                ),
                if (costOverrun != null && costOverrun > 0) ...[
                  const SizedBox(height: 12),
                  _FinancialNotice(
                    title: context.tr('cost_overrun'),
                    message: context.tr('cost_overrun_detail').replaceAll(
                        '{amount}', formatDisplayAmount(costOverrun, 'YER')),
                    color: Colors.red,
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// Per-currency wallet balances card. Displays the SAR and YER wallet
/// balances independently — never mixed. The header reads "الرصيد النقدي
/// الحالي" / "Current cash balance".
class _WalletBalancesCard extends StatelessWidget {
  const _WalletBalancesCard({required this.wallets});
  final ProjectWalletBalances wallets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_outlined,
                  color: Colors.teal, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('current_cash_balance'),
                  style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in wallets.balances) ...[
            _WalletBalanceRow(entry: entry),
            if (entry.currency != wallets.balances.last.currency)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _WalletBalanceRow extends StatelessWidget {
  const _WalletBalanceRow({required this.entry});
  final WalletBalanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final labelKey =
        entry.currency == 'SAR' ? 'wallet_balance_sar' : 'wallet_balance_yer';
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '${context.tr(labelKey)} (${entry.currency})',
            style: TextStyle(
                color: Colors.teal.withValues(alpha: 0.85), fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 3,
          child: Text(
            formatCurrencyDisplay(entry.amountMinor, entry.currency),
            textAlign: TextAlign.end,
            style: TextStyle(
              color: entry.amountMinor < 0 ? Colors.deepOrange : Colors.teal,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Optional analytical converted value card. Shows a toggle to reveal an
/// analytical YER-equivalent total computed from a user-selected exchange
/// rate. The value is clearly marked as analytical only and is never used
/// for financial calculations or stored.
class _AnalyticalValueCard extends StatelessWidget {
  const _AnalyticalValueCard({
    required this.showAnalytical,
    required this.onToggle,
    required this.rate,
    required this.onRateChanged,
    required this.analyticalConverted,
  });
  final bool showAnalytical;
  final ValueChanged<bool> onToggle;
  final String rate;
  final ValueChanged<String> onRateChanged;
  final int? analyticalConverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined,
                  color: Colors.blueGrey, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('analytical_converted_value'),
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              Switch(
                value: showAnalytical,
                onChanged: onToggle,
              ),
            ],
          ),
          if (showAnalytical) ...[
            TextField(
              decoration: InputDecoration(
                labelText: context.tr('analytical_exchange_rate'),
                hintText: 'e.g. 410.000000',
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              controller: TextEditingController(text: rate),
              onChanged: onRateChanged,
            ),
            const SizedBox(height: 8),
            if (analyticalConverted != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'YER',
                      style: TextStyle(
                          color: Colors.blueGrey.withValues(alpha: 0.85),
                          fontSize: 14),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      formatCurrencyDisplay(analyticalConverted!, 'YER'),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              context.tr('analytical_value_disclaimer'),
              style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueGrey.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: isLarge ? 22 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialNotice extends StatelessWidget {
  const _FinancialNotice({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String title;
  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
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

    localStatus = localizedMilestoneStatus(context, milestone.status);
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
                    value: formatCurrencyDisplay(totalYer, 'YER'),
                    color: Colors.green),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = payments[i];
                      return _TransactionCard(
                        amount: formatDisplayAmount(
                            p.originalAmountMinor, p.originalCurrency),
                        subtitle:
                            '${_fmtDate(p.paymentDate)}  •  ${localizedPaymentMethod(context, p.method)}',
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
                    value: formatCurrencyDisplay(totalYer, 'YER'),
                    color: Colors.red),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = expenses[i];
                      return _TransactionCard(
                        amount: formatDisplayAmount(
                            e.originalAmountMinor, e.originalCurrency),
                        subtitle:
                            '${_fmtDate(e.expenseDate)}  •  ${localizedExpenseCategory(context, e.category)}',
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

// ─── Transfers Tab ─────────────────────────────────────────────────────────────

class _TransfersTab extends ConsumerWidget {
  const _TransfersTab({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transfersByProjectProvider(projectId));
    return Stack(
      children: [
        transfersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (transfers) {
            if (transfers.isEmpty) {
              return Center(child: Text(context.tr('no_transfers')));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: transfers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = transfers[i];
                return _TransactionCard(
                  amount:
                      '${formatDisplayAmount(t.sourceAmountMinor, t.sourceCurrency)} → ${formatDisplayAmount(t.targetAmountMinor, t.targetCurrency)}',
                  subtitle:
                      '${_fmtDate(t.date)}  •  1 ${t.sourceCurrency} = ${formatScaledExchangeRate(t.exchangeRateScaled)} ${t.targetCurrency == kCurrencyYer ? 'YER' : t.targetCurrency}',
                  icon: Icons.swap_horiz,
                  color: Colors.indigo,
                  onTap: () {},
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'transfer-fab',
            child: const Icon(Icons.swap_horiz),
            onPressed: () => _showTransferForm(context, ref, projectId),
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
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
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

void _showTransferForm(BuildContext context, WidgetRef ref, String projectId) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => CurrencyTransferDialog(projectId: projectId),
  );
  if (result == true) {
    ref.invalidate(transfersByProjectProvider(projectId));
    ref.invalidate(projectWalletBalancesProvider(projectId));
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Renders a grouped multi-currency breakdown as a single display string,
/// one line per currency, e.g. "SAR 238,095.00\nYER 15,000,000".
///
/// When only one currency is present, returns that single formatted line.
/// Never mixes currencies on the same line.
String _groupedCurrencyDisplay(List<CurrencyBreakdownEntry> entries) {
  if (entries.isEmpty) return '0';
  if (entries.length == 1) {
    return formatDisplayAmount(entries.first.amountMinor, entries.first.currency);
  }
  return entries
      .map((e) => formatDisplayAmount(e.amountMinor, e.currency))
      .join('\n');
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
            FilledButton(onPressed: onRetry, child: Text(context.tr('retry'))),
          ],
        ),
      );
}
