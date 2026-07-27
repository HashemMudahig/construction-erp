# Project History

## 2026-07-26 — Phase 13 Release Validation

- Added safe startup recovery before database/provider exposure.
- Release manifest has no network or broad storage permission.
- Release APK/AAB and 435 Flutter tests passed; FastAPI baseline 17 passed.
- Final status: technically validated with signing and device steps remaining.

## 2026-07-26 — Phase 12 Runtime API/Auth Removal

- Finalized UI → Riverpod → local repositories → Drift → SQLite, with no Dio,
  FastAPI, JWT, auth/session, or remote adapter runtime.
- Kept backend production, Backup/Restore, schema v4, and router unchanged.
- Validation: 422 Flutter tests, clean analyzer, Android debug APK, and 17
  FastAPI baseline tests.
- Phase 13 remains Ready and was not started.

## 2026-07-26 — Phase 11 Backup and Restore

- Implemented portable full-database backup using a consistent SQLite snapshot,
  strict format-v1 manifest, SHA-256, archive path/size safeguards, and system
  file selection.
- Restore is a validated replacement, not a merge: staging migrations and
  integrity/FK/count checks complete before active data is touched.
- Active database replacement retains rollback until the recreated provider
  and restored database pass final validation.
- Backup is offline and unencrypted, contains no credentials, and does not
  claim unsupported attachment coverage. Phase 12 was not started.
- Validation: analyzer clean; Backup/Restore 42; full Flutter 412; FastAPI 17.

## 2026-07-26 — Phase 10 Settings and Local Security

- Completed the verified local settings contract: default SAR→YER rate and
  `en`/`ar` locale in the canonical SQLite settings row.
- Added safe defaults, validation, persistence/reopen and v3→v4 migration
  coverage, plus responsive local settings UI.
- New SAR transactions use project-fixed, manual, then local-default rate
  precedence; prior records remain unchanged.
- The local shell has no active JWT/auth-session dependency. Remote auth source
  remains preserved for a future adapter.
- Validation: analyzer clean; Settings 27; full Flutter 370; FastAPI 17.
- Phase 11 is Ready and was not started.

## 2026-07-26 — Phase 09 Reports Local Queries

- Completed local Project Status, Financial Summary, and Expense Analysis reports.
- Reports no longer require FastAPI or JWT; the remote adapter remains preserved.
- Historical converted-YER snapshots, soft-delete exclusion, inclusive dates,
  local Project/status filters, and safe separate aggregation are verified.
- Net cash flow terminology replaces misleading generic net/balance labels.
- Validation: Reports 27, full Flutter 343, FastAPI baseline 17, analyzer clean.
- Phase 10 remains Ready and was not started.

## 2026-07-26 — Phase 08 Dashboard Local Queries

- Completed the Dashboard migration to derived local Drift/SQLite queries with
  no active HTTP dependency.
- Verified summary, per-project aggregation, 12-month zero filling, offline
  provider resolution, mutation invalidation, and responsive LTR/RTL states.
- Closed 62 analyzer diagnostics without ignores or suppressions.
- Validation: analyzer 0 findings; focused suites all pass; full Flutter 316
  passed; FastAPI baseline 17 passed.
- Phase 08 is Completed. Phase 09 is Ready and has not started.

## Why the project started
The Construction ERP began as a need to replace fragmented spreadsheets, manual reporting, and scattered client/project tracking used by small construction companies.

## Initial idea
Build a modern ERP that centralizes clients, project delivery, finance, and reporting in a single platform with real-time visibility.

## Decisions made
- Backend-first implementation to establish stable data models and APIs.
- Feature-first architecture to build modules incrementally and keep scope manageable.
- Clean architecture to enforce separation between domain rules, data access, and presentation.
- Intentionally simple v1: a single administrative user, no multi-tenant or RBAC complexity.
- Money and budget values use `Decimal`/`Numeric`. Never `float`.
- Alembic migrations are the source of truth for schema; never hand-edit production tables.

## Sprint philosophy
Organize work into focused five-sprint iterations that deliver core modules first, then add reporting, exports, and polish. Each sprint has a 16-file developer specification folder under `backend/docs/Sprint_XX_<Name>/` with clear goals, API contracts, backlog tables, and completion criteria.

## Sprint summary
| Sprint | Name | Period | Goal |
| --- | --- | --- | --- |
| S01 | Foundation, Clients & Projects | 2026-07-06 to 2026-07-17 | FastAPI skeleton, PostgreSQL, JWT auth, client + project CRUD + Flutter screens |
| S02 | Financials — Payments, Expenses & Milestones | 2026-07-20 to 2026-07-31 | Milestone/payment/expense CRUD + project profitability service + Flutter screens |
| S03 | Dashboard | 2026-08-03 to 2026-08-14 | KPI summary cards, projects overview, monthly finance charts |
| S04 | Reports & Analysis | 2026-08-17 to 2026-08-28 | Project status, financial summary, expense analysis reports with filters |
| S05 | Files & Export | 2026-08-31 to 2026-09-11 | Project file attachments, CSV report export, PDF-ready project summary |

## 2026-06-28

### Workspace Reorganization

- Reorganized the workspace to mirror the D:\Gold reference structure.
- Created root `agent.md`, `HISTORY.md`, `.agents/`.
- Created per-package `AGENTS.md` and `HISTORY.md` for backend and frontend.
- Added backend infrastructure: `alembic.ini`, `alembic/`, `.env.example`, `.gitignore`, `docker-compose.yml`, `scripts/`, `tests/`.
- Filled the FastAPI skeleton: `core/config.py`, `database.py`, `security.py`, `response.py`, runnable `main.py` with health endpoints.
- Added Flutter feature-first `lib/` skeleton with `pubspec.yaml`, Dio provider, GoRouter, endpoints constants, theme, and feature folders for all 8 features.
- Wrote 80 developer spec files: 16-file folders for all 5 sprints under `backend/docs/Sprint_0X_<Name>/`.
- Retired the thin `docs/sprints/` and `docs/implementation/` summaries into `docs/archive/` since the 16-file sprint folders supersede them.

### Verification

- `python -c "import app.main"` succeeds.
- `pytest tests/test_health.py` passes (2 tests).
- Each sprint folder contains exactly 16 markdown files.

## 2026-07-22

### Offline Migration Documentation

- Completed architecture analysis for converting the Flutter frontend from a server-dependent application to a local-first, fully offline, single-user, single-device application.
- Created `docs/offline_migration/` documentation set with 14 phase documents (Phase 00 through Phase 13), a master README, target architecture document, data model mapping, decision log (ADR-001 through ADR-010), and risk register (R-001 through R-021).
- No application behavior changed. No package added. No implementation phase started.
- Updated existing documentation (`docs/README.md`, `docs/architecture.md`, `docs/project_overview.md`, `docs/tech_stack.md`) to reference the offline migration plan.
- Updated `agent.md` and `frontend/AGENTS.md` with offline migration governance rules for future agents.
- All implementation phases remain unstarted. All ADRs remain in `Proposed` status pending user confirmation.

### Verification

- No Flutter or FastAPI source code was modified.
- No `pubspec.yaml` or `requirements.txt` was modified.
- No branch or commit was created.

## 2026-07-22 (Phase 01 — ADR-005 Multi-Currency Accepted)

### ADR-005 Multi-Currency Financial Storage Confirmed

- User confirmed multi-currency requirements: YER (base, scale 0) and SAR (scale 2).
- Exchange rates stored as scaled INTEGER (scale 6). Default rate in settings.
- Every non-YER transaction stores immutable exchange-rate snapshot (original amount, original currency, applied rate, converted YER amount, rate source, rate date).
- Historical transactions never recalculated when default rate changes.
- Project exchange policy: fixed_rate or per_transaction.
- Mixed-currency expenses: multiple linked expense lines.
- Reports: original currency totals + unified YER totals.
- ADR-005 status changed from Proposed to Accepted.
- Updated `decision_log.md`, `data_model_mapping.md`, `risk_register.md`, and `README.md` migration principles.
- R-008 status changed to Mitigated. R-026, R-027, R-028, R-029 added to risk register.
- No code was modified. No tests were changed. All 67 tests still pass (50 Flutter + 17 backend).

## 2026-07-22 (Phase 01 — Baseline and Contracts)

### Phase 01 Baseline and Contract Verification Completed

