# Phase 10 — Settings and Local Security

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Remove the server authentication dependency from the local runtime. Implement optional local security (PIN, biometrics) and local settings persistence (language, lock/unlock behavior).

## Current State

- Authentication uses JWT bearer tokens via `frontend/lib/features/auth/presentation/auth_provider.dart`.
- Tokens are stored in `shared_preferences` (keys `erp_token`, `erp_email`).
- The Dio interceptor at `frontend/lib/core/network/dio_provider.dart` injects `Authorization: Bearer <token>` on every request.
- The router at `frontend/lib/core/router/app_router.dart` currently has auth redirect logic removed (login bypassed), but the auth provider and login screen still exist.
- The `settings` feature at `frontend/lib/features/settings/` is scaffolded only (empty `.gitkeep` files, no implementation).
- Language/locale is managed via `localeProvider` referenced in `frontend/lib/main.dart`.

## Target State

- No server login required at runtime.
- Optional local PIN protection (user can enable/disable).
- Optional biometric authentication (if device supports it).
- Local settings persisted in `shared_preferences` or a settings table.
- Language preference persisted locally.
- Lock/unlock behavior when PIN is enabled.
- Secure storage for PIN hash if implemented.
- No JWT token storage or injection in local mode.

## Scope

- Remove server authentication dependency from local runtime.
- Implement optional local PIN.
- Implement optional biometrics.
- Local settings persistence.
- Language persistence.
- Lock/unlock behavior.

## Out of Scope

- Multi-user authentication.
- Remote authentication (preserved for future use but not active).
- Cloud-based settings sync.

## Prerequisites

- Phase 02 (Local Database Foundation) must be completed.
- ADR-010 (No server login in local runtime) must be Accepted.

## Relevant Current Files

- `frontend/lib/features/auth/presentation/auth_provider.dart`
- `frontend/lib/features/auth/presentation/login_screen.dart`
- `frontend/lib/features/auth/data/auth_repository.dart`
- `frontend/lib/features/auth/domain/user_entity.dart`
- `frontend/lib/core/network/dio_provider.dart` — `_AuthInterceptor` class.
- `frontend/lib/core/router/app_router.dart` — Current routing.
- `frontend/lib/features/settings/` — Empty scaffold.
- `frontend/lib/main.dart` — `localeProvider` usage.

## Expected New Files

- `frontend/lib/features/settings/domain/settings_entity.dart` (proposed)
- `frontend/lib/features/settings/data/local_settings_repository.dart` (proposed)
- `frontend/lib/features/settings/presentation/settings_screen.dart` (proposed)
- `frontend/lib/features/settings/presentation/settings_provider.dart` (proposed)
- `frontend/lib/features/security/presentation/local_auth_provider.dart` (proposed)

## Data Model Impact

- A `settings` table or `shared_preferences` keys for:
  - `pin_enabled` (bool)
  - `pin_hash` (String, stored in secure storage if available)
  - `biometric_enabled` (bool)
  - `language` (String, e.g., "ar", "en")
  - `lock_timeout_minutes` (int)

## Repository and Provider Impact

```
SettingsScreen
→ settingsProvider
→ LocalSettingsRepository
→ shared_preferences / settings table
→ SQLite (optional)
```

## Implementation Tasks

- [ ] Define settings entity and local settings repository.
- [ ] Implement local settings persistence (language, PIN enabled, biometric enabled, lock timeout).
- [ ] Implement optional local PIN (hash and store securely).
- [ ] Implement optional biometric authentication using `local_auth` package (if approved).
- [ ] Implement lock/unlock behavior (app locks after timeout when PIN is enabled).
- [ ] Implement settings screen UI.
- [ ] Add `/settings` route to `app_router.dart`.
- [ ] Migrate `localeProvider` to use local settings persistence.
- [ ] Ensure no JWT token is required or stored in local mode.
- [ ] Write unit tests for settings persistence.
- [ ] Write tests for PIN enable/disable/verify flow.
- [ ] Run `flutter analyze`.

## Validation Plan

- Static analysis: `flutter analyze`.
- Unit tests: Settings persistence, PIN flow.
- Persistence after restart: Settings persist across app restarts.
- Offline behavior: All settings work offline.
- Security: PIN is hashed, not stored in plain text.

## Acceptance Criteria

1. No server login is required to use the app.
2. Optional PIN can be enabled, verified, and disabled.
3. Settings (language, PIN, biometric) persist across restarts.
4. Settings screen is accessible and functional.
5. `flutter analyze` reports zero errors.
6. All settings tests pass.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-019: Uncontrolled `shared_preferences` use. Mitigated by centralizing settings access.
- R-002: App uninstall causes total data loss (including settings). Mitigated by backup (Phase 11).

## Rollback Strategy

1. Revert settings changes.
2. Re-enable auth redirect in router (if needed for backend mode).
3. Delete settings and security files.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 10 status.
- `frontend/HISTORY.md` — Add entry for settings and local security.
- `docs/history.md` — Add entry for settings and local security.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent