import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../projects/presentation/project_providers.dart';
import 'report_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportType _reportType = ReportType.projectStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _projectId;
  String? _statusFilter;
  bool _generated = false;
  ReportFilters? _lastFilters;

  static const _statuses = [
    'active',
    'completed',
    'on_hold',
    'cancelled',
    'planning'
  ];

  String _localizedStatus(BuildContext ctx, String s) {
    final isAr = Localizations.localeOf(ctx).languageCode == 'ar';
    if (s == 'active') return isAr ? 'نشط' : 'Active';
    if (s == 'completed') return isAr ? 'مكتمل' : 'Completed';
    if (s == 'on_hold') return isAr ? 'معلق' : 'On Hold';
    if (s == 'cancelled') return isAr ? 'ملغى' : 'Cancelled';
    if (s == 'planning') return isAr ? 'تخطيط' : 'Planning';
    return s.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('reports')),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: context.tr('export'),
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Report type chips ──────────────────────────────────────────
            _SectionLabel(label: context.tr('report_type')),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: context.tr('project_status_report'),
                  icon: Icons.folder_open_outlined,
                  selected: _reportType == ReportType.projectStatus,
                  onTap: () => setState(() {
                    _reportType = ReportType.projectStatus;
                    _generated = false;
                  }),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: context.tr('financial_report'),
                  icon: Icons.bar_chart_outlined,
                  selected: _reportType == ReportType.financialSummary,
                  onTap: () => setState(() {
                    _reportType = ReportType.financialSummary;
                    _generated = false;
                  }),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: context.tr('expense_report'),
                  icon: Icons.receipt_long_outlined,
                  selected: _reportType == ReportType.expenseAnalysis,
                  onTap: () => setState(() {
                    _reportType = ReportType.expenseAnalysis;
                    _generated = false;
                  }),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Date filters ───────────────────────────────────────────────
            _SectionLabel(label: isAr ? 'الفترة الزمنية' : 'Date Range'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _DateField(
                  label: context.tr('filter_start'),
                  date: _startDate,
                  onPick: (d) => setState(() => _startDate = d),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _DateField(
                  label: context.tr('filter_end'),
                  date: _endDate,
                  onPick: (d) => setState(() => _endDate = d),
                )),
              ],
            ),

            const SizedBox(height: 16),

            // ── Project filter ─────────────────────────────────────────────
            _SectionLabel(label: isAr ? 'المشروع' : 'Project'),
            const SizedBox(height: 8),
            _ProjectDropdown(
              selected: _projectId,
              onChanged: (v) => setState(() => _projectId = v),
            ),

            if (_reportType == ReportType.projectStatus) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: context.tr('status')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _statusFilter,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.filter_list),
                  hintText: context.tr('all_statuses'),
                ),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(context.tr('all_statuses'))),
                  ..._statuses.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_localizedStatus(context, s)),
                      )),
                ],
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
            ],

            const SizedBox(height: 24),

            // ── Generate button ────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                icon: const Icon(Icons.assessment_outlined),
                label: Text(context.tr('generate'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  setState(() {
                    _lastFilters = ReportFilters(
                      type: _reportType,
                      startDate: _startDate,
                      endDate: _endDate,
                      projectId: _projectId,
                      status: _statusFilter,
                    );
                    _generated = true;
                  });
                },
              ),
            ),

            const SizedBox(height: 28),

            // ── Results area ───────────────────────────────────────────────
            if (_generated && _lastFilters != null)
              _ResultsArea(filters: _lastFilters!)
            else
              _HintView(hint: context.tr('report_hint')),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
      );
}

// ─── Report type chip ─────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hint view ────────────────────────────────────────────────────────────────

class _HintView extends StatelessWidget {
  const _HintView({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Date field ───────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.label, required this.date, required this.onPick});
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
        ),
        child: Text(
          date == null
              ? '—'
              : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}

// ─── Project dropdown ─────────────────────────────────────────────────────────

class _ProjectDropdown extends ConsumerStatefulWidget {
  const _ProjectDropdown({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<_ProjectDropdown> createState() => _ProjectDropdownState();
}

class _ProjectDropdownState extends ConsumerState<_ProjectDropdown> {
  List<dynamic> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final projects = await ref.read(projectRepositoryProvider).list();
      if (mounted) {
        setState(() {
          _projects = projects;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      initialValue: widget.selected,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.folder_outlined, size: 18),
        hintText: context.tr('all_projects'),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(context.tr('all_projects'))),
        ..._projects
            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
      ],
      onChanged: widget.onChanged,
    );
  }
}

// ─── Results area ─────────────────────────────────────────────────────────────

class _ResultsArea extends ConsumerWidget {
  const _ResultsArea({required this.filters});
  final ReportFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(reportResultProvider(filters));

    return resultAsync.when(
      loading: () => const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(reportResultProvider(filters))),
      data: (result) {
        final type = result['type'] as String;
        final data = result['data'];

        switch (type) {
          case 'project_status':
            return _ProjectStatusResults(data: data as List);
          case 'financial_summary':
            return _FinancialSummaryResults(
                data: FinancialSummary.fromJson(data as Map<String, dynamic>));
          case 'expense_analysis':
            return _ExpenseAnalysisResults(
                data: ExpenseAnalysis.fromJson(data as Map<String, dynamic>));
          default:
            return const Text('Unknown report type');
        }
      },
    );
  }
}

// ─── Project Status Results ───────────────────────────────────────────────────

