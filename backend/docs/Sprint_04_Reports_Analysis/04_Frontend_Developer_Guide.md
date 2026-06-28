# Sprint 04 — Frontend Developer Guide

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Feature Structure

New feature-first module at `lib/features/reports/`:

```
lib/features/reports/
  data/
    data_sources/reports_remote_data_source.dart
    models/report_dtos.dart
    repositories/reports_repository_impl.dart
  domain/
    entities/report_entities.dart
    repositories/reports_repository.dart
    services/reports_service.dart
  presentation/
    providers/reports_provider.dart
    screens/reports_screen.dart
    widgets/report_type_selector.dart
    widgets/report_filters.dart
    widgets/project_status_table.dart
    widgets/financial_summary_table.dart
    widgets/expense_analysis_table.dart
    widgets/category_chart.dart
```

## 2. Endpoints (`lib/core/constants/endpoints.dart`)

```dart
class Endpoints {
  static const String reportsProjectStatus = '/reports/project-status';
  static const String reportsFinancialSummary = '/reports/financial-summary';
  static const String reportsExpenseAnalysis = '/reports/expense-analysis';
}
```

## 3. Riverpod Providers

```dart
enum ReportType { projectStatus, financialSummary, expenseAnalysis }

@freezed
class ReportsFilters {
  const ReportsFilters._();
  const factory ReportsFilters({
    ReportType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? projectId,
    String? status,
  }) = _ReportsFilters;
}

@riverpod
class ReportsController extends _$ReportsController {
  @override
  Future<ReportResult?> build() => Future.value(null);

  Future<void> generate(ReportsFilters f) async {
    state = const AsyncLoading();
    try {
      final res = await ref.read(reportsServiceProvider).fetch(f);
      state = AsyncData(res);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
```

## 4. Repository & Data Source

`ReportsRemoteDataSource` uses Dio with the auth interceptor. Query params are built from `ReportsFilters`, omitting nulls:

```dart
final qp = <String, dynamic>{};
if (f.startDate != null) qp['start_date'] = isoDate(f.startDate!);
if (f.endDate != null) qp['end_date'] = isoDate(f.endDate!);
if (f.projectId != null) qp['project_id'] = f.projectId;
if (f.status != null) qp['status'] = f.status;
final r = await dio.get(Endpoints.reportsProjectStatus, queryParameters: qp);
```

Unwrap the standard envelope: `if (json['success']) return mapper(json['data']); else throw ApiError(json['message']);`.

## 5. Domain Entities

```dart
abstract class ReportResult {}
class ProjectStatusResult extends ReportResult { final List<ProjectStatusRow> rows; ... }
class FinancialSummaryResult extends ReportResult { final Decimal income; final Decimal expenses; final Decimal net; final List<ProjectFinancial> perProject; ... }
class ExpenseAnalysisResult extends ReportResult { final Decimal grandTotal; final List<CategoryBreakdown> byCategory; final List<ProjectExpense> byProject; ... }
```

Decimals parsed with `Decimal.parse` (package `decimal`); never `double`.

## 6. Presentation

`ReportsScreen` layout:
1. `ReportTypeSelector` (segmented control / dropdown).
2. `ReportFilters` — date-range picker + project dropdown + (status for project status).
3. "Generate" button -> `ref.read(reportsControllerProvider.notifier).generate(f)`.
4. Results area switches widget by `ReportType`:
   - ProjectStatus -> `ProjectStatusTable`
   - FinancialSummary -> `FinancialSummaryTable`
   - ExpenseAnalysis -> `ExpenseAnalysisTable` + `CategoryChart` (bar/pie)

## 7. States

- **Loading:** `AsyncLoading` -> progress indicator over results area.
- **Empty:** `AsyncData` with zero rows -> "No data for the selected filters."
- **Error:** `AsyncError` -> error message + retry button.
- **Initial:** null result -> hint text "Select a report type and filters, then Generate."

## 8. Routing

Add route `/reports` in GoRouter. Accessible from the dashboard drawer. Requires auth (redirect to `/login` if unauthenticated).