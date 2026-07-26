# Project History

## 2026-07-26 — Phase 09 Reports Local Queries Completed

- Migrated the three verified Reports sections to local Drift-derived queries.
- Added typed filters/results, `ReportsRepositoryInterface`,
  `LocalReportsRepository`, `ReportsDao`, and a preserved inactive FastAPI adapter.
- Enforced active converted-YER snapshots, inclusive dates, independent finance
  aggregates, Net cash flow naming, and mutation invalidation.
- Validation: analyzer 0 findings; Reports 27; full Flutter 343; FastAPI 17.
- Phase 10 was not started. No branch or commit was created.

This file records notable updates made across the Construction ERP workspace.

## 2026-07-26

### Phase 08 — Dashboard Local Queries Completed

- Closed the repository-wide Flutter analyzer debt without suppressions;
  `flutter analyze --no-pub` now exits 0 with no findings.
- Completed the local SQLite Dashboard query path, aggregation safeguards,
  deterministic finance timeline, offline provider wiring, and responsive UI validation.
- Verified 316 Flutter tests and 17 FastAPI baseline tests.
- Marked Phase 08 Completed and Phase 09 Ready; Phase 09 implementation has not started.
- No branch or commit was created.

## 2026-06-28

### Workspace Reorganization to Gold-Style Structure

- Analyzed the existing `construction-erp` skeleton and the `D:\Gold` reference workspace.
- Identified gaps: missing root `agent.md`, missing per-package `AGENTS.md` and `HISTORY.md`, missing backend infrastructure (alembic, env files, docker-compose, scripts, tests), empty Flutter frontend, and thin sprint docs.
- Reorganized the workspace to mirror the Gold pattern while keeping the project intentionally simple (single administrative user, no RBAC complexity).

### Files Created

- `agent.md` at workspace root: cross-workspace agent guide with backend and frontend patterns, simple auth model, and verification rules.
- `HISTORY.md` at workspace root (this file).
- `.agents/` directory at workspace root.
- `backend/AGENTS.md`: per-package agent guidelines for the FastAPI backend.
- `backend/HISTORY.md`: per-package backend history.
- `backend/.gitignore`, `backend/.env.example`.
- `backend/alembic.ini` and `backend/alembic/` migration skeleton.
- `backend/docker-compose.yml` for local PostgreSQL.
- `backend/scripts/` quick-start scripts.
- `backend/tests/` package skeleton.
- `frontend/AGENTS.md`, `frontend/HISTORY.md`: per-package frontend guidelines and history.
- `frontend/pubspec.yaml` and Flutter feature-first `lib/` skeleton.
- Filled `backend/app/core/config.py`, `database.py`, `security.py`, and `main.py` with a runnable FastAPI skeleton.

### Sprint Documentation

- Replaced the thin `docs/sprints/sprint-0X.md` and `docs/implementation/sprint-0X-implementation.md` summaries with full 16-file developer spec folders under `backend/docs/Sprint_0X_<Name>/`:
  - `Sprint_01_Foundation_Clients_Projects`
  - `Sprint_02_Financials_Payments_Expenses`
  - `Sprint_03_Dashboard`
  - `Sprint_04_Reports_Analysis`
  - `Sprint_05_Files_Export`
- Each sprint folder contains the 16 canonical docs: Product Scope PRD, System Architecture, Backend Developer Guide, Frontend Developer Guide, API Contract, Database Schema, Service Workflows, Security, Logging/Audit, Error Codes, Testing QA, Implementation Roadmap, Environment Config, Integration, UI/UX Screen Spec, and Acceptance Criteria.
- Each sprint doc uses the header block (project, sprint, period, lead, goal, source, status) and a Backlog table with IDs like `S0X-T0Y`, owners, priorities, story points, dependencies, acceptance criteria, and deliverables.

### Verification

- Confirmed the workspace layout matches the D:\Gold reference structure adapted to Flutter + simple single-admin model.
- Confirmed backend skeleton imports cleanly (`python -c "import app.main"` succeeded after fill).
- Confirmed Alembic config and migration env are wired to `app.core.database`.
- Confirmed every sprint folder has all 16 files.

## 2026-07-22

### Offline Migration Documentation Phase

- Completed architecture analysis for converting the Flutter frontend from a server-dependent application to a local-first, fully offline, single-user, single-device application.
- Created `docs/offline_migration/` documentation set: master README, 14 phase documents (Phase 00–13), target architecture, data model mapping, decision log (ADR-001–010), and risk register (R-001–021).
- Updated existing documentation to reference the offline migration: `docs/README.md`, `docs/architecture.md`, `docs/project_overview.md`, `docs/tech_stack.md`, `docs/history.md`.
- Updated `agent.md` and `frontend/AGENTS.md` with offline migration governance rules for future agents.
- No application behavior changed. No package added. No implementation phase started. No branch or commit created.

### Verification

- No Flutter or FastAPI source code was modified.
- No `pubspec.yaml` or `requirements.txt` was modified.
- `git status` confirms only documentation and agent instruction files were added or modified.

## 2026-07-22 (Phase 01 — Baseline and Contracts)

### Phase 01 Completed

