# Phase 13 — Offline Release Validation

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Validate that the application is fully functional offline and ready for client delivery. Execute a comprehensive release validation checklist covering all features, edge cases, and failure scenarios.

## Current State

After Phases 02–12, the application should be fully local-first with no runtime HTTP dependency. All data is stored in SQLite via Drift. Backup and restore are implemented. Settings and optional PIN security are in place.

## Target State

A validated, release-ready offline application that passes all acceptance criteria and the release validation checklist.

## Scope

- Full offline validation.
- Fresh installation validation.
- CRUD operations validation.
- Restart and persistence validation.
- Database upgrade validation.
- Backup and restore validation.
- Failure scenario validation.
- Performance validation.
- Financial precision validation.
- Release APK build.

## Out of Scope

- New feature development.
- Backend changes.

## Prerequisites

- All phases 02–12 must be completed.

## Relevant Current Files

- All `frontend/lib/` files.
- `frontend/pubspec.yaml`.
- `frontend/test/` — All test files.

## Expected New Files

- `frontend/test/offline_release_validation_test.dart` (proposed) — Automated validation tests.

## Data Model Impact

None.

## Repository and Provider Impact

None.

## Implementation Tasks

- [ ] Build release APK: `flutter build apk --release`.
- [ ] Test with backend stopped (no FastAPI running).
- [ ] Test in airplane mode (network disabled).
- [ ] Test fresh installation (uninstall, install, verify empty state).
- [ ] Test create/read/update/archive for clients.
- [ ] Test create/read/update/delete for projects.
- [ ] Test create/read/update/complete/delete for milestones.
- [ ] Test create/read/update/delete for payments.
- [ ] Test create/read/update/delete for expenses.
- [ ] Test dashboard loads correctly with local data.
- [ ] Test reports generate correctly with local data.
- [ ] Test restart application (close, reopen, verify data persists).
- [ ] Test restart device (reboot, verify data persists).
- [ ] Test database upgrade (install old version, upgrade, verify data).
- [ ] Test backup creation.
- [ ] Test restore from valid backup.
- [ ] Test restore from invalid backup (corrupted, wrong checksum, missing manifest).
- [ ] Test low storage scenario.
- [ ] Test interrupted restore recovery.
- [ ] Test financial precision (large amounts, small amounts, exact Decimal values).
- [ ] Test duplicate IDs (verify UUID uniqueness).
- [ ] Test foreign-key enforcement (insert child with non-existent parent).
- [ ] Test crash recovery (force stop, reopen, verify data).
- [ ] Test data-loss warnings (backup reminder before destructive operations).
- [ ] Verify Android permissions (storage, biometric if applicable).
- [ ] Test performance with realistic data (100+ clients, 50+ projects, 500+ payments/expenses).
- [ ] Run `flutter analyze` — must report zero errors.
- [ ] Run all unit and integration tests.
- [ ] Final delivery checklist sign-off.

## Validation Plan

This phase IS the validation plan. All items in the implementation tasks are validation steps.

## Acceptance Criteria

1. Application runs fully offline in airplane mode.
2. All CRUD operations work without network.
3. Data persists across app restarts and device reboots.
4. Backup and restore work correctly.
5. Invalid backups are rejected.
6. Interrupted restore recovers gracefully.
7. No financial precision loss in any test.
8. No duplicate UUIDs generated.
9. Foreign keys are enforced.
10. Crash recovery preserves data.
11. Performance is acceptable with realistic data volumes.
12. `flutter analyze` reports zero errors.
13. All tests pass.
14. Release APK builds successfully.

## Risks

See [risk_register.md](risk_register.md). All risks are validated during this phase.

## Rollback Strategy

If validation fails, identify the failing phase, fix the issue, and re-run validation. No code rollback is needed — this phase is validation-only.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 13 status to Completed.
- `docs/offline_migration/README.md` — Update overall migration status.
- `frontend/HISTORY.md` — Add entry for release validation.
- `docs/history.md` — Add entry for release validation and migration completion.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent