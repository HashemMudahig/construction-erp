# 04 — Frontend Developer Guide (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Feature Layout
```
lib/features/dashboard/
  data/
    datasources/dashboard_remote_datasource.dart
    models/dashboard_summary_dto.dart
    models/project_overview_dto.dart
    models/finance_overview_dto.dart
    repositories/dashboard_repository_impl.dart
  domain/
    entities/dashboard_summary.dart
    entities/project_overview.dart
    entities/finance_overview.dart
    usecases/get_dashboard.dart
  presentation/
    providers/dashboard_provider.dart
    widgets/kpi_card.dart
    widgets/projects_overview_table.dart
    widgets/cash_flow_chart.dart
    screens/dashboard_screen.dart
```

## 2. Endpoints (`lib/core/constants/endpoints.dart`)
```dart
class Endpoints {
  static const String dashboardSummary  = '/api/v1/dashboard/summary';
  static const String dashboardProjects = '/api/v1/dashboard/projects';
  static const String dashboardFinance  = '/api/v1/dashboard/finance';
}
```

## 3. Riverpod Provider
`DashboardProvider` fires the three GETs in parallel and exposes a unified state object.

```dart
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repo);
});

class DashboardState {
  final AsyncValue<DashboardSummary> summary;
  final AsyncValue<List<ProjectOverview>> projects;
  final AsyncValue<FinanceOverview> finance;
  final DateTime? lastRefresh;
  const DashboardState({this.summary, this.projects, this.finance, this.lastRefresh});
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._repo) : super(const DashboardState());
  final DashboardRepository _repo;

  Future<void> refresh() async {
    final results = await Future.wait([
      _repo.fetchSummary(),
      _repo.fetchProjects(),
      _repo.fetchFinance(),
    ]);
    state = DashboardState(
      summary: AsyncValue.data(results[0] as DashboardSummary),
      projects: AsyncValue.data(results[1] as List<ProjectOverview>),
      finance: AsyncValue.data(results[2] as FinanceOverview),
      lastRefresh: DateTime.now(),
    );
  }
}
```

## 4. DTO → Entity mapping
```dart
DashboardSummary toEntity(DashboardSummaryDto d) => DashboardSummary(
  activeProjects: d.activeProjects,
  completedProjects: d.completedProjects,
  totalClients: d.totalClients,
  outstandingBalances: d.outstandingBalances, // Decimal/string parsed
  totalPayments: d.totalPayments,
  totalExpenses: d.totalExpenses,
);
```

## 5. KPI Card widget
```dart
class KpiCard extends StatelessWidget {
  final String label; final String value; final IconData icon;
  const KpiCard({required this.label, required this.value, required this.icon});
  @override Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 28), const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ]),
      ),
    );
  }
}
```

## 6. Chart widget (`fl_chart`)
Use `fl_chart`'s `BarChart` for the 12-month cash flow. Income and expense are paired bars per month.
```dart
BarChartData data(List<MonthlyPoint> months) => BarChartData(
  barGroups: List.generate(months.length, (i) {
    final m = months[i];
    return BarChartGroupData(x: i, barRods: [
      BarChartRodData(toY: m.income.toDouble(), color: Colors.green),
      BarChartRodData(toY: m.expense.toDouble(), color: Colors.red),
    ]);
  }),
);
```
Fallback: `CustomPaint` if `fl_chart` license/size is a concern.

## 7. States
- **Loading:** `AsyncValue.loading` → shimmer placeholders on cards/table; spinner on chart.
- **Empty:** `AsyncValue.data` with zero rows → "No projects yet" empty illustration.
- **Error:** `AsyncValue.error` → red banner with retry `Refresh` button.
- **Refresh:** pull-to-refresh on the screen calls `ref.read(dashboardProvider.notifier).refresh()`.

## 8. Routing (GoRouter)
```dart
GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen());
```
Add as the initial location after login.

## 9. Conventions
- Money values are strings from API → parse with `Decimal.parse` from `decimal` package for safe arithmetic, display with `intl.NumberFormat.currency`.
- Colors: green positive balance, red negative.
- Material 3 theming; responsive grid uses `LayoutBuilder` breakpoints (2 cols mobile, 4 cols desktop).