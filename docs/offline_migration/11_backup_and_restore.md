# Phase 11 — Backup and Restore

## Status

- Status: Completed
- Owner: Codex
- Created: 2026-07-22
- Last updated: 2026-07-26
- Implementation started: 2026-07-26
- Implementation completed: 2026-07-26

## Objective

Provide an offline, portable, full-database backup and a validated
replacement restore with rollback. No cloud service, API, JWT, account, or
encryption is involved.

## Previous state

The application stored all active business data in
`construction_erp.db` under the application documents directory, but exposed
no backup or restore operation. `databaseProvider` owned a lazy
`NativeDatabase` and closed it on provider disposal.

## Implemented architecture

```text
Settings / BackupRestoreSection
→ BackupRestoreNotifier
→ BackupRepositoryInterface
→ LocalBackupRepository
├── DatabaseSnapshotService
├── BackupArchiveService
├── BackupChecksumService
└── database lifecycle callbacks
    → close database → replace → invalidate/recreate databaseProvider
```

Presentation selects files and displays state only. It has no `AppDatabase`,
DAO, SQL, archive, or checksum dependency.

## Snapshot strategy

Phase 11 uses SQLite `VACUUM INTO` against the active Drift connection.
SQLite produces a transactionally consistent, standalone database snapshot.
The live file is never copied blindly and no `-wal` or `-shm` file enters the
backup. Snapshot failure does not close or mutate the active database.

## Backup format

The portable `.cerpbackup` file is ZIP-compatible and contains exactly:

- `manifest.json`
- `construction_erp.db`

Compressed input is limited to 256 MiB and the extracted database to 512 MiB.
Nested, parent-relative, absolute, backslash, and Windows drive-letter entry
paths are rejected.

## Manifest contract

Format version 1 uses strict UTF-8 JSON fields:

- `backupFormatVersion`
- `applicationId`
- `createdAtUtc`
- `databaseEntryName`
- `databaseSchemaVersion`
- `databaseSizeBytes`
- `databaseSha256`
- `applicationVersion`
- `recordCounts` for Clients, Projects, Milestones, Payments, Expenses, and
  AppSettings

Missing required fields, invalid UTC timestamps, wrong product identifiers,
invalid checksums, unsupported format versions, and future schemas are
rejected. Unknown optional fields are harmless.

## Backup creation

1. Select a destination through the system file selector.
2. Enter `creatingBackup` maintenance state and block duplicate operations.
3. Create the temporary `VACUUM INTO` snapshot.
4. Run `integrity_check`, `foreign_key_check`, core-table checks, and counts.
5. Stream SHA-256 calculation.
6. Create the two-entry archive and copy it to the selected destination.
7. Verify the output and remove all temporary files.

Cancellation is an idle result, not an error. Existing destination files are
not silently overwritten.

## Restore validation and preview

The selected file is copied to an application-controlled temporary directory.
The archive structure, paths, sizes, strict manifest, declared file size, and
SHA-256 are validated before SQLite is opened. The staging database is opened
through the current Drift migration chain, then integrity, foreign keys,
schema, tables, and record counts are revalidated.

The UI shows the UTC creation date, record counts, and an explicit warning
that restore replaces all current local data and is not a merge. Cancellation
deletes staging files and never mutates the active database.

## Schema compatibility

- Schema greater than current v4: rejected.
- Schema below v1: rejected.
- Schemas v1–v3: migrated only on the extracted staging copy through the
  verified Drift migration chain.
- The post-migration staging schema must equal v4 and pass all checks.

## Replacement and rollback

After explicit confirmation:

1. Copy validated staging data to an incoming sibling file.
2. Close the active database and remove closed sidecars.
3. Rename the current database to `.pre_restore`.
4. Rename incoming data to the canonical filename.
5. Recreate `databaseProvider`; dependent watched repositories/providers are
   invalidated with it.
6. Recheck integrity, foreign keys, schema, and record counts.
7. Delete rollback and staging data only after success.

If replacement, reopening, or final validation fails, the replacement is
closed and removed, `.pre_restore` is restored, reopened, and validated. The
user receives a rollback-safe failure message.

## Included data

All rows in Clients, Projects, Milestones, Payments, Expenses, and AppSettings
are included. This includes archived Clients, soft-deleted financial rows,
group identifiers, original currencies, immutable exchange-rate snapshots,
converted YER amounts, locale, and default rate.

## Excluded data and limitations

- JWT, refresh tokens, passwords, secure storage, SharedPreferences, API
  caches, logs, and build files are excluded.
- Attachments/receipts do not exist and are not claimed as included.
- Backups are **not encrypted**. Users must store them in a protected place.
- No cloud upload, synchronization, merge restore, or analytics exists.
- The current checked-in Flutter platform is Android. `file_selector` uses the
  scoped system document UI without broad storage permissions; other platform
  runners require their normal project configuration before release testing.

## UI and accessibility

Backup/Restore is embedded in local Settings. It exposes idle, creating,
validating, preview/confirmation, restoring, completed, and failed states.
Buttons are disabled during maintenance. Ten English/Arabic phone, tablet,
and desktop-sized layouts pass without overflow; long errors remain readable.

## Validation

- `flutter pub get`: exit 0, 8.4s.
- `flutter analyze --no-pub`: exit 0, zero findings, 4.2s final run.
- Focused Backup/Restore: 42 passed, exit 0, 8.4s final run.
- Settings 27 (7.4s), Dashboard 18 (7.5s), Reports 27 (13.8s),
  Clients 36 (6.3s), Projects 30 (6.3s), Milestones 30 (6.5s),
  Payments 35 (6.6s), and Expenses 40 (6.4s).
- Database 75 (8.1s), contract 49 (6.5s).
- Full Flutter: 412 passed, exit 0, 32.4s final run.
- FastAPI baseline: 17 passed, exit 0, 9.3s.

## Completion record

- Completion date: 2026-07-26
- Backup format: `.cerpbackup`, ZIP-compatible, format version 1
- Active schema: 4
- Snapshot method: SQLite `VACUUM INTO`
- Checksum: streaming SHA-256
- Router changes: none
- Backend/Alembic changes: none
- Branch/commit created by Codex: none
- Phase 12: Ready; not started
