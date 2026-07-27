# Offline Migration Documentation

> **Status: Phases 00 through 13 are completed. Phase 13 is technically validated with manual distribution steps remaining.**

This documentation tracks the migration of the Construction ERP Flutter
frontend to a local, offline, single-user, single-device application using
Drift and SQLite. The FastAPI backend remains preserved and independently
testable, but the Flutter production runtime no longer consumes it.

## Current architecture

```text
Flutter UI → Riverpod → local repositories → Drift → SQLite
```

Clients, Projects, Milestones, Payments, Expenses, Dashboard, Reports,
Settings, and Backup/Restore work without FastAPI, JWT, login, or internet.
Financial values retain exact scaled-integer rules; Dashboard and Reports are
derived rather than stored.

## Scope and principles

- Flutter is offline and uses local SQLite as its sole business data source.
- FastAPI/PostgreSQL remain separate preserved code, not a runtime dependency.
- No synchronization, cloud backup, multi-user, or multi-device support.
- Repository interfaces isolate presentation from local persistence.
- Foreign keys, UUID compatibility, exact currency snapshots, and immutable
  historical conversions remain mandatory.
- Backup/Restore is required and remains fully local.
- No server login or fake local authentication exists.

## Phase status

| Phase | Document | Status | Started |
|---|---|---|---|
| 00 | [Migration Overview](00_migration_overview.md) | Completed | Yes |
| 01 | [Baseline and Contracts](01_baseline_and_contracts.md) | Completed | Yes |
| 02 | [Local Database Foundation](02_local_database_foundation.md) | Completed | Yes |
| 03 | [Clients Local Storage](03_clients_local_storage.md) | Completed | Yes |
| 04 | [Projects Local Storage](04_projects_local_storage.md) | Completed | Yes |
| 05 | [Milestones Local Storage](05_milestones_local_storage.md) | Completed | Yes |
| 06 | [Payments Local Storage](06_payments_local_storage.md) | Completed | Yes |
| 07 | [Expenses Local Storage](07_expenses_local_storage.md) | Completed | Yes |
| 08 | [Dashboard Local Queries](08_dashboard_local_queries.md) | Completed | Yes |
| 09 | [Reports Local Queries](09_reports_local_queries.md) | Completed | Yes |
| 10 | [Settings and Local Security](10_settings_and_local_security.md) | Completed | Yes |
| 11 | [Backup and Restore](11_backup_and_restore.md) | Completed | Yes |
| 12 | [Remove Runtime API Dependency](12_remove_runtime_api_dependency.md) | Completed | Yes |
| 13 | [Offline Release Validation](13_release_validation.md) | Completed — Technical | Yes |

Completed means implementation and its validation gates passed. Ready means the
phase is documented but implementation has not started.

## Remaining definition of done

Phase 13 must validate release platforms, installation/upgrade behavior,
production data lifecycle, airplane-mode operation, and startup recovery for
abandoned `.pre_restore`/`.incoming` files. Phase 13 has not started.

## Update rules

1. Update phase status only after its acceptance and validation gates pass.
2. Record unresolved decisions and risks in their canonical logs.
3. Update `docs/history.md`, root `HISTORY.md`, and `frontend/HISTORY.md` after
   a completed frontend phase.
4. Do not update backend history unless backend behavior or documentation
   changes.

## Related documentation

- [Target Architecture](architecture_target.md)
- [Data Model Mapping](data_model_mapping.md)
- [Decision Log](decision_log.md)
- [Risk Register](risk_register.md)
- [Root history](../../HISTORY.md)
- [Frontend history](../../frontend/HISTORY.md)
