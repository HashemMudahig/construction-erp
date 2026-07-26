# Offline Migration Documentation

> **Status: In progress — Phases 01 through 09 are completed; Phase 10 is ready.**

This documentation set describes the planned migration of the Construction ERP Flutter frontend from a server-dependent architecture (FastAPI + PostgreSQL) to a local-first, fully offline, single-user, single-device application using Drift and SQLite.

The FastAPI backend remains preserved as a possible future remote adapter. No backend source code will be removed or modified during this migration.

---

## Purpose

The Construction ERP currently requires a running FastAPI backend with PostgreSQL to function. The target state is a Flutter application that stores all data locally on the device using SQLite via the Drift ORM, with no runtime network dependency.

## Current Application State

- Flutter frontend communicates with a FastAPI backend over HTTP (Dio).
- Backend persists data in PostgreSQL via SQLAlchemy ORM.
- Authentication uses JWT bearer tokens.
- All CRUD operations (clients, projects, milestones, payments, expenses) and all read operations (dashboard, reports) require network access to the backend.
- The dashboard providers currently use static mock data as a temporary measure, but the architecture still depends on Dio and the backend contract.

## Target Application State

- Flutter frontend stores all data in a local SQLite database via Drift.
- No network connection required at runtime.
- Single user, single device.
- No synchronization in the first local release.
- FastAPI backend source code remains in the repository, preserved and buildable, but is not used at runtime.

## Scope

- **In scope:** Flutter frontend becomes local-first/offline.
- **In scope:** FastAPI backend remains preserved and buildable.
- **In scope:** Single user, single device, no server requirement.
- **Out of scope:** No synchronization in the first local release.
- **Out of scope:** No multi-user or multi-device support.

## Migration Principles

1. Preserve all existing business logic and data contracts.
2. Never store financial values as `double` or SQLite `REAL`. Use scaled INTEGER (ADR-005).
3. Preserve UUID compatibility across local and remote storage.
4. Repository interfaces separate the UI from the data source.
5. Dashboard and reports are derived queries, not stored tables.
6. Foreign keys are mandatory in the local database.
7. Backup and restore is required before client delivery.
8. No server login in local runtime.
9. The FastAPI backend must remain buildable and testable at all times.
10. Multi-currency support: YER (base, scale 0) and SAR (scale 2). Exchange rates stored as scaled INTEGER (scale 6). Every non-YER transaction stores an immutable exchange-rate snapshot. Historical transactions are never recalculated.

## Phase List

| Phase | Document | Status | Dependencies | Implementation started |
|---|---|---|---|---|
| 00 | [Migration Overview](00_migration_overview.md) | Ready | None | No |
| 01 | [Baseline and Contracts](01_baseline_and_contracts.md) | Completed | Phase 00 | Yes |
| 02 | [Local Database Foundation](02_local_database_foundation.md) | Completed | Phase 01 | Yes |
| 03 | [Clients Local Storage](03_clients_local_storage.md) | Completed | Phase 02 | Yes |
| 04 | [Projects Local Storage](04_projects_local_storage.md) | Completed | Phase 03 | Yes |
| 05 | [Milestones Local Storage](05_milestones_local_storage.md) | Completed | Phase 04 | Yes |
| 06 | [Payments Local Storage](06_payments_local_storage.md) | Completed | Phase 04 | Yes |
| 07 | [Expenses Local Storage](07_expenses_local_storage.md) | Completed | Phase 04 | Yes |
| 08 | [Dashboard Local Queries](08_dashboard_local_queries.md) | Completed | Phases 03–07 | Yes |
| 09 | [Reports Local Queries](09_reports_local_queries.md) | Completed | Phases 03–07 | Yes |
| 10 | [Settings and Local Security](10_settings_and_local_security.md) | Ready | Phase 02 | No |
| 11 | [Backup and Restore](11_backup_and_restore.md) | Draft | Phase 02 | No |
| 12 | [Remove Runtime API Dependency](12_remove_runtime_api_dependency.md) | Draft | Phases 03–09 | No |
| 13 | [Offline Release Validation](13_offline_release_validation.md) | Draft | Phase 12 | No |

### Status Values

- **Draft** — Document created, content not yet finalized for implementation.
- **Ready** — Document finalized, ready for implementation.
- **In Progress** — Implementation actively underway.
- **Blocked** — Implementation blocked by an unresolved decision or issue.
- **Completed** — Implementation finished and validated.
- **Superseded** — Document replaced by a newer version.

> Completed phases have passed their documented validation gates. A Ready phase
> has not started implementation.

## Definition of Done

The offline migration is complete when:

1. All 14 phases are implemented and validated.
2. The Flutter application runs fully offline with no HTTP calls at runtime.
3. All CRUD operations (clients, projects, milestones, payments, expenses) work against the local SQLite database.
4. Dashboard and reports are computed from local data.
5. Backup and restore functionality is tested and working.
6. The FastAPI backend remains buildable and its tests pass.
7. The release validation checklist (Phase 13) passes in airplane mode.
8. No financial precision loss is detected in any test.
9. `flutter analyze` reports zero errors.
10. All phase-specific tests pass.

## Rules for Updating Phase Documents

1. Update the `Status` and `Last updated` fields when implementation begins or completes.
2. Mark the `Implementation started` date when work begins.
3. Fill the `Completion record` section when the phase is finished.
4. Never mark a phase as `Completed` if tests or acceptance criteria fail.
5. Update the phase status table in this README after any status change.
6. Record unresolved decisions in `decision_log.md`.

## Rules for Updating History

After every completed phase:

1. Update the relevant phase document with the completion record.
2. Update the status table in this `README.md`.
3. Update the canonical project history file (`docs/history.md`).
4. Update `frontend/HISTORY.md` if the frontend was modified.
5. Do not update `backend/HISTORY.md` unless backend documentation or behavior changed.

## Related Documentation

- [Architecture](../architecture.md) — Current architecture description.
- [Target Architecture](architecture_target.md) — Planned offline architecture.
- [Project Overview](../project_overview.md) — Project purpose and modules.
- [Tech Stack](../tech_stack.md) — Technologies used and planned.
- [Data Model Mapping](data_model_mapping.md) — Field-by-field mapping across all storage layers.
- [Decision Log](decision_log.md) — Architecture Decision Records.
- [Risk Register](risk_register.md) — Identified risks and mitigations.
- [Root agent.md](../../agent.md) — Cross-workspace agent guide.
- [Frontend AGENTS.md](../../frontend/AGENTS.md) — Frontend agent guidelines.
- [Root HISTORY.md](../../HISTORY.md) — Workspace history.
- [Frontend HISTORY.md](../../frontend/HISTORY.md) — Frontend history.
