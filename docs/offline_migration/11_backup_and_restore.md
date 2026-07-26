# Phase 11 — Backup and Restore

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Implement database backup and restore functionality to protect against data loss from app uninstall, device loss, or database corruption. The backup must include the SQLite database file, a manifest with schema version and backup format version, and checksums for integrity verification.

## Current State

The application has no backup or restore functionality. All data is stored in the backend (PostgreSQL) or, after migration, in the local SQLite database. There is no mechanism to export or import data.

Attachments are not currently implemented in the application. The backup design must account for their future addition but should not claim they exist.

## Target State

- A backup feature that exports the SQLite database file to a user-chosen location.
- A ZIP archive containing:
  - The SQLite database file.
  - A manifest file (JSON) with:
    - Schema version.
    - Backup format version.
    - Timestamp.
    - Checksums (SHA-256) for the database file.
  - Optional: attachment files (when attachments are implemented in the future).
- A restore feature that:
  - Validates the backup archive before restoring.
  - Creates a safe backup of the current database before replacing it.
  - Validates the restored database in a temporary location.
  - Atomically replaces the active database.
  - Handles failure recovery (restore the safe backup if validation fails).
- Integration with Android Storage Access Framework for file picking.

## Scope

- Database backup to file.
- Database restore from file.
- ZIP manifest with schema version and checksums.
- Safe backup before restore.
- Temporary database validation.
- Atomic replacement.
- Android Storage Access Framework integration.
- Failure recovery.

## Out of Scope

- Cloud backup or sync.
- Attachment backup (attachments not yet implemented).
- Cross-version migration during restore (handled by Drift migrations on open).

## Prerequisites

- Phase 02 (Local Database Foundation) must be completed.
- ADR-009 (Backup and restore is required before client delivery) must be Accepted.

## Relevant Current Files

- `frontend/lib/core/database/app_database.dart` (proposed, from Phase 02).
- `frontend/lib/core/database/database_provider.dart` (proposed, from Phase 02).

## Expected New Files

- `frontend/lib/features/backup/data/backup_service.dart` (proposed)
- `frontend/lib/features/backup/data/restore_service.dart` (proposed)
- `frontend/lib/features/backup/domain/backup_manifest.dart` (proposed)
- `frontend/lib/features/backup/presentation/backup_screen.dart` (proposed)
- `frontend/lib/features/backup/presentation/backup_provider.dart` (proposed)

## Data Model Impact

No data model changes. Backup operates on the database file level.

## Repository and Provider Impact

```
BackupScreen
→ backupProvider
→ BackupService / RestoreService
→ AppDatabase (close, copy file, reopen)
→ File system / Android SAF
```

## Implementation Tasks

- [ ] Define `BackupManifest` class (schema_version, backup_format_version, timestamp, checksums).
- [ ] Implement `BackupService.createBackup()` — close database, copy file, compute SHA-256, create ZIP with manifest.
- [ ] Implement `RestoreService.validateBackup()` — extract ZIP, verify manifest, verify checksums.
- [ ] Implement `RestoreService.restoreBackup()` — create safe backup of current DB, validate restored DB in temporary location, atomically replace.
- [ ] Implement failure recovery (restore safe backup if validation fails).
- [ ] Integrate with Android Storage Access Framework for file picking.
- [ ] Implement backup screen UI.
- [ ] Add `/backup` route.
- [ ] Write unit tests for backup creation.
- [ ] Write unit tests for restore validation.
- [ ] Write tests for invalid backup rejection.
- [ ] Write tests for interrupted restore recovery.
- [ ] Write tests for atomic replacement.
- [ ] Run `flutter analyze`.

## Validation Plan

- Static analysis: `flutter analyze`.
- Unit tests: Backup creation, restore validation, invalid backup rejection.
- Persistence after restart: Backup, close app, restore on fresh install, verify data.
- Offline behavior: Backup and restore work offline.
- Failure recovery: Interrupt restore, verify safe backup is restored.
- Checksum verification: Modify database file in ZIP, verify restore rejects it.
- Schema version check: Attempt to restore a backup with a different schema version, verify appropriate handling.

## Acceptance Criteria

1. Backup creates a valid ZIP with database file and manifest.
2. Restore validates the backup before applying it.
3. Restore creates a safe backup of the current database before replacing.
4. Restore atomically replaces the active database.
5. Invalid backups (corrupted, wrong checksum, missing manifest) are rejected.
6. Interrupted restore recovers gracefully.
7. Backup and restore work offline.
8. `flutter analyze` reports zero errors.
9. All backup/restore tests pass.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-005: Failed restore could corrupt data. Mitigated by safe backup and temporary validation.
- R-006: Partial backup if interrupted. Mitigated by checksum verification.
- R-016: Android storage permissions. Mitigated by using Storage Access Framework.
- R-017: Release/debug differences in file access. Mitigated by testing both configurations.

## Rollback Strategy

1. Delete backup/restore feature files.
2. Remove `/backup` route.
3. The application continues to function without backup capability (data remains in local database).

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 11 status.
- `frontend/HISTORY.md` — Add entry for backup and restore.
- `docs/history.md` — Add entry for backup and restore.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent