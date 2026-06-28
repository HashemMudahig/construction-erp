# Sprint 04 — Integration With Core APIs

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Frontend Integration Overview

The Reports feature integrates with the existing core stack: Riverpod (state), GoRouter (routing), Dio (HTTP + auth interceptor), and the standard response envelope.

```
ReportsScreen -> reportsControllerProvider -> ReportsService -> ReportsRepository -> Dio
```

## 2. Endpoints

In `lib/core/constants/endpoints.dart`:

```dart
static const String reportsProjectStatus   = '/reports/project-status';
static const String reportsFinancialSummary = '/reports/financial-summary';
static const String reportsExpenseAnalysis  = '/reports/expense-analysis';
```

All GET; auth handled by the existing `AuthInterceptor` adding the Bearer header.

## 3. Query Param Building

`ReportsFilters` -> query params, nulls omitted:

```dart
Map<String, dynamic> toQuery(ReportsFilters f, ReportType t) {
  final q = <String, dynamic>{};
  if (f.startDate != null) q['start_date'] = _iso(f.startDate!);
  if (f.endDate != null) q['end_date'] = _iso(f.endDate!);
  if (f.projectId != null) q['project_id'] = f.projectId;
  if (t == ReportType.projectStatus && f.status != null) q['status'] = f.status;
  return q;
}

String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
```

Date-range picker produces `DateTime`; convert to `YYYY-MM-DD` before sending.

## 4. Envelope Unwrap

`ReportsRemoteDataSource`:

```dart
Future<T> _get<T>(String path, Map<String, dynamic> q, T Function(Map<String,dynamic>) parse) async {
  final r = await dio.get(path, queryParameters: q);
  final json = r.data as Map<String, dynamic>;
  if (json['success'] == true) return parse(json['data'] as Map<String, dynamic>);
  throw ApiError(json['message'] as String, codes: List<String>.from(json['errors'] ?? []));
}
```

`ApiError` carries `codes` so the UI can map `INVALID_DATE_RANGE` etc. to user-friendly messages.

## 5. DTO Mapping

`report_dtos.dart` defines freezed DTOs mirroring the API contract. A mapper converts DTOs to domain entities in `domain/entities/report_entities.dart`, parsing money with `Decimal.parse`:

```dart
final income = Decimal.parse(dto['total_income'] as String);
final pct = Decimal.parse(cat['percentage'] as String);
```

Never use `double` for money or percentages.

## 6. Riverpod State

```dart
@riverpod
class ReportsController extends _$ReportsController {
  @override
  Future<ReportResult?> build() async => null;

  Future<void> generate(ReportsFilters f, ReportType t) async {
    state = const AsyncLoading();
    try {
      final res = await ref.read(reportsServiceProvider).fetch(f, t);
      state = AsyncData(res);
    } on ApiError catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
```

UI consumes `ref.watch(reportsControllerProvider)` and pattern-matches on `AsyncValue` (loading/data/error).

## 7. Routing

```dart
GoRoute(
  path: '/reports',
  builder: (_, __) => const ReportsScreen(),
  redirect: authGuard,
),
```

`authGuard` redirects to `/login` if no valid token. Add a drawer entry "Reports" from the dashboard.

## 8. Rendering by Type

```dart
switch (type) {
  case ReportType.projectStatus:
    return ProjectStatusTable(rows: result.asProjectStatus.rows);
  case ReportType.financialSummary:
    return FinancialSummaryTable(report: result.asFinancial);
  case ReportType.expenseAnalysis:
    return Column(children: [
      ExpenseAnalysisTable(report: result.asExpense),
      CategoryChart(categories: result.asExpense.byCategory),
    ]);
}
```

## 9. Error Mapping

| Code | UI Message |
| --- | --- |
| `INVALID_DATE_RANGE` | "Start date must be on or before end date." |
| `PROJECT_NOT_FOUND` | "Selected project no longer exists." |
| `REPORT_RANGE_TOO_LARGE` | "Selected range is too large; narrow the dates." |
| `UNAUTHORIZED` | redirect to login |

## 10. Export Placeholder

A disabled "Export" button is shown on the reports screen. It is a placeholder wired in S05 (CSV/PDF). For now it shows a tooltip "Available in Sprint 05."