# Phase 08 — Dashboard Local Queries

## Status

- Status: Completed
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-26
- Implementation started: 2026-07-26
- Implementation completed: 2026-07-26

## Objective

Migrate dashboard data from the FastAPI backend to local SQLite queries. Implement a local dashboard query service that computes summary metrics, project overview, and finance timeline from local data without any HTTP calls.

## Current State

Dashboard data is managed through:
- `frontend/lib/features/dashboard/presentation/dashboard_providers.dart` — `dashboardSummaryProvider`, `dashboardProjectsProvider`, `dashboardFinanceProvider`.
- These providers currently call `dioProvider` directly (no repository abstraction) to fetch from `GET /dashboard/summary`, `GET /dashboard/projects`, `GET /dashboard/finance`.
- The providers currently return static mock data as a temporary measure.

Dashboard data models:
- `DashboardSummary`: `activeProjects` (int), `completedProjects` (int), `totalClients` (int), `outstandingBalances` (Decimal), `totalPayments` (Decimal), `totalExpenses` (Decimal).
- `ProjectOverview`: `projectId`, `name`, `clientName`, `status`, `budget` (Decimal), `paymentsSum` (Decimal), `expensesSum` (Decimal), `balance` (Decimal).
- `MonthlyPoint`: `month` (String), `income` (Decimal), `expense` (Decimal).
- `FinanceOverview`: `months` (List<MonthlyPoint>).

Backend formulas (from `backend/app/repositories/dashboard_repository.py`):
- `active_projects` = count of projects where `status = 'active'`.
- `completed_projects` = count of projects where `status = 'completed'`.
- `total_clients` = count of all clients.
- `outstanding_balances` = sum of project balances (balance = payments_sum - expenses_sum).
- `total_payments` = sum of all payment amounts.
- `total_expenses` = sum of all expense amounts.
- `projects_overview` = join projects + clients, outer-join payments and expenses, group by project.
- `finance_overview` = monthly cash flow using `date_trunc('month', ...)` for last 12 months, padding missing months with zeros.

## Target State

- A `DashboardQueryService` that computes all dashboard metrics from local SQLite data.
- Dashboard providers use the local query service instead of Dio.
- No HTTP calls for dashboard data.
- Aggregation safety: prevent payment/expense row multiplication in joins.
- Archived clients: decide whether to include in `total_clients` count (Decision Required).

## Scope

- Local dashboard query service.
- Summary metrics computation.
- Project overview computation.
- Finance timeline computation.
- Provider migration.
- Aggregation safety.

## Out of Scope

- Reports (Phase 09).
- Backup and restore (Phase 11).
- Removal of Dio provider (Phase 12).

## Prerequisites

- Phases 03–07 (all entity local storage) must be completed.
- ADR-007 (Dashboard and reports are derived queries, not stored tables) must be Accepted.

## Relevant Current Files

- `frontend/lib/features/dashboard/presentation/dashboard_providers.dart`
- `frontend/lib/features/dashboard/presentation/dashboard_screen.dart`
- `backend/app/repositories/dashboard_repository.py` — Reference for query logic.
- `backend/app/schemas/dashboard.py` — Reference for response models.

## Expected New Files

- `frontend/lib/features/dashboard/domain/dashboard_query_service.dart` (proposed)
- `frontend/lib/features/dashboard/data/local_dashboard_repository.dart` (proposed)

## Data Model Impact

No new tables. Dashboard data is derived from existing local tables (clients, projects, payments, expenses).

## Repository and Provider Impact

```
DashboardScreen
→ dashboardSummaryProvider / dashboardProjectsProvider / dashboardFinanceProvider
→ DashboardQueryService
→ DAOs (ClientDao, ProjectDao, PaymentDao, ExpenseDao)
→ AppDatabase
→ SQLite
```

## Implementation Tasks

- [x] Define `DashboardQueryService` class.
- [x] Implement `getSummary()` — count active/completed projects, count clients, sum payments, sum expenses, compute outstanding balances.
- [x] Implement `getProjectsOverview()` — join projects + clients, compute per-project payment/expense sums and balance.
- [x] Implement `getFinanceOverview()` — monthly cash flow for last 12 months, padding missing months with zeros.
- [x] Ensure aggregation queries do not multiply payment/expense rows (use subqueries or separate aggregation).
- [x] Migrate `dashboardSummaryProvider` to use `DashboardQueryService`.
- [x] Migrate `dashboardProjectsProvider` to use `DashboardQueryService`.
- [x] Migrate `dashboardFinanceProvider` to use `DashboardQueryService`.
- [x] Remove static mock data from providers.
- [x] Write unit tests for dashboard query service.
- [x] Write tests verifying aggregation correctness (no row multiplication).
- [x] Write tests with known data sets and expected values.
- [x] Run `flutter analyze`.
- [x] Verify dashboard screen renders correctly with local data.

## Validation Plan

- Static analysis: `flutter analyze`.
- Unit tests: Summary metrics, project overview, finance timeline.
- Aggregation safety: Insert multiple payments and expenses per project, verify sums are correct (not multiplied).
- Persistence after restart: Data persists, dashboard computes from persisted data.
- Offline behavior: Dashboard loads with no network.
- Regression checks: Dashboard screen displays correct KPIs, project table, and finance chart.

## Acceptance Criteria

1. Dashboard summary metrics are computed correctly from local data.
2. Project overview shows correct budget, payments sum, expenses sum, and balance per project.
3. Finance timeline shows 12 months with correct income and expense per month.
4. No row multiplication in aggregation queries.
5. No HTTP calls for dashboard data.
6. `flutter analyze` reports zero errors.
7. All dashboard tests pass.
8. Dashboard screen renders correctly.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-013: Dashboard aggregation duplication (row multiplication). Mitigated by subquery-based aggregation.
- R-008: Financial precision loss in sums. Mitigated by TEXT-based Decimal arithmetic.

## Rollback Strategy

1. Revert dashboard providers to use Dio (or static mock data).
2. Delete `DashboardQueryService` and local dashboard repository.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 08 status.
- `frontend/HISTORY.md` — Add entry for dashboard local queries.
- `docs/history.md` — Add entry for dashboard local queries.

## Completion Record

- Completion date: 2026-07-26
- Commands executed: exact analyzer, focused Phase 03–08/database/contract suites, full Flutter suite, and FastAPI baseline.
- Tests passed: Dashboard 18; Clients 36; Projects 30; Milestones 30; Payments 35; Expenses 40; database 75; contract 49; full Flutter 316; FastAPI baseline 17.
- Analyzer result: `flutter analyze --no-pub` exited 0 with `No issues found!` in 3.1 seconds.
- Files created: Dashboard domain models/interface, local/API adapters, Dashboard DAO, and Phase 08 tests.
- Files modified: Dashboard providers/screen, mutation providers, and migration documentation.
- Remaining issues: None for Phase 08. Phase 09 is Ready and has not started.
- Git commit: Not created by agent

## Implementation notes — 2026-07-26

- Active path: `DashboardScreen -> Riverpod -> DashboardRepositoryInterface -> LocalDashboardRepository -> DashboardDao -> Drift/SQLite`.
- `ApiDashboardRepository` preserves the FastAPI endpoints but is not the runtime default.
- Archived clients and soft-deleted financial rows are excluded. Payments minus expenses is named net cash flow.
- Payment and expense aggregates are joined only after separate grouping, preventing Cartesian multiplication.
- Milestone progress is an integer 0–100 percentage. The deterministic timeline is chronological and zero-fills every requested month.
- Dashboard results remain derived; no table was added and no activity was fabricated.
- Financial cards wrap on narrow layouts and use locale-formatted integer YER.
- Feature mutation action layers invalidate Dashboard providers.
- Phase is **Completed** after successful validation.

## Validation continuation — 2026-07-26

- Previous timeout root cause: the sandbox user could read the Flutter SDK but
  could not open `C:\src\flutter\bin\cache\lockfile` for writing. Running the
  Flutter commands with approved SDK access resolved the apparent hang.
- `flutter pub get` completed successfully in 9.6 seconds. Generated Drift
  inputs were unchanged, so build_runner regeneration was not required.
- Phase 08 Dart files were formatted successfully.
- `flutter analyze --no-pub` completed in 63.4 seconds with exit code 1:
  no compile errors, but 63 pre-existing warning/info diagnostics across
  Phases 02–07, shared UI, tests, and Reports. After the Dashboard unused import
  was corrected it reports 62 diagnostics. The supplementary non-fatal run
  exited 0, confirming no compilation errors, but it does not satisfy the
  mandatory analyzer criterion.
- Focused Dashboard data tests: 5 passed.
- Responsive Dashboard matrix: 13 passed, covering 320×640, 390×844, 600×900,
  800×1280, and 1440×900 in LTR and RTL, plus empty/loading/local-error states.
- Corrected verified overflows in the net-cash-flow header, project-overview
  header, and quick-action cards. Static trend claims and the incorrect SAR
  display currency were removed from active Dashboard cards.
- Feature regression results: Clients 36, Projects 30, Milestones 30,
  Payments 35, Expenses 40, database 75, and contract 49; all passed.
- Full Flutter suite: 316 passed in 30 seconds, exit code 0.
- FastAPI baseline: 17 passed in 9.44 seconds, exit code 0.
- Active provider test proves `dashboardRepositoryProvider` resolves to
  `LocalDashboardRepository`; Dio exists only in the preserved API adapter.
- Mutation provider inspection confirms all Client, Project, Milestone,
  Payment, and Expense action paths call `invalidateDashboard`.
- Analyzer closure removed 62 repository-wide diagnostics without suppressions:
  unused imports/code, deprecated Flutter APIs, async context usage, redundant
  null assertions, style/const findings, and test-only findings.
- Reports changes were analysis-only (unused import removal, deprecated
  `value` replacement, and required braces); no Reports provider migration,
  formula, data source, or behavior changed.
- `flutter analyze --no-pub` now exits 0 with no findings. All focused suites,
  the 316-test full Flutter suite, and the 17-test FastAPI baseline pass.
- Phase 08 is **Completed**. Phase 09 is **Ready**, not In Progress.
