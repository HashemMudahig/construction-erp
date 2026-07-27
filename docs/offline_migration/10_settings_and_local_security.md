# Phase 10 — Settings and Local Security

## Status

- Status: Completed
- Owner: Codex
- Created: 2026-07-22
- Last updated: 2026-07-26
- Implementation started: 2026-07-26
- Implementation completed: 2026-07-26

## Objective

Persist the settings that are verified by the existing product contracts and
remove active server-authentication state from the local application shell.
Settings must work entirely through the local repository/DAO/SQLite path.

## Implemented scope

- Canonical singleton `app_settings` row (`id = "app"`).
- Default SAR→YER rate stored as an exact scale-6 SQLite INTEGER.
- Locale stored as `en` or `ar`.
- Idempotent initialization with a 410.000000 default rate and `en` locale.
- Non-destructive schema migration from version 3 to version 4.
- Settings repository interface, local implementation, Riverpod state, and
  responsive RTL/LTR settings UI.
- Default rate is used only for newly created SAR payments/expenses when no
  project-fixed or manually supplied rate exists.
- Existing transaction snapshots are never recalculated.
- Local shell no longer watches JWT/auth session state and does not present
  login/logout claims.

## Explicitly out of scope

- PIN, password, biometric authentication, encryption, and lock timeout.
  None had a verified product contract, so the UI truthfully states that no
  additional in-app lock is configured.
- Backup/restore (Phase 11).
- Global removal of API/auth/remote-adapter source (Phase 12).
- Backend or Alembic changes.
- Theme persistence; no verified theme control existed.

## Runtime flow

```text
SettingsScreen
→ settingsProvider / localeProvider
→ SettingsRepositoryInterface
→ LocalSettingsRepository
→ AppSettingsDao
→ Drift / SQLite
```

The local settings path has no Dio, HTTP, JWT, token, or SharedPreferences
dependency. Remote authentication source remains preserved but inactive.

## Data contract

| Field | SQLite representation | Validation | Default |
|---|---|---|---|
| `default_sar_to_yer_rate` | INTEGER, scale 6 | finite decimal, greater than zero, exactly representable | `410000000` (410.000000) |
| `locale_code` | TEXT | `en` or `ar` | `en` |

Unknown or malformed stored values fall back safely without deleting unrelated
settings. Invalid updates are rejected and the last valid published state is
retained.

## Exchange-rate precedence

For a new SAR payment or expense:

1. project fixed rate;
2. explicitly entered per-transaction rate;
3. local default rate.

YER transactions keep identity conversion. Changing the default affects only
future transactions and never mutates stored financial history.

## Validation completed

- `flutter pub get`: exit 0 (5.9s).
- `flutter analyze --no-pub`: exit 0, zero issues (7.8s final run).
- `flutter test test/features/settings --no-pub --concurrency=1 -r expanded`:
  exit 0, 27 passed (8.1s final run).
- Dashboard 18, Reports 27, Clients 36, Projects 30, Milestones 30,
  Payments 35, and Expenses 40 tests passed.
- Database: 75 passed (6.1s); contract: 49 passed (4.1s).
- Full Flutter: 370 passed (27.9s).
- FastAPI baseline: 17 passed (8.7s command time), without backend changes.
- `dart run build_runner build --delete-conflicting-outputs`: exit 0
  (26.3s command time); no generated file required a tracked change.
- Persistence across database reopen and v3→v4 migration are covered.
- Settings screen is covered across ten phone/tablet/desktop RTL/LTR viewports,
  including loading, local error, validation, and save states.

## Acceptance criteria

- [x] No server login is required by the local application shell.
- [x] Verified settings persist locally across restarts.
- [x] Settings are accessible and functional offline.
- [x] Invalid values do not replace valid published state.
- [x] Financial history is immutable when the default rate changes.
- [x] Analyzer and all required tests pass.

## Risks and boundaries

- Uninstalling or clearing application data still removes local settings and
  business data. Backup/restore remains Phase 11 and was not started.
- Device-level access control is the only security boundary in this phase.
- Preserved remote auth/token code must not be interpreted as active local
  runtime behavior.

## Completion record

- Completion date: 2026-07-26
- Database schema: version 4
- New feature files: settings domain, repository, providers, screen, and tests
- Backend changes: none
- Router changes: none
- Backup/restore changes: none
- Git branch/commit created by Codex: none
- Next phase: Phase 11 is Ready; it was not started