- Verified all Flutter DTOs, entities, and their field names, types, and parsing behavior against actual source code.
- Verified all FastAPI Pydantic schemas, SQLAlchemy models, enum values, CHECK constraints, indexes, and foreign keys against actual source code.
- Verified all dashboard and report formulas by reading `dashboard_repository.py`, `report_repository.py`, `dashboard_service.py`, `report_service.py`, and `profitability_service.py`.
- Verified all delete and cascade behaviors.
- Documented verified enum matrix, date/time contracts, financial contracts, and delete/archive matrix in `data_model_mapping.md`.
- Updated ADR statuses: ADR-001, ADR-002, ADR-003, ADR-004, ADR-006, ADR-007, ADR-008, ADR-009, ADR-010 → Accepted. ADR-005 revised and remains Proposed (blocked until currency/scale confirmed).
- Discovered and documented 5 verified defects:
  - R-013: Dashboard `projects_overview()` cartesian product row multiplication (joins Payment + Expense simultaneously).
  - R-022: Finance timeline omits months with zero transactions in both income and expense.
  - R-023: `outstanding_balances` is total net (payments - expenses), not sum of negative balances.
  - R-024: `total_clients` includes archived clients.
  - R-025: `profit_margin` is a ratio (0.50), not a percentage (50.00).
- Created baseline test fixtures with deterministic UUIDs, dates, and monetary values.
- Created Flutter contract tests: `frontend/test/contract/baseline_contracts_test.dart` (50 tests, all pass).
- Created backend contract tests: `backend/tests/test_baseline_contracts.py` (17 tests, all pass).
- No storage migration implemented. No Drift or SQLite dependency added. No production behavior changed.
- Known defects were documented and reproduced in tests, not silently fixed.

### Verification

- `flutter analyze` → 0 errors.
- `flutter test test/contract/baseline_contracts_test.dart` → 50 passed.
- `python -m pytest tests/test_baseline_contracts.py -v` → 17 passed.
- No Flutter or FastAPI production source code was modified.
- No `pubspec.yaml` or `requirements.txt` was modified.
- No branch or commit was created.

## 2026-07-23 (Phase 02 — Local Database Foundation)

### Phase 02 Completed

- Implemented local SQLite database foundation using Drift ORM.
- Added dependencies: drift, sqlite3_flutter_libs, path_provider, path, drift_dev.
- Created database structure under `frontend/lib/core/database/` with tables, DAOs, finance utilities, and AppDatabase.
- Implemented multi-currency scaled-INTEGER storage (ADR-005): YER scale 0, SAR scale 2, exchange rate scale 6.
- Implemented currency conversion with round-half-up using BigInt arithmetic (no double).
- Created 6 tables: clients, projects, milestones, payments, expenses, app_settings.
- Foreign keys enabled via PRAGMA. Delete: clients→projects RESTRICT, projects→milestones CASCADE, projects→payments RESTRICT, projects→expenses RESTRICT.
- Created 6 DAOs with basic CRUD. Created Riverpod databaseProvider. Schema version 1 with migration foundation.
- Drift code generation successful. Created 51 Phase 02 tests — all pass.
- No feature repository migrated. No screen connected to AppDatabase. FastAPI unchanged.

### Verification

- `flutter analyze` → 0 errors. Phase 02 tests → 51 passed. Baseline Flutter → 50 passed. Baseline backend → 17 passed.
- No branch or commit created.

## 2026-07-23 (Phase 02 — Corrective Completion: Persistent File-Backed Database)

### Phase 02 Correction

- Production `databaseProvider` changed from in-memory `NativeDatabase.memory()` to file-backed `LazyDatabase` using `getApplicationDocumentsDirectory()`.
- In-memory SQLite is now restricted to explicit test construction via `AppDatabase.forTesting()` or direct `NativeDatabase.memory()` in tests only.
- Added `frontend/lib/core/database/finance/snapshot_validation.dart` — YER identity and SAR conversion snapshot validation utilities.
- Added `frontend/test/database/phase02_persistence_test.dart` — 24 persistence tests:
  - Database file created on disk, data persists after close/reopen.
  - Client, Project, AppSettings, Payment snapshot, Expense snapshot all persist.
  - Foreign keys active after reopening. Schema version correct after reopening.
  - Multiple AppDatabase instances on same file succeed.
  - UUID enforcement: Drift enforces min TEXT length at Dart layer (not SQLite).
  - YER identity rate policy: rate=1,000,000, source=identity, converted=original.
  - SAR snapshot validation: correct conversion and error cases.
- Total tests: 51 original Phase 02 + 24 persistence + 50 baseline + 17 backend = 142, all pass.
- No feature repository migrated. No screen connected. FastAPI unchanged.

## 2026-07-23 (Phase 03 — Clients Local Storage)

### Phase 03 Completed

- Migrated Clients feature from Dio/FastAPI runtime to Drift/SQLite local database.
- Created `ClientRepositoryInterface` in domain layer (abstract, returns entities).
- Created `LocalClientRepository` implementing the interface using `ClientsDao`.
- Preserved remote adapter: `ApiClientRepository` and old `ClientRepository` class remain compiling.
- Created `ClientMapper` for Drift row <-> entity mapping (no DateTime.now() fallback).
- Added `UuidUtil` for local UUID v4 generation and format validation.
- Extended `ClientsDao` with active/archived filtering, case-insensitive search, project count.
- Updated `client_providers.dart` to use `localClientRepositoryProvider` as runtime default.
- Updated `client_form_screen.dart` and `client_detail_screen.dart` to use interface methods.
- Updated `project_form_screen.dart` to use `clientRepositoryProvider` from client_providers.
- Client policies: active by default, archived excluded, archive/restore, hard-delete only when no projects.
- 36 Phase 03 tests pass (UUID, CRUD, search, mapping, persistence, interface compliance).
- Total: 36 + 51 + 24 + 50 + 17 = 178 tests pass. `flutter analyze` → 0 errors.
- No other feature migrated. FastAPI unchanged. Remote adapter preserved.

### Verification

- `flutter analyze` → 0 errors.
- Phase 03 tests → 36 passed. Phase 02 → 51 passed. Persistence → 24 passed. Baseline Flutter → 50 passed. Baseline backend → 17 passed.
- No branch or commit created.

## 2026-07-23 (Phase 04 — Projects Local Storage)

### Phase 04 Completed

- Migrated Projects feature from Dio/FastAPI to Drift/SQLite local database.
- Updated `ProjectEntity` with multi-currency fields. Created `ProjectRepositoryInterface`, `LocalProjectRepository`, `ProjectMapper`.
- Preserved remote adapters: `ApiProjectRepository` and legacy `ProjectRepository` class.
- Extended `ProjectsDao` with search, filters, child counts, YER sum aggregations for local profitability.
- Updated `project_providers.dart`, `project_form_screen.dart`, `project_detail_screen.dart`, `reports_screen.dart`.
- Corrected stale `widget_test.dart` — replaced obsolete login test with router/database verification.
- Local profitability: no Dio, uses Drift SUM queries, avoids Cartesian multiplication, guards zero denominator.
- Transitional child behavior: child tabs use remote providers but local projects show empty state without triggering Dio.
- 30 Phase 04 tests pass. Total: 194 Flutter + 17 backend = 211, all pass. `flutter analyze` → 0 errors.
- No child feature migrated. FastAPI unchanged. Remote adapters preserved.

### Verification

- `flutter test` → 194 passed. `pytest` → 17 passed. `flutter analyze` → 0 errors.
- No branch or commit created.

## 2026-07-23 (Phase 05 — Milestones Local Storage)

### Phase 05 Completed

- Migrated Milestones feature from Dio/FastAPI to Drift/SQLite local database.
- Created `MilestoneRepositoryInterface` in domain layer.
- Created `LocalMilestoneRepository` implementing the interface using `MilestonesDao`.
- Preserved remote adapter: `ApiMilestoneRepository` and legacy `MilestoneRepository` class remain compiling.
- Created `MilestoneMapper` for Drift row <-> entity mapping (no DateTime.now() fallback).
- Updated `MilestoneEntity` with `effectiveStatus(referenceDate)` for overdue derivation.
- Extended `MilestonesDao` with `countByProject` and `countCompletedByProject`.
- Updated `milestone_providers.dart` to use `localMilestoneRepositoryProvider` with auto-invalidation.
- Updated `milestone_form_dialog.dart` to use interface methods.
- Overdue policy: stored status preserved, effective overdue derived at read time using injected reference date.
- Complete operation: idempotent, sets stored status to 'completed'.
- Project progress: derived locally via `countByProject` / `countCompletedByProject`.
- 30 Phase 05 tests pass (CRUD, validation, overdue, progress, persistence, mapping, regression).
- Total: 224 Flutter + 17 backend = 241 tests, all pass. `flutter analyze` → 0 errors.
- Payments and Expenses remain remote (transitional). No child feature migrated beyond Milestones.

### Verification

- `flutter test` → 224 passed. `pytest` → 17 passed. `flutter analyze` → 0 errors.
- No branch or commit created.

## 2026-07-23 (Phase 06 — Payments Local Storage)

### Phase 06 Completed

- Migrated Payments feature from Dio/FastAPI to Drift/SQLite with multi-currency, soft-delete, and immutable exchange-rate snapshots.
- Schema migration: v1 → v2, added `is_deleted` and `deleted_at` columns to payments table (non-destructive, backfilled defaults).
- Created `PaymentRepositoryInterface`, `LocalPaymentRepository`, `ApiPaymentRepository` (preserved), `PaymentMapper`.
- Updated `PaymentEntity` with multi-currency snapshot fields (originalAmountMinor, originalCurrency, exchangeRateScaled, convertedYerAmount, rateSource, rateDate, paymentGroupId, isDeleted, deletedAt).
- Extended `PaymentsDao` with active/soft-delete queries, group operations, financial totals.
- Updated `ProjectsDao.sumPaymentsYer` to exclude soft-deleted payments from financial totals.
- Payment policies: soft-delete (non-destructive), restore, group atomic operations, YER identity rate, SAR exact conversion.
- Exchange-rate snapshot: immutable, changing default or project rate never alters historical payments.
- Updated `payment_providers.dart` with auto-invalidation of payments list and project financial summary.
- Updated `payment_form_dialog.dart` with currency selection, SAR exchange rate input.
- Updated `ProjectDetailScreen` payments tab to use new entity fields.
- 35 Phase 06 tests pass (CRUD, currency, conversion, soft-delete, groups, persistence, mapping, regression).
- Total: 259 Flutter + 17 backend = 276 tests, all pass. `flutter analyze` → 0 errors.
- Expenses remain remote (transitional). FastAPI unchanged. Remote adapter preserved.

### Verification

- `flutter test` → 259 passed. `pytest` → 17 passed. `flutter analyze` → 0 errors.
- No branch or commit created.

## 2026-07-23 (Phase 07 — Expenses Local Storage)

### Phase 07 Completed

- Migrated Expenses feature from Dio/FastAPI to Drift/SQLite with multi-currency, soft-delete, and immutable exchange-rate snapshots.
- Schema migration: v2 → v3, added `is_deleted` and `deleted_at` columns to expenses table (non-destructive, backfilled defaults).
- Created `ExpenseRepositoryInterface`, `LocalExpenseRepository`, `ApiExpenseRepository` (preserved), `ExpenseMapper`.
- Updated `ExpenseEntity` with multi-currency snapshot fields and soft-delete fields.
- Extended `ExpensesDao` with active/soft-delete queries, group operations, financial totals.
- Updated `ProjectsDao.sumExpensesYer` to exclude soft-deleted expenses from financial totals.
- Expense policies: soft-delete (non-destructive), restore, group atomic operations, YER identity rate, SAR exact conversion, category validation.
- Exchange-rate snapshot: immutable, changing default or project rate never alters historical expenses.
- Updated `expense_providers.dart` with auto-invalidation of expenses list and project financial summary.
- Updated `expense_form_dialog.dart` with currency selection, SAR exchange rate input, category dropdown.
- Updated `ProjectDetailScreen` expenses tab to use new entity fields.
- 40 Phase 07 tests pass (CRUD, categories, currency, conversion, soft-delete, groups, persistence, mapping, regression).
- Total: 299 Flutter + 17 backend = 316 tests, all pass. `flutter analyze` → 0 errors.
- No Project child feature requires FastAPI. All child features (Clients, Projects, Milestones, Payments, Expenses) are now local.
- Dashboard and Reports remain for later phases. FastAPI unchanged. Remote adapter preserved.

### Verification

- `flutter test` → 299 passed. `pytest` → 17 passed. `flutter analyze` → 0 errors.
- No branch or commit created.
# 2026-07-26 — Phase 08 Dashboard local queries (In Progress)

- Implemented the scoped local derived Dashboard architecture and corrected metric contracts.
- No Dashboard result table or fabricated activity was introduced.
- Required Flutter validation timed out; completion remains pending.

### Phase 08 validation continuation

- Resolved the timeout diagnosis as Flutter SDK lockfile permission under the
  sandbox, then ran validation with approved SDK access.
- Dashboard focused/responsive tests, all feature regressions, 316 full Flutter
  tests, and 17 FastAPI baselines passed.
- Corrected three production Dashboard overflows and removed static financial
  trend/currency claims.
- Phase remains In Progress because the exact repository-wide analyzer command
  exits 1 on 62 existing warning/info diagnostics despite no compile errors.