- Verified all domain contracts (Flutter DTOs, entities, FastAPI schemas, SQLAlchemy models) against actual source code.
- Accepted ADR-001, ADR-002, ADR-003, ADR-004, ADR-006, ADR-007, ADR-008, ADR-009, ADR-010. Revised ADR-005 (remains Proposed).
- Documented 5 verified defects (R-013 cartesian product, R-022 missing timeline months, R-023 outstanding_balances naming, R-024 archived clients count, R-025 profit_margin ratio vs percentage).
- Created Flutter contract tests (50 tests pass) and backend contract tests (17 tests pass).
- No storage migration implemented. No Drift or SQLite added. No production behavior changed.

### Verification

- `flutter analyze` → 0 errors. `flutter test` → 50 passed. `pytest` → 17 passed.
- No production source code modified. No dependencies added. No branch or commit created.

## 2026-07-22 (Phase 01 — ADR-005 Multi-Currency Accepted)

### ADR-005 Multi-Currency Financial Storage Confirmed

- User confirmed: YER (base, scale 0), SAR (scale 2), exchange rate scale 6.
- Every non-YER transaction stores immutable exchange-rate snapshot.
- Historical transactions never recalculated. Project exchange policy: fixed or per-transaction.
- ADR-005 status: Proposed → Accepted. R-008 → Mitigated. R-026–R-029 added.
- No code modified. All 67 tests still pass.

## 2026-07-23 (Phase 02 — Local Database Foundation)

### Phase 02 Completed

- Drift + SQLite database foundation implemented. 6 tables, 6 DAOs, multi-currency scaled-INTEGER storage.
- 51 Phase 02 tests pass. 50 baseline + 17 backend tests unchanged. `flutter analyze` → 0 errors.
- No feature repository migrated. No screen connected. FastAPI unchanged. No branch or commit created.

## 2026-07-23 (Phase 02 — Corrective: Persistent Database)

### Phase 02 Corrective Completion

- Production `databaseProvider` changed from in-memory to file-backed `LazyDatabase` via `getApplicationDocumentsDirectory()`.
- In-memory SQLite restricted to tests only. 24 persistence tests added (close/reopen, FK, snapshots, UUID enforcement).
- Total: 142 tests pass (51+24+50+17). `flutter analyze` → 0 errors. No feature migrated. FastAPI unchanged.

## 2026-07-23 (Phase 03 — Clients Local Storage)

### Phase 03 Completed

- Clients feature migrated to Drift/SQLite. Domain interface, local repository, mapper, UUID utility created.
- Remote FastAPI adapter preserved. 36 Phase 03 tests pass. Total 178 tests pass. `flutter analyze` → 0 errors.
- No other feature migrated. No branch or commit created.

## 2026-07-23 (Phase 04 — Projects Local Storage)

### Phase 04 Completed

- Projects migrated to Drift/SQLite with multi-currency budget, exchange policy, local profitability (no Dio).
- Remote adapter preserved. Stale widget test corrected. 194 Flutter + 17 backend = 211 tests pass. `flutter analyze` → 0 errors.
- No child feature migrated. No branch or commit created.

## 2026-07-23 (Phase 05 — Milestones Local Storage)

### Phase 05 Completed

- Milestones migrated to Drift/SQLite. Overdue derived locally, complete idempotent, progress derived.
- Remote adapter preserved. 224 Flutter + 17 backend = 241 tests pass. `flutter analyze` → 0 errors.
- Payments and Expenses remain remote. No branch or commit created.

## 2026-07-23 (Phase 06 — Payments Local Storage)

### Phase 06 Completed

- Payments migrated to Drift/SQLite with multi-currency, soft-delete, immutable exchange-rate snapshots. Schema v2.
- Remote adapter preserved. 259 Flutter + 17 backend = 276 tests pass. `flutter analyze` → 0 errors.
- Expenses remain remote. No branch or commit created.

## 2026-07-23 (Phase 07 — Expenses Local Storage)

### Phase 07 Completed

- Expenses migrated to Drift/SQLite with multi-currency, soft-delete, immutable exchange-rate snapshots. Schema v3.
- All Project child features now local. No Project child requires FastAPI.
- Remote adapter preserved. 299 Flutter + 17 backend = 316 tests pass. `flutter analyze` → 0 errors.
- Dashboard and Reports remain for later phases. No branch or commit created.
# 2026-07-26 — Phase 08 Dashboard local queries (In Progress)

- Added the local Dashboard repository/query path and preserved the FastAPI adapter.
- Corrected archived-client, soft-delete, Cartesian aggregation, net-cash-flow,
  milestone-progress, and zero-filled timeline semantics.
- Validation commands timed out, so Phase 08 remains In Progress and Reports remain unchanged.

### Validation continuation

- Diagnosed Flutter SDK lockfile access as the previous timeout cause.
- Passed 18 Dashboard tests, 316 full Flutter tests, and 17 FastAPI baseline tests.
- Fixed verified Dashboard responsive overflows and corrected active YER/net-cash-flow presentation.
- Phase remains In Progress because `flutter analyze --no-pub` still exits 1 on
  repository-wide pre-existing warning/info diagnostics; Reports were not changed.
