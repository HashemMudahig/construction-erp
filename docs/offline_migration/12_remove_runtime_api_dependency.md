# Phase 12 — Remove Runtime API Dependency

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Remove all runtime HTTP dependency from the Flutter application. Ensure no Dio provider, API repository, or endpoint constant is invoked during normal local operation. Preserve the FastAPI backend and remote-capable code for future use, but ensure the local runtime path makes zero HTTP calls.

## Current State

After Phases 03–09, all entity and dashboard/report providers use local repositories. However, the following HTTP-related code still exists:

- `frontend/lib/core/network/dio_provider.dart` — `dioProvider`, `_AuthInterceptor`, `_EnvelopeInterceptor`, `ApiException`, `ApiError`.
- `frontend/lib/core/config/app_config.dart` — `appConfig` with `baseUrl`.
- `frontend/lib/core/constants/endpoints.dart` — All API endpoint constants.
- `frontend/lib/features/auth/` — `AuthRepository`, `AuthSessionNotifier`, `LoginScreen`.
- Feature `data/` directories still contain Dio-based repository classes (e.g., `ClientRepository`, `ProjectRepository`, etc.) — preserved but unused.

## Target State

- No HTTP call occurs during normal local application runtime.
- The Dio provider and API repositories remain in the codebase, preserved and buildable, but are not wired into any active provider.
- The auth provider and login screen are either removed or gated behind a future "remote mode" flag.
- Endpoint constants remain for reference but are not called.
- The app starts directly to the dashboard with no network check.
- Criteria proving no HTTP call occurs are documented and tested.

## Scope

- Identify and disconnect all remaining Dio usage from active providers.
- Clean up router (remove any auth redirect if still present).
- Remove or gate auth provider.
- Verify no HTTP call occurs at startup or during any operation.
- Preserve FastAPI backend and remote-capable code.

## Out of Scope

- Deleting the FastAPI backend source code.
- Deleting Dio provider or API repository classes (preserved for future use).
- Implementing a remote/local mode switch (future enhancement).

## Prerequisites

- Phases 03–09 (all entity, dashboard, and report local storage) must be completed.
- Phase 10 (Settings and Local Security) must be completed.
- ADR-002 (Preserve FastAPI backend) must be Accepted.
- ADR-010 (No server login in local runtime) must be Accepted.

## Relevant Current Files

- `frontend/lib/core/network/dio_provider.dart`
- `frontend/lib/core/config/app_config.dart`
- `frontend/lib/core/constants/endpoints.dart`
- `frontend/lib/core/router/app_router.dart`
- `frontend/lib/features/auth/` — All auth files.
- `frontend/lib/features/*/data/*_repository.dart` — All Dio-based repositories.
- `frontend/lib/main.dart`

## Expected New Files

No new files expected. This phase involves disconnection and cleanup.

## Data Model Impact

None.

## Repository and Provider Impact

All active providers must depend only on local repositories. Dio-based repositories remain in the codebase but are not referenced by any active provider.

## Implementation Tasks

- [ ] Audit all providers to confirm none import or use `dioProvider`.
- [ ] Audit all screens to confirm none directly call Dio or API repositories.
- [ ] Remove auth redirect from router (if still present).
- [ ] Remove or gate `authSessionProvider` (either delete or wrap in a feature flag).
- [ ] Remove or gate `LoginScreen` route.
- [ ] Ensure `main.dart` starts the app directly at `/` (dashboard) with no auth check.
- [ ] Verify `dioProvider` is not instantiated at runtime (add a test that checks no Dio instance is created).
- [ ] Verify all Dio-based repository classes remain buildable (they are preserved, not deleted).
- [ ] Verify the FastAPI backend remains buildable and its tests pass.
- [ ] Document which providers and files are now unused but preserved.
- [ ] Write a test that verifies no HTTP call is made during app startup and a full CRUD cycle.
- [ ] Run `flutter analyze`.
- [ ] Run backend tests (`python -m pytest` from `backend/`).

## Validation Plan

- Static analysis: `flutter analyze`.
- Backend tests: `python -m pytest` from `backend/`.
- HTTP call verification: Run app in airplane mode, perform all CRUD operations, verify no errors and no HTTP calls.
- Startup test: App starts directly to dashboard with no network.
- Compile-time check: Dio-based repositories compile without errors (preserved code).
- Regression checks: All features (clients, projects, milestones, payments, expenses, dashboard, reports) work offline.

## Acceptance Criteria

1. No HTTP call occurs during app startup.
2. No HTTP call occurs during any CRUD operation.
3. No HTTP call occurs during dashboard or report queries.
4. `dioProvider` is not instantiated at runtime.
5. Auth provider and login screen are removed or gated.
6. Router starts directly at dashboard.
7. All Dio-based repository classes remain buildable.
8. FastAPI backend remains buildable and tests pass.
9. `flutter analyze` reports zero errors.
10. App functions fully in airplane mode.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-020: Accidental continued HTTP calls. Mitigated by HTTP call verification test.
- R-017: Release/debug differences. Mitigated by testing both configurations.

## Rollback Strategy

1. Re-connect providers to Dio-based repositories.
2. Re-enable auth redirect in router.
3. The application returns to its server-dependent architecture.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 12 status.
- `docs/architecture.md` — Update to reflect local-only runtime.
- `docs/tech_stack.md` — Update to reflect Dio as "Preserved for future use".
- `frontend/HISTORY.md` — Add entry for API dependency removal.
- `docs/history.md` — Add entry for API dependency removal.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent