# Phase 13 — Offline Release Validation

## Status

- Status: Completed — Technically Validated, Manual Release Steps Remaining
- Started: 2026-07-26
- Completed: 2026-07-26

## Release audit and architecture

Flutter remains fully local:

```text
startup recovery → Riverpod → local repositories → Drift → SQLite
```

`main()` resolves `construction_erp.db` and runs
`DatabaseStartupRecoveryService` before `ProviderScope` or any repository can
obtain the database. Schema remains version 4.

## Interrupted Restore recovery

Every candidate must be non-empty, open as SQLite, pass `integrity_check` and
`foreign_key_check`, contain all core tables, and reach supported schema v4.
Precedence is canonical, `.pre_restore`, then `.incoming`.

- A valid canonical is never replaced; verified stale remnants are cleaned.
- A missing/corrupt canonical is recovered from valid rollback first.
- Incoming is promoted only when no valid rollback exists.
- Corrupt canonical data is quarantined before replacement.
- If no valid candidate exists, all evidence remains and startup shows a
  controlled local recovery message rather than creating an empty database.
- Recovery is deterministic and idempotent. No journal was required.

## Automated lifecycle validation

File-backed tests cover clean creation, normal restart, stale remnants,
rollback restoration, corrupt-canonical quarantine, incoming promotion,
idempotence, candidate preservation, schema v4, and ordering before `runApp`.
Existing migration tests cover historical v1–v4 paths, persistence, exact
financial snapshots, settings, Dashboard/Reports, and Backup/Restore rollback.
Full Flutter result: 435 passed.

## Android release validation

- Application ID: `com.example.construction_erp` (placeholder; replace before
  external distribution).
- Version: `1.0.0+1`; merged versionCode 1/versionName 1.0.0.
- minSdk 24; targetSdk 36.
- Main/release manifest has no INTERNET, network-state, broad storage, media,
  location, camera, or microphone permission.
- Debug/profile retain INTERNET for Flutter tooling only.
- System document selection remains the Backup/Restore file boundary.
- Launcher activity is exported only for its launcher intent. No cleartext or
  debuggable release flag and no hardcoded secret was found.
- Release currently uses the debug signing key. No production keystore or
  password was generated or committed.

## Artifacts

- `frontend/build/app/outputs/flutter-apk/app-release.apk`
  - SHA-256: `7AE93F48D1507BB429C569F1E07AB2E72A29EF791A65D794F8204F2B65193960`
- `frontend/build/app/outputs/bundle/release/app-release.aab`
  - SHA-256: `01EA070EAE7FB3F6F59D85FB2724732BD49561655A7B2523E13C7C28003D6FB1`

Both release builds completed successfully. A non-failing Material/Cupertino
font notice and Kotlin daemon fallback were emitted.

## Offline, privacy, UI, and performance evidence

Production source has no Dio, FastAPI URL, JWT, Login, token key, or remote
repository. No production financial/customer row logging, remote analytics, or
raw-path user error was found. Existing responsive Arabic/English suites cover
the required phone, tablet, and desktop matrices. Database, Dashboard, Reports,
and Backup suites provide deterministic moderate-data/query and precision
smoke coverage; no dedicated 26,500-row device benchmark was run.

## Device/install/update status

Android SDK `adb devices` reported no connected device. Therefore physical
clean-install, same-key update, file-selector interaction, airplane-mode, and
on-device performance were not claimed. Automated file-backed clean-install,
migration, persistence, recovery, and replacement equivalents passed.

## Validation

- Analyzer: clean.
- Focused Phase 13: 13 passed.
- Full Flutter: 435 passed.
- Release APK and AAB: built.
- Release merged permissions: passed.
- FastAPI baseline: 17 passed; backend production unchanged.

## Manual release steps

1. Choose a permanent non-placeholder application ID.
2. Configure a protected production signing key outside source control.
3. Increment version metadata for the intended distribution.
4. Run physical clean-install and same-signing-key update validation.
5. Exercise system file selection, airplane mode, and realistic performance on
   supported Android hardware.

## Final decision

**Completed — Technically Validated, Manual Release Steps Remaining.**
No source or automated lifecycle blocker remains, but the build is not ready
for store/customer distribution until signing, package identity, and physical
device validation are completed.
