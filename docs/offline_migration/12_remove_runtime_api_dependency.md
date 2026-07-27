# Phase 12 — Remove Runtime API Dependency

## Status

- Status: Completed
- Owner: Codex
- Created: 2026-07-22
- Last updated: 2026-07-26
- Implementation started: 2026-07-26
- Implementation completed: 2026-07-26

## Objective and final architecture

The production Flutter package is now:

```text
Flutter UI → Riverpod → local repositories → Drift DAOs → SQLite
```

It contains no Dio client, HTTP endpoint configuration, JWT/authentication
runtime, authorization interceptor, token persistence, login route, or remote
business repository. The separately preserved FastAPI backend is not consumed
by Flutter and was not modified.

## Initial inventory and classification

| Inventory | Classification | Resolution |
|---|---|---|
| Dio provider, app config, endpoints | Remote-only obsolete frontend | Removed |
| Auth repository/entity/provider/login UI | Remote-only obsolete frontend | Removed |
| Remote feature repositories | Remote-only obsolete frontend | Removed |
| Five HTTP DTO modules | Historical test-contract value | Moved from `lib/` to test fixtures |
| Domain models and repository interfaces | Required local domain code | Retained |
| Local repositories, DAOs, Drift database | Active local runtime | Retained |
| Settings and Backup/Restore | Active local runtime | Retained |
| Archive, crypto, file selector, Drift/SQLite/path | Required local dependencies | Retained |
| FastAPI and Alembic | Separate preserved backend | Untouched |

Complete call-site inspection found no unresolved item and no local form or
mapper depending on an HTTP DTO.

## Removal record

- Removed Dio configuration/interceptors/network exceptions, base URL,
  endpoints, and the `dio` dependency.
- Removed auth/session/user/login/logout/token runtime. No replacement password,
  PIN, biometric, encryption, or fake authentication was introduced.
- Removed remote adapters for Clients, Projects, Milestones, Payments, Expenses,
  Dashboard, and Reports.
- Removed `shared_preferences`; it had no verified non-auth production owner.
- Retained all local, exact-finance, localization, and Backup/Restore packages.

Git history archives deleted adapters. Historical DTO contract fixtures live
only under `test/` and are not shipped.

## Startup, errors, and security

The production router was not changed. Startup opens Dashboard directly with no
login flash, auth loading, token read, or background request. AppShell has no
user/session/logout placeholder. Active UI uses local validation, database, and
file/backup error models rather than HTTP/auth/network messages.

Security copy truthfully relies on device/OS access protection and claims no
app PIN, biometric protection, database encryption, or mandatory login.

## Backup/Restore regression

Phase 11 remains intact: `.cerpbackup` snapshot creation, manifest and SHA-256
validation, staging migration, rollback, provider recreation, and responsive
UI pass. Backups contain no password, token, or credential. `archive`, `crypto`,
and `file_selector` remain. Schema remains version 4.

## Architecture enforcement

`test/architecture/phase12_runtime_architecture_test.dart` verifies no
production network/auth source or dependency, no remote repositories, direct
Dashboard startup, local-only repository ownership, no credential settings,
backup isolation, required package retention, and schema-v4 offline opening.
Old remote-compilation assertions were removed; meaningful JSON contract tests
use test-only fixtures.

## Validation

From `frontend/`:

- `flutter clean`: exit 0, 2.9s.
- `flutter pub get`: exit 0, 3.4s.
- `flutter analyze --no-pub`: exit 0, 5.2s, no issues.
- Architecture: 10 passed.
- Backup 42; Settings 27; Dashboard 18; Reports 27.
- Clients 36; Projects 30; Milestones 30; Payments 35; Expenses 40.
- Database 75; contracts 49.
- Full Flutter: 422 passed, exit 0, 33.2s.
- `flutter build apk --debug --no-pub`: exit 0, 92.2s; APK produced.

From `backend/`:

- `python -m pytest tests/test_baseline_contracts.py -v`: exit 0, 8.7s;
  17 passed with three non-failing environment/deprecation warnings.

## Completion record

- Acceptance criteria: Passed.
- Production router: Unchanged.
- Backend production/Alembic: Unchanged.
- Branch/commit created: No.
- Phase 13 started: No.
- Phase 13 carry-over: abandoned `.pre_restore`/`.incoming` startup recovery,
  release-platform and installation/upgrade validation, and production
  data-lifecycle checks.