class _ProjectStatusResults extends StatelessWidget {
  const _ProjectStatusResults({required this.data});
  final List data;

  String _localizedStatus(BuildContext ctx, String s) {
    final isAr = Localizations.localeOf(ctx).languageCode == 'ar';
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
  Widget build(BuildContext context) {
    if (data.isEmpty) return _EmptyView(message: context.tr('no_data'));

    final items = data
        .map((d) => ProjectStatusItem.fromJson(d as Map<String, dynamic>))
        .toList();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatPill(
              label: context.tr('tab_milestones'),
              value: '${items.length}',
              color: theme.colorScheme.primary,
              icon: Icons.folder_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Project cards
        ...items.map((item) {
          final statusColor = _statusColor(item.status);
          final progress = item.progressPct.toDouble() / 100.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _localizedStatus(context, item.status),
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${item.progressPct}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Budget / Payments / Expenses row
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _MiniStat(
                          label: context.tr('budget'),
                          value: _fmt(item.budget),
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7)),
                      _MiniStat(
                          label: context.tr('total_payments'),
                          value: _fmt(item.totalPayments),
                          color: Colors.green),
                      _MiniStat(
                          label: context.tr('total_expenses'),
                          value: _fmt(item.totalExpenses),
                          color: Colors.red),
                      _MiniStat(
                        label: context.tr('balance'),
                        value: _fmt(item.balance),
                        color: item.balance < Decimal.zero
                            ? Colors.red
                            : Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.tr('milestones_progress')}: ${item.completedMilestones}/${item.milestoneCount}',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _fmt(Decimal d) => d.toStringAsFixed(2);
}

// ─── Financial Summary Results ────────────────────────────────────────────────

class _FinancialSummaryResults extends StatelessWidget {
  const _FinancialSummaryResults({required this.data});
  final FinancialSummary data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI cards row
        Row(
          children: [
            Expanded(
                child: _KpiCard(
                    label: context.tr('income'),
                    value: data.totalIncome.toStringAsFixed(2),
                    color: Colors.green,
                    icon: Icons.trending_up)),
            const SizedBox(width: 10),
            Expanded(
                child: _KpiCard(
                    label: context.tr('total_expenses'),
                    value: data.totalExpenses.toStringAsFixed(2),
                    color: Colors.red,
                    icon: Icons.trending_down)),
            const SizedBox(width: 10),
            Expanded(
                child: _KpiCard(
              label: context.tr('net'),
              value: data.net.toStringAsFixed(2),
              color: data.net >= Decimal.zero ? Colors.teal : Colors.red,
              icon: data.net >= Decimal.zero
                  ? Icons.account_balance_wallet_outlined
                  : Icons.warning_amber_outlined,
            )),
          ],
        ),
        const SizedBox(height: 20),
        if (data.perProject.isNotEmpty) ...[
          _SectionLabel(label: context.tr('by_project')),
          const SizedBox(height: 10),
          ...data.perProject.map((p) => _FinancialProjectRow(project: p)),
        ] else
          _EmptyView(message: context.tr('no_data')),
      ],
    );
  }
}

class _FinancialProjectRow extends StatelessWidget {
  const _FinancialProjectRow({required this.project});
  final ProjectFinancial project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = project.net >= Decimal.zero;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(project.name,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          _MiniStat(
              label: context.tr('income'),
              value: project.income.toStringAsFixed(2),
              color: Colors.green),
          const SizedBox(width: 16),
          _MiniStat(
              label: context.tr('total_expenses'),
              value: project.expenses.toStringAsFixed(2),
              color: Colors.red),
          const SizedBox(width: 16),
          _MiniStat(
            label: context.tr('net'),
            value: project.net.toStringAsFixed(2),
            color: isPositive ? Colors.teal : Colors.red,
          ),
        ],
      ),
    );
  }
}

// ─── Expense Analysis Results ─────────────────────────────────────────────────

class _ExpenseAnalysisResults extends StatelessWidget {
  const _ExpenseAnalysisResults({required this.data});
  final ExpenseAnalysis data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KpiCard(
          label: context.tr('grand_total'),
          value: data.grandTotal.toStringAsFixed(2),
          color: Colors.orange,
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 20),
        if (data.byCategory.isNotEmpty) ...[
          _SectionLabel(label: context.tr('by_category')),
          const SizedBox(height: 10),
          ...data.byCategory.map((c) => _CategoryBar(item: c)),
          const SizedBox(height: 20),
          _SectionLabel(label: context.tr('by_project')),
          const SizedBox(height: 10),
          ...data.byProject.map((p) => _ProjectExpansionTile(project: p)),
        ] else
          _EmptyView(message: context.tr('no_data')),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.item});
  final CategoryBreakdown item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.category,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${item.percentage}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (item.percentage.toDouble() / 100.0)
                  .clamp(0.0, 1.0)
                  .toDouble(),
              minHeight: 7,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(height: 4),
          Text(item.total.toStringAsFixed(2),
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

class _ProjectExpansionTile extends StatelessWidget {
  const _ProjectExpansionTile({required this.project});
  final ProjectExpense project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(project.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(project.total.toStringAsFixed(2),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.orange)),
        children: project.byCategory
            .map((c) => ListTile(
                  dense: true,
                  title: Text(c.category),
                  trailing: Text(
                      '${c.total.toStringAsFixed(2)}  (${c.percentage}%)',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65))),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.75), fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text('$value $label',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: onRetry, child: Text(context.tr('retry'))),
            ],
          ),
        ),
      );
}
