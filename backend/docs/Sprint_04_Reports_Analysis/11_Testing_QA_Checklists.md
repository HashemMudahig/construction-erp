# Sprint 04 — Testing & QA Checklists

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Test Strategy

- **Unit tests:** service math (aggregation, percentage, net, balance) with in-memory seeded fixtures.
- **Integration tests:** endpoint tests via `httpx AsyncClient` against a test PostgreSQL (or test transaction) with seeded data; verify filters and aggregations.
- **Frontend widget tests:** ReportsScreen state transitions, filter building, table rendering.
- **QA manual checklist:** end-to-end on staging.

## 2. Unit Tests — Service Math

| Test | Setup | Assert |
| --- | --- | --- |
| `test_project_status_progress` | 4 milestones, 1 completed | `progress_pct == Decimal("25.00")` |
| `test_project_status_balance` | budget 100k, expenses 30k | `balance == Decimal("70000.00")` |
| `test_financial_summary_net` | income 50k, expenses 32k | `net == Decimal("18000.00")` |
| `test_financial_summary_per_project` | 2 projects with payments+expenses | per_project nets correct |
| `test_expense_analysis_pct` | Materials 150k, Labor 90k, total 300k | Materials pct `50.00`, Labor pct `30.00` |
| `test_expense_analysis_zero_total` | no expenses | `grand_total == 0`, `by_category == []`, no division error |
| `test_invalid_date_range_raises` | start > end | raises `INVALID_DATE_RANGE` |

Use `Decimal` in assertions, never `float`.

## 3. Integration Tests — Endpoints

### 3.1 Project Status

- `GET /reports/project-status` (no filter) -> all projects.
- `?status=active` -> only active.
- `?project_id=<existing>` -> single row.
- `?project_id=<missing>` -> 404 PROJECT_NOT_FOUND.
- No JWT -> 401.

### 3.2 Financial Summary

- No dates -> sums all-time.
- `?start_date=2026-01-01&end_date=2026-06-30` -> only rows in range.
- `start > end` -> 422 INVALID_DATE_RANGE.
- Empty range (no matching rows) -> 200 with zeros.

### 3.3 Expense Analysis

- No filter -> all expenses grouped by category.
- `?project_id=<p>` -> only that project's expenses.
- `?start_date&end_date` -> filtered by expense_date.
- Percentage sum across categories ~ `100.00` (allow rounding ±0.01).

## 4. Seeded Fixtures

A pytest fixture seeds:
- 3 projects (statuses: active, completed, on_hold).
- Payments across 2026-01..2026-08.
- Expenses across categories (Materials, Labor, Equipment).
- Milestones with mixed `is_completed`.

Seed values chosen so totals are easy to verify by hand (e.g. round numbers).

## 5. Frontend Widget Tests

- ReportsScreen shows empty hint initially.
- Selecting report type + filters + Generate calls provider.
- Loading state shows progress.
- Error state shows message + retry.
- ExpenseAnalysis renders CategoryChart with correct proportions.
- Empty result shows "No data" message.

## 6. QA Checklist

- [ ] All 3 reports generate from UI with no filter.
- [ ] Date-range filter restricts results correctly.
- [ ] Project filter restricts results correctly.
- [ ] Status filter restricts project status report.
- [ ] Invalid date range shows user-friendly error.
- [ ] Non-existent project shows error.
- [ ] Money values display with 2 decimals.
- [ ] Percentages display with 2 decimals and sum ~100.
- [ ] Expense analysis chart renders (bar or pie).
- [ ] Loading/empty/error states render correctly.
- [ ] No regressions in Sprints 01–03 screens.
- [ ] Reports endpoint requires auth (curl without token -> 401).

## 7. Test Files

```
backend/tests/reports/test_report_service.py
backend/tests/reports/test_reports_api.py
backend/tests/reports/conftest.py
lib/features/reports/presentation/test/reports_screen_test.dart
```

## 8. Exit Criteria

- All unit + integration tests green.
- QA checklist fully signed.
- Coverage of report service >= 90%.