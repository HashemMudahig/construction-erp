# Phase 09 — Reports Local Queries

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Migrate report data from the FastAPI backend to local SQLite queries. Implement a local report query service that computes project status reports, financial summaries, and expense analysis from local data.

## Current State

Report data is managed through:
- `frontend/lib/features/reports/presentation/report_providers.dart` — `reportResultProvider` (FutureProvider.family<Map<String, dynamic>, ReportFilters>).
- The provider calls `dioProvider` directly to fetch from `GET /reports/project-status`, `GET /reports/financial-summary`, `GET /reports/expense-analysis`.
- DTOs (`ProjectStatusItem`, `FinancialSummary`, `ExpenseAnalysis`, etc.) are defined but the provider returns raw `Map<String, dynamic>` instead of typed objects.

Report types:
1. **Project Status** — per-project: budget, total_payments, total_expenses, balance, milestone_count, completed_milestones, progress_pct.
2. **Financial Summary** — date-range filtered: total_income, total_expenses, net, per-project breakdown.
3. **Expense Analysis** — date-range and optional project filtered: grand_total, by_category (with percentages), by_project (with nested by_category).

Backend formulas (from `backend/app/repositories/report_repository.py`):
- `progress_pct` = `completed_milestones / milestone_count * 100` quantized to 0.01.
- `percentage` (expense category) = `total / grand_total * 100` quantized to 0.01.
- `net` = `total_income - total_expenses`.

Filters:
- `start_date`, `end_date` (optional date range).
- `project_id` (optional, for project status and expense analysis).
- `status` (optional, for project status).

## Target State

- A `ReportQueryService` that computes all report data from local SQLite data.
- Report provider uses the local query service.
- Typed DTOs are used instead of raw `Map<String, dynamic>`.
- No HTTP calls for report data.
- Decimal/Rational conversion risks addressed (all arithmetic using Decimal).

## Scope

- Local report query service.
- Project status report computation.
- Financial summary report computation.
- Expense analysis report computation.
- Provider migration.
- Typed DTO usage.

## Out of Scope

- Export functionality (CSV/PDF) — not currently implemented.
- Backup and restore (Phase 11).

## Prerequisites

- Phases 03–07 (all entity local storage) must be completed.
- ADR-007 (Dashboard and reports are derived queries) must be Accepted.

## Relevant Current Files

- `frontend/lib/features/reports/presentation/report_providers.dart`
- `frontend/lib/features/reports/presentation/reports_screen.dart`
- `backend/app/repositories/report_repository.py` — Reference for query logic.
- `backend/app/schemas/reports.py` — Reference for response models.

## Expected New Files

- `frontend/lib/features/reports/domain/report_query_service.dart` (proposed)
- `frontend/lib/features/reports/data/local_report_repository.dart` (proposed)

## Data Model Impact

No new tables. Report data is derived from existing local tables.

## Repository and Provider Impact

```
ReportsScreen
→ reportResultProvider
→ ReportQueryService
→ DAOs (ProjectDao, PaymentDao, ExpenseDao, MilestoneDao, ClientDao)
→ AppDatabase
→ SQLite
```

## Implementation Tasks

- [ ] Define `ReportQueryService` class.
- [ ] Implement `getProjectStatus(projectId?, status?)` — per-project metrics with milestone progress.
- [ ] Implement `getFinancialSummary(startDate?, endDate?)` — totals and per-project breakdown.
- [ ] Implement `getExpenseAnalysis(startDate?, endDate?, projectId?)` — category and project breakdowns with percentages.
- [ ] Ensure all Decimal arithmetic uses the `decimal` package (no double conversion).
- [ ] Migrate `reportResultProvider` to use `ReportQueryService`.
- [ ] Refactor provider to return typed DTOs instead of raw `Map<String, dynamic>`.
- [ ] Update `reports_screen.dart` to consume typed DTOs.
- [ ] Write unit tests for report query service.
- [ ] Write tests with known data sets and expected values.
- [ ] Run `flutter analyze`.
- [ ] Verify reports screen renders correctly with local data.

## Validation Plan

- Static analysis: `flutter analyze`.
- Unit tests: Each report type with various filters.
- Decimal precision: Verify all percentage and sum calculations use Decimal.
- Persistence after restart: Reports compute from persisted data.
- Offline behavior: Reports load with no network.
- Regression checks: Reports screen displays correct data for all three report types.

## Acceptance Criteria

1. Project status report computes correct metrics per project.
2. Financial summary report computes correct totals and per-project breakdown.
3. Expense analysis report computes correct category and project breakdowns with percentages.
4. All date range and project filters work.
5. All Decimal arithmetic preserves precision (no double conversion).
6. No HTTP calls for report data.
7. `flutter analyze` reports zero errors.
8. All report tests pass.
9. Reports screen renders correctly with typed DTOs.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-008: Financial precision loss in percentage calculations. Mitigated by Decimal arithmetic.
- R-014: Invalid date parsing in date range filters. Mitigated by ISO date format.

## Rollback Strategy

1. Revert `report_providers.dart` to use Dio.
2. Delete `ReportQueryService` and local report repository.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 09 status.
- `frontend/HISTORY.md` — Add entry for reports local queries.
- `docs/history.md` — Add entry for reports local queries.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent