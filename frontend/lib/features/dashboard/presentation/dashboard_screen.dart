import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final projectsAsync = ref.watch(dashboardProjectsProvider);
    final financeAsync = ref.watch(dashboardFinanceProvider);
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
    final chartHeight = width > 900 ? 320.0 : (width > 600 ? 260.0 : 200.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(dashboardProjectsProvider);
              ref.invalidate(dashboardFinanceProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPI cards
            summaryAsync.when(
              loading: () => const SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorBox(message: e.toString(), onRetry: () => ref.invalidate(dashboardSummaryProvider)),
              data: (s) => GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _KpiCard(
                    title: 'Active Projects',
                    value: '${s.activeProjects}',
                    icon: Icons.work,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _KpiCard(
                    title: 'Completed Projects',
                    value: '${s.completedProjects}',
                    icon: Icons.task_alt,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  _KpiCard(
                    title: 'Total Clients',
                    value: '${s.totalClients}',
                    icon: Icons.people,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  _KpiCard(
                    title: 'Outstanding',
                    value: _fmtMoney(s.outstandingBalances),
                    icon: Icons.account_balance_wallet,
                    color: s.outstandingBalances < Decimal.zero ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Projects overview table
            Text('Projects Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            projectsAsync.when(
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => _ErrorBox(message: e.toString(), onRetry: () => ref.invalidate(dashboardProjectsProvider)),
              data: (projects) {
                if (projects.isEmpty) {
                  return const Card(child: ListTile(title: Text('No projects yet'), leading: Icon(Icons.folder_off)));
                }
                return Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Client')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Budget'), numeric: true),
                        DataColumn(label: Text('Balance'), numeric: true),
                      ],
                      rows: projects.map((p) => DataRow(
                        onSelectChanged: (_) => context.go('/projects/${p.projectId}'),
                        cells: [
                          DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(p.clientName)),
                          DataCell(_StatusChip(status: p.status)),
                          DataCell(Text(_fmtMoney(p.budget))),
                          DataCell(Text(
                            _fmtMoney(p.balance),
                            style: TextStyle(color: p.balance < Decimal.zero ? Colors.red : Colors.green),
                          )),
                        ],
                      )).toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Cash flow chart
            Text('Cash Flow (12 months)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            financeAsync.when(
              loading: () => SizedBox(height: chartHeight, child: const Center(child: CircularProgressIndicator())),
              error: (e, _) => _ErrorBox(message: e.toString(), onRetry: () => ref.invalidate(dashboardFinanceProvider)),
              data: (finance) {
                if (finance.months.isEmpty) {
                  return SizedBox(height: chartHeight, child: const Card(child: Center(child: Text('No financial data yet'))));
                }
                return Card(
                  child: Container(
                    height: chartHeight,
                    padding: const EdgeInsets.all(16),
                    child: _CashFlowChart(months: finance.months),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _fmtMoney(Decimal d) => d.toStringAsFixed(2);
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  Color _color() {
    switch (status) {
      case 'active': return Colors.green.shade100;
      case 'completed': return Colors.blue.shade100;
      case 'on_hold': return Colors.orange.shade100;
      case 'cancelled': return Colors.red.shade100;
      default: return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) => Chip(label: Text(status), backgroundColor: _color());
}

class _CashFlowChart extends StatelessWidget {
  const _CashFlowChart({required this.months});
  final List<MonthlyPoint> months;

  @override
  Widget build(BuildContext context) {
    final maxVal = months.fold<Decimal>(Decimal.zero, (m, p) {
      final bigger = p.income > p.expense ? p.income : p.expense;
      return bigger > m ? bigger : m;
    });
    final maxDouble = maxVal.toDouble().abs();
    final chartMax = maxDouble == 0 ? 1.0 : maxDouble * 1.1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth / (months.length * 3);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Y-axis labels
            SizedBox(
              width: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_shortMoney(chartMax), style: const TextStyle(fontSize: 9)),
                  Text(_shortMoney(chartMax / 2), style: const TextStyle(fontSize: 9)),
                  const Text('0', style: TextStyle(fontSize: 9)),
                ],
              ),
            ),
            // Bars
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: months.length * barWidth * 3,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _BarPainter(
                      months: months,
                      maxVal: chartMax,
                      barWidth: barWidth,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _shortMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.months, required this.maxVal, required this.barWidth});
  final List<MonthlyPoint> months;
  final double maxVal;
  final double barWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paintIncome = Paint()..color = Colors.green;
    final paintExpense = Paint()..color = Colors.red;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < months.length; i++) {
      final m = months[i];
      final x = i * barWidth * 3 + barWidth;

      // income bar
      final incomeH = (m.income.toDouble().abs() / maxVal) * size.height * 0.85;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.9 - incomeH, barWidth, incomeH),
        paintIncome,
      );

      // expense bar
      final expenseH = (m.expense.toDouble().abs() / maxVal) * size.height * 0.85;
      canvas.drawRect(
        Rect.fromLTWH(x + barWidth + 2, size.height * 0.9 - expenseH, barWidth, expenseH),
        paintExpense,
      );

      // month label
      textPainter.text = TextSpan(
        text: m.month.length >= 7 ? m.month.substring(5) : m.month,
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 2, size.height * 0.92));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.months != months;
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
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