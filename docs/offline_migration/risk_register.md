# Risk Register

## Phase 13 final risks

Interrupted Restore and missing/corrupt canonical risks are mitigated by
validated, deterministic startup recovery. Network/storage permission leakage
is closed by merged-manifest tests and inspection. Remaining distribution risks
are owned by the release manager: permanent application ID, production signing,
physical clean-install/update, system file-selector, airplane-mode, and
on-device performance validation.

## Phase 12 closure and Phase 13 carry-over

Architecture scans, provider tests, responsive suites, 422 full Flutter tests,
and the Android build close the risks of remaining API/token references, stale
remote tests, HTTP DTO coupling, removed plugin dependencies, router/auth
regression, misleading security UI, and Backup/Restore invalidation.

Future networking requires an explicit architecture decision. Phase 13 retains
startup recovery for abandoned `.pre_restore`/`.incoming` files, release
platform validation, installation/upgrade validation, and production
data-lifecycle checks.

> **Identified risks for the offline migration.**

## Status Values

- **Open** — Risk identified, mitigation not yet in place.
- **Mitigated** — Mitigation implemented and verified.
- **Closed** — Risk no longer applicable.
- **Monitoring** — Mitigation in place, ongoing monitoring required.

---

| ID | Risk | Probability | Impact | Detection | Mitigation | Owner | Status |
|---|---|---|---|---|---|---|---|
| R-001 | App uninstall causes total data loss | High | Critical | User reports data loss after uninstall | Backup and restore feature (Phase 11). User education to back up regularly. | Unassigned | Open |
| R-002 | Clear application data causes total data loss | Medium | Critical | User reports data loss after clearing app data | Backup and restore feature (Phase 11). Data-loss warning before destructive operations. | Unassigned | Open |
| R-003 | Device loss causes total data loss | Medium | Critical | User reports unable to access data | Backup and restore feature (Phase 11). Encourage regular backups to external storage. | Unassigned | Open |
| R-004 | SQLite database corruption | Low | Critical | Database open fails, error logs | WAL mode, proper close handling, backup before migrations, crash recovery testing (Phase 13). | Unassigned | Open |
| R-005 | Failed migration leaves database in inconsistent state | Low | High | Migration test fails, data inconsistency | Drift migration framework with up/down support. Test migrations on copy before applying. | Unassigned | Open |
| R-006 | Failed restore corrupts existing data | Medium | Critical | Restore test fails, data loss | Safe backup before restore. Temporary database validation. Atomic replacement (Phase 11). | Unassigned | Open |
| R-007 | Partial backup if interrupted | Low | High | Backup file is incomplete or corrupted | Checksum verification (SHA-256). Manifest validation before restore (Phase 11). | Unassigned | Open |
| R-008 | Financial precision loss | Medium | Critical | Financial test fails, amount mismatch | ADR-005 Accepted: scaled INTEGER storage. YER scale 0, SAR scale 2, exchange rate scale 6. SQLite REAL and Dart double prohibited. Every non-YER transaction stores immutable exchange-rate snapshot. | Unassigned | Mitigated |
| R-013 | Dashboard aggregation row multiplication in projects_overview | High | High | Dashboard sums are inflated when a project has both payments and expenses | Local Dashboard aggregates payments and expenses independently before joining; dedicated multi-row tests verify exact totals. | Unassigned | Mitigated |
| R-022 | Finance timeline missing months with no transactions | Medium | Medium | Dashboard finance chart shows fewer than 12 months | Local Dashboard generates a canonical 12-month sequence and zero-fills missing income and expense months; tests cover sparse data. | Unassigned | Mitigated |
| R-023 | Outstanding balance is total net, not negative-only | Medium | Medium | Dashboard shows positive outstanding balance when payments exceed expenses | Verified: `outstanding_balances = total_payments - total_expenses`. The field name suggests it should represent only negative balances (money owed), but the implementation returns the overall net. This is misleading. | Unassigned | Open |
| R-024 | Total clients includes archived clients | Low | Low | Dashboard client count includes archived clients | Verified: `counts()` counts all clients with no archived filter. The field name `total_clients` does not distinguish active from archived. | Unassigned | Open |
| R-025 | profit_margin is a ratio, not a percentage | Low | Low | UI may display 0.50 instead of 50% | Verified: `profit_margin = (balance / total_payments).quantize(Decimal("0.01"))` — no `* 100`. The field name says "margin" but the value is a ratio. UI must multiply by 100 for display. | Unassigned | Open |
| R-026 | Exchange rate changes corrupt historical data | Medium | Critical | Historical transaction YER amounts change after rate update | ADR-005: Every non-YER transaction stores an immutable exchange-rate snapshot (original amount, original currency, applied rate, converted YER amount, rate source, rate date). Historical transactions are never recalculated. | Unassigned | Mitigated |
| R-027 | Mixed-currency expense line linkage breaks | Low | High | Expense lines become orphaned from parent | Use shared `parent_expense_id` field with foreign key enforcement. Validate all lines share the same project_id. | Unassigned | Open |
| R-028 | Currency scale mismatch in arithmetic | Medium | Critical | YER (scale 0) and SAR (scale 2) amounts added incorrectly | All unified calculations use converted YER amounts (scale 0). Original amounts are display-only after conversion. Never mix scales in arithmetic. | Unassigned | Open |
| R-029 | Budget currency not designated on existing projects | Medium | Medium | Projects created before multi-currency have no currency field | Migration must assign default currency (YER) to existing budget values. Decision Required on whether budget is YER or SAR by default. | Unassigned | Open |
| R-009 | Cascade deletion removes unintended data | Medium | High | Project delete removes milestones/payments/expenses unexpectedly | Confirmation dialog before delete. Cascade is intentional but must be communicated to user. | Unassigned | Open |
| R-010 | Duplicate UUID during import | Very Low | High | UUID collision on restore | UUID v4 has negligible collision probability. Verify uniqueness on import. | Unassigned | Open |
| R-011 | Orphan records after failed cascade | Low | High | Child records exist without parent | Foreign key enforcement (PRAGMA foreign_keys = ON). ADR-008. | Unassigned | Open |
| R-012 | Missing foreign-key enforcement | Medium | High | Insert child with non-existent parent succeeds | PRAGMA foreign_keys = ON on every connection. Integration test for FK enforcement. | Unassigned | Open |
| R-013 | Dashboard aggregation row multiplication | Medium | High | Dashboard sums are inflated | Implemented separate grouped subqueries with an aggregation safety test in Phase 08. | Unassigned | Mitigated |
| R-014 | Invalid date parsing | Low | Medium | Date fields show incorrect values | Use ISO 8601 format consistently. Test date parsing with various inputs. | Unassigned | Open |
| R-015 | Timezone inconsistencies | Medium | Medium | Timestamps differ across timezones | Store all timestamps as UTC. Convert to local timezone only for display. | Unassigned | Open |
| R-016 | Android storage permissions denied | Medium | High | Backup/restore fails with permission error | Use Android Storage Access Framework (user picks file location). Handle permission denial gracefully. | Unassigned | Open |
| R-017 | Release/debug differences in database behavior | Low | Medium | App works in debug but fails in release | Test both debug and release configurations (Phase 13). | Unassigned | Open |
| R-018 | Attachment path invalidation | Low | Medium | Attachment file not found after restore | Attachments not yet implemented. Account for path migration in backup manifest when implemented. | Unassigned | Open |
| R-019 | Uncontrolled SharedPreferences use | Medium | Low | Settings scattered across multiple keys | Verified settings are centralized in LocalSettingsRepository and SQLite. Preserved remote token preferences are inactive in local runtime. | Codex | Mitigated (Phase 10) |
| R-020 | Malformed or imprecise exchange-rate setting | Low | High | Settings validation or migration test fails | Exact scale-6 INTEGER, shared finance parser, positive/precision validation, and safe read fallback. | Codex | Mitigated (Phase 10) |
| R-021 | Default-rate change recalculates financial history | Low | Critical | Stored snapshots/totals change after a setting update | Default is consulted only during creation; regression tests compare existing Payment, Expense, and Project fixed-rate rows. | Codex | Mitigated (Phase 10) |
| R-022 | Local runtime accidentally depends on JWT | Low | High | Offline screen blocks or starts auth refresh | Local providers use repository/SQLite paths; shell auth-session dependency and misleading logout UI were removed. Remote code remains isolated. | Codex | Mitigated (Phase 10) |
| R-023 | Unsupported local-security claim | Low | High | UI claims PIN, biometric, encryption, or account protection | Settings UI explicitly describes device-level boundary; no secret fields exist in AppSettings. | Codex | Mitigated (Phase 10) |
| R-024 | Locale startup fallback or responsive overflow | Low | Medium | Unsupported locale, load failure, RTL overflow | Restrict locale to en/ar, safe English startup fallback, and test ten RTL/LTR viewports plus loading/error states. | Codex | Mitigated (Phase 10) |
| R-025 | Phase 10 expands into backup or global API removal | Low | Medium | Backup/API production files appear in diff | Phase boundary documented; router, backend, Alembic, backup, and global API source remain unchanged. | Codex | Mitigated (Phase 10) |
| R-026 | Inconsistent SQLite backup or omitted WAL data | Low | Critical | Snapshot row counts/integrity differ | Use SQLite `VACUUM INTO`; never copy the active file and never archive WAL/SHM. | Codex | Mitigated (Phase 11) |
| R-027 | Corrupt/tampered archive or checksum mismatch | Low | Critical | ZIP, size, SHA-256, integrity, or FK validation fails | Validate all layers on a staging copy before replacement. | Codex | Mitigated (Phase 11) |
| R-028 | Archive traversal or oversized extraction | Low | Critical | Nested, absolute, drive, parent path, or size-limit test fails | Exactly two root entries; 256 MiB compressed and 512 MiB extracted limits. | Codex | Mitigated (Phase 11) |
| R-029 | Future/unsupported schema or staging migration failure | Low | High | Schema outside v1–v4 or post-migration checks fail | Reject future/unknown schemas; migrate only staging and rerun validation. | Codex | Mitigated (Phase 11) |
| R-030 | Windows file lock or failed active replacement | Medium | Critical | Rename/reopen fails | Close active Drift connection, use sibling incoming/rollback files, and restore rollback on any failure. | Codex | Mitigated (Phase 11) |
| R-031 | Stale DAO/provider after restore | Low | High | Feature reads closed database | Invalidate `databaseProvider`; watched repository/DAO providers rebuild from the new instance. | Codex | Mitigated (Phase 11) |
| R-032 | Credential inclusion or misleading encryption claim | Low | Critical | Manifest/archive contains remote secrets or UI claims encryption | Back up only SQLite business/settings tables; explicitly label artifact unencrypted. | Codex | Mitigated (Phase 11) |
| R-033 | Temporary-file leakage or user cancellation | Low | Medium | Controlled staging directory remains | Cleanup in success/failure/cancel paths and on provider disposal. | Codex | Mitigated (Phase 11) |
| R-034 | Process termination during the small replacement window | Low | Critical | `.pre_restore` remains after abrupt termination | Rollback file is never deleted before validation; startup crash-recovery automation remains a release-validation hardening item. | Unassigned | Open |
| R-020 | Accidental continued HTTP calls | Medium | High | App makes network request in airplane mode | HTTP call verification test. Audit all providers for Dio imports (Phase 12). | Unassigned | Open |
| R-021 | Documentation becomes stale | Medium | Medium | Documentation does not match implementation | Mandatory history updates after each phase. Phase status tracking in README. | Unassigned | Open |
# Phase 08 risk update — 2026-07-26

- Cartesian aggregation is mitigated by separately grouped finance subqueries.
- Soft-delete and archived-client predicates are explicit.
- Feature mutation providers invalidate Dashboard providers.
- Net-cash-flow naming and zero-filled canonical month generation address
  misleading names and missing periods.
- SQLite INTEGER and Dart `int` preserve precision; int64 sum limits remain a
  deployment-monitoring concern.
- Financial cards wrap and the required viewport/RTL widget matrix passes.
- No recent activity is fabricated and active providers contain no Dio path.
- Validation confirmed all focused and full test suites pass. The exact analyzer
  command exits 0 with no findings, so Phase 08 is completed.

# Phase 09 risk update — 2026-07-26

- Inclusive ISO date-only predicates and boundary tests mitigate off-by-one,
  timezone-shift, month/year-boundary, single-day, and leap-day risks.
- Separate grouped Payment and Expense subqueries mitigate Cartesian multiplication.
- Explicit `is_deleted = 0` predicates mitigate deleted-row inclusion.
- Stored converted-YER snapshots prevent historical-rate recalculation.
- Integer YER totals and basis-point ratios avoid mixed-scale and division-by-zero errors.
- Typed filters, provider-family equality, and mutation invalidation mitigate stale results.
- Ten RTL/LTR viewport tests mitigate responsive overflow.
- The export action remains disabled, preventing hidden remote export calls.
- The active Reports provider has no Dio dependency; the API adapter is explicitly preserved and inactive.
- Net-cash-flow naming prevents invented profit, receivable, or debt semantics.
- SQLite/Dart int64 aggregate limits remain a deployment-monitoring risk.
