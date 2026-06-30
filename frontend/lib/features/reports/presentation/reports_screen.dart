import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/data/project_repository.dart';
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

  static const _statuses = ['active', 'completed', 'on_hold', 'cancelled', 'planning'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export (available in Sprint 05)',
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report type selector
            SegmentedButton<ReportType>(
              segments: const [
                ButtonSegment(value: ReportType.projectStatus, label: Text('Project Status')),
                ButtonSegment(value: ReportType.financialSummary, label: Text('Financial')),
                ButtonSegment(value: ReportType.expenseAnalysis, label: Text('Expenses')),
              ],
              selected: {_reportType},
              onSelectionChanged: (selection) {
                setState(() {
                  _reportType = selection.first;
                  _generated = false;
                });
              },
            ),
            const SizedBox(height: 16),
            // Filters row
            Row(
              children: [
                Expanded(child: _DateField(label: 'Start', date: _startDate, onPick: (d) => setState(() => _startDate = d))),
                const SizedBox(width: 12),
                Expanded(child: _DateField(label: 'End', date: _endDate, onPick: (d) => setState(() => _endDate = d))),
              ],
            ),
            const SizedBox(height: 12),
            // Project filter
            _ProjectDropdown(
              selected: _projectId,
              onChanged: (v) => setState(() => _projectId = v),
            ),
            if (_reportType == ReportType.projectStatus) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: const InputDecoration(labelText: 'Status', isDense: true),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All statuses')),
                  ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.assessment),
              label: const Text('Generate'),
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
            const SizedBox(height: 24),
            // Results area
            if (_generated && _lastFilters != null)
              _ResultsArea(filters: _lastFilters!)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Select a report type and filters, then Generate.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onPick});
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
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true),
        child: Text(date == null
            ? '—'
            : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'),
      ),
    );
  }
}

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
      final dtos = await ref.read(projectRepositoryProvider).list(limit: 100);
      if (mounted) setState(() { _projects = dtos; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      value: widget.selected,
      decoration: const InputDecoration(labelText: 'Project', isDense: true),
      items: [
        const DropdownMenuItem(value: null, child: Text('All projects')),
        ..._projects.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.status})'))),
      ],
      onChanged: widget.onChanged,
    );
  }
}

class _ResultsArea extends ConsumerWidget {
  const _ResultsArea({required this.filters});
  final ReportFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(reportResultProvider(filters));

    return resultAsync.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ErrorView(message: e.toString(), onRetry: () => ref.invalidate(reportResultProvider(filters))),
      data: (result) {
        final type = result['type'] as String;
        final data = result['data'];

        switch (type) {
          case 'project_status':
            return _ProjectStatusResults(data: data as List);
          case 'financial_summary':
            return _FinancialSummaryResults(data: FinancialSummary.fromJson(data as Map<String, dynamic>));
          case 'expense_analysis':
            return _ExpenseAnalysisResults(data: ExpenseAnalysis.fromJson(data as Map<String, dynamic>));
          default:
            return const Text('Unknown report type');
        }
      },
    );
  }
}

class _ProjectStatusResults extends StatelessWidget {
  const _ProjectStatusResults({required this.data});
  final List data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyView();
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Project')), DataColumn(label: Text('Status')),
            DataColumn(label: Text('Budget'), numeric: true),
            DataColumn(label: Text('Payments'), numeric: true),
            DataColumn(label: Text('Expenses'), numeric: true),
            DataColumn(label: Text('Balance'), numeric: true),
            DataColumn(label: Text('Milestones')), DataColumn(label: Text('Progress')),
          ],
          rows: data.map((d) {
            final item = ProjectStatusItem.fromJson(d as Map<String, dynamic>);
            return DataRow(cells: [
              DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Chip(label: Text(item.status))),
              DataCell(Text(item.budget.toStringAsFixed(2))),
              DataCell(Text(item.totalPayments.toStringAsFixed(2))),
              DataCell(Text(item.totalExpenses.toStringAsFixed(2))),
              DataCell(Text(item.balance.toStringAsFixed(2),
                  style: TextStyle(color: item.balance < Decimal.zero ? Colors.red : Colors.green))),
              DataCell(Text('${item.completedMilestones}/${item.milestoneCount}')),
              DataCell(Text('${item.progressPct}%')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _FinancialSummaryResults extends StatelessWidget {
  const _FinancialSummaryResults({required this.data});
  final FinancialSummary data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'Income', value: data.totalIncome.toStringAsFixed(2), color: Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _SummaryCard(label: 'Expenses', value: data.totalExpenses.toStringAsFixed(2), color: Colors.red)),
            const SizedBox(width: 8),
            Expanded(child: _SummaryCard(
              label: 'Net', value: data.net.toStringAsFixed(2),
              color: data.net >= Decimal.zero ? Colors.green : Colors.red)),
          ],
        ),
        const SizedBox(height: 16),
        // Per-project table
        if (data.perProject.isEmpty)
          const _EmptyView()
        else
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Project')),
                  DataColumn(label: Text('Income'), numeric: true),
                  DataColumn(label: Text('Expenses'), numeric: true),
                  DataColumn(label: Text('Net'), numeric: true),
                ],
                rows: data.perProject.map((p) => DataRow(cells: [
                  DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(p.income.toStringAsFixed(2))),
                  DataCell(Text(p.expenses.toStringAsFixed(2))),
                  DataCell(Text(p.net.toStringAsFixed(2),
                      style: TextStyle(color: p.net < Decimal.zero ? Colors.red : Colors.green))),
                ])).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExpenseAnalysisResults extends StatelessWidget {
  const _ExpenseAnalysisResults({required this.data});
  final ExpenseAnalysis data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(label: 'Grand Total', value: data.grandTotal.toStringAsFixed(2), color: Colors.orange),
        const SizedBox(height: 16),
        if (data.byCategory.isEmpty)
          const _EmptyView()
        else ...[
          // Category breakdown table
          Text('By Category', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: data.byCategory.map((c) => ListTile(
                title: Text(c.category),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.total.toStringAsFixed(2)),
                    const SizedBox(width: 12),
                    SizedBox(width: 60, child: Text('${c.percentage}%', textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                leading: _CategoryBar(percentage: c.percentage.toDouble()),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // By project
          Text('By Project', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: data.byProject.map((p) => ExpansionTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(p.total.toStringAsFixed(2)),
                children: p.byCategory.map((c) => ListTile(
                  dense: true,
                  title: Text(c.category),
                  trailing: Text('${c.total.toStringAsFixed(2)}  (${c.percentage}%)'),
                )).toList(),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      );
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.percentage});
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40, height: 40,
      child: CircularProgressIndicator(
        value: percentage / 100,
        strokeWidth: 4,
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No data for the selected filters.')),
      );
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
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}