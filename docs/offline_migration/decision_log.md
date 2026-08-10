# Decision Log

## ADR-015 — Inline client creation from the project form (UX)

- **Date:** 2026-08-08
- **Status:** Accepted
- **Decision:** Allow creating a client without leaving the "Create Project"
  screen, via a localized in-form dialog. The dialog uses the existing
  `ClientRepositoryInterface` (local-first); UI never touches Drift directly
  and no API/Dio dependency is introduced.
- **Consequences:** Project creation flow improved; no schema, repository,
  routing, or backend changes. Existing client/project persistence and
  validation are reused. All user-facing strings are localized (Arabic +
  English); technical exceptions are never exposed to the user.

## ADR-014 — Conservative startup recovery and Android release boundary

- **Date:** 2026-07-26
- **Status:** Accepted
- **Decision:** Run candidate validation before Riverpod database exposure.
  Prefer canonical, then rollback, then incoming; preserve invalid evidence.
  Release manifest has no network or broad-storage permission.
- **Release decision:** Technically validated; production application ID,
  signing credentials, and physical install/update validation remain manual.

## ADR-013 — Remove frontend remote and authentication runtime

- **Date:** 2026-07-26
- **Status:** Accepted
- **Decision:** Remove Dio/endpoints, remote frontend repositories, and
  authentication/session code after completing all local feature migrations.
- **Consequences:** Flutter no longer consumes FastAPI or requires JWT. Local
  repositories are the only active business sources. FastAPI remains separately
  preserved. No fake local authentication was added. Git history archives
  deleted adapters; historical DTO contracts are test-only fixtures.

> **Architecture Decision Records (ADR) for the offline migration.**

## Status Values

- **Proposed** — Decision suggested, awaiting confirmation.
- **Accepted** — Decision confirmed and approved.
- **Rejected** — Decision was considered and rejected.
- **Superseded** — Decision has been replaced by a newer ADR.

---

| ID | Decision | Status | Date | Context | Options | Selected Option | Consequences |
|---|---|---|---|---|---|---|---|
| ADR-001 | Local-first single-device architecture | Accepted | 2026-07-22 | The application currently requires a running FastAPI backend. The target is a fully offline app for a single user on a single device. Repository evidence confirms the app is a single-admin ERP with no multi-tenant or RBAC complexity. | 1. Keep server-dependent architecture. 2. Local-first with optional sync. 3. Local-first with no sync (first release). | Option 3: Local-first with no sync in first release. | No network dependency. Data stored locally. No multi-device support. Backup/restore required for data safety. |
| ADR-002 | Preserve FastAPI backend | Accepted | 2026-07-22 | The backend has working CRUD, dashboard, and report implementations with passing tests. Removing it would lose tested code. The backend source at `backend/app/` is complete and buildable. | 1. Delete backend. 2. Archive backend. 3. Preserve backend as future remote adapter. | Option 3: Preserve as future remote adapter. | Backend code remains buildable and testable. Remote repository classes remain in Flutter codebase. No runtime dependency on backend. |
| ADR-003 | Drift selected as the planned local persistence layer | Accepted | 2026-07-22 | A local database ORM is needed for SQLite access in Flutter. The application requires relational queries for dashboard and reports, which limits NoSQL options. | 1. sqflite (low-level, manual SQL). 2. Drift (type-safe, code generation, migrations). 3. Isar (NoSQL, fast but less relational). 4. Hive (key-value, not relational). | Option 2: Drift. | Type-safe database access. Built-in migration support. Code generation required. Supports relational queries needed for dashboard/reports. |
| ADR-004 | Preserve UUID primary identifiers | Accepted | 2026-07-22 | The backend uses UUID v4 (`gen_random_uuid()`) for all primary keys, stored as `String(36)`. Flutter DTOs use `String` for all IDs. Local storage must maintain compatibility. | 1. Switch to auto-increment integers. 2. Keep UUIDs as TEXT. 3. Use UUIDs as BLOB. | Option 2: Keep UUIDs as TEXT. | Compatible with backend UUIDs. Readable in database inspection. Slightly larger storage than integers. |
| ADR-005 | Multi-currency financial storage | Accepted | 2026-07-22 | The application must support YER (base reporting currency, scale 0) and SAR (scale 2). Financial amounts cannot use SQLite REAL or Dart double. Exchange rates need 6 decimal places. Historical transactions must be immutable when default rate changes. Projects may use fixed or per-transaction exchange rates. Reports must show both original currency and unified YER totals. | 1. Store as REAL — rejected, precision loss. 2. Store as TEXT (Decimal string) — fallback only. 3. Store as scaled INTEGER with per-currency scale — preferred for fixed scales. | Option 3: Scaled INTEGER with per-currency scale. | YER amounts stored as INTEGER (scale 0). SAR amounts stored as INTEGER (scale 2). Exchange rates stored as INTEGER (scale 6). Every non-YER transaction stores an immutable exchange-rate snapshot. Historical records never recalculated. Reports show original + unified YER totals. |
| ADR-006 | Introduce domain repository interfaces | Accepted | 2026-07-22 | The UI and providers should not know whether data comes from local SQLite or remote FastAPI. The current codebase has providers calling Dio-based repositories directly (dashboard, reports) or through repository classes (CRUD features). | 1. Direct DAO access from providers. 2. Repository interface with local/remote implementations. | Option 2: Repository interface pattern. | Providers depend on abstractions. Local and remote repositories are interchangeable. Slightly more code. Enables future sync. |
| ADR-007 | Dashboard and Reports remain derived queries | Accepted | 2026-07-22 | Dashboard and report data is computed from clients, projects, payments, and expenses. The backend already computes these as derived queries in `dashboard_repository.py` and `report_repository.py`. Storing pre-computed values would introduce staleness. | 1. Store pre-computed dashboard/report tables. 2. Compute on demand from base tables. | Option 2: Compute on demand. | Always fresh data. No sync needed for derived data. Slightly more query overhead. |
| ADR-008 | Foreign-key enforcement is mandatory | Accepted | 2026-07-22 | SQLite does not enforce foreign keys by default. The backend uses FK constraints with RESTRICT (clients→projects) and CASCADE (projects→milestones/payments/expenses). Data integrity requires equivalent enforcement locally. | 1. No foreign keys (manual checks). 2. Foreign keys with PRAGMA enforcement. | Option 2: Foreign keys with PRAGMA foreign_keys = ON. | Data integrity guaranteed. Orphan records prevented. Cascade deletes work correctly. |
| ADR-009 | Backup and restore is required before client delivery | Accepted | 2026-07-22 | Local-only storage means data is lost if the app is uninstalled or the device is lost. The risk register identifies this as High probability, Critical impact (R-001, R-002, R-003). | 1. No backup (user responsibility). 2. Backup and restore feature. | Option 2: Backup and restore feature. | Data can be exported and imported. Reduces data loss risk. Additional development effort. |
| ADR-010 | No server authentication is required in local runtime | Accepted, clarified | 2026-07-26 | The local app does not need server authentication. No verified PIN, biometric, encryption, or password contract exists. | 1. Keep active JWT auth. 2. Use device security only and preserve remote auth source. 3. Invent an in-app security system. | Option 2: local shell has no auth-session dependency; device security is the current boundary. | No login/logout claim in the local shell. Remote auth code is preserved but inactive. Additional local security requires a separately verified contract. |
| ADR-011 | Persist verified application settings in SQLite | Accepted | 2026-07-26 | Locale was stored separately and new SAR transactions needed an exact, persistent default exchange rate. | 1. Scattered preferences. 2. Canonical settings row through repository/DAO/SQLite. | Option 2: singleton `app_settings` row with scale-6 rate and locale. | Deterministic offline persistence, non-destructive migration, exact financial input, and no network/auth dependency. |
| ADR-012 | Portable full-database backup and replacement restore | Accepted | 2026-07-26 | Local-only data needs a consistent portable recovery artifact without cloud or credential leakage. | 1. Row export/merge. 2. Blind file copy. 3. Consistent SQLite snapshot with strict staged replacement restore. | Option 3: `VACUUM INTO`, versioned ZIP-compatible manifest, streaming SHA-256, staging validation/migration, and rollback. | Restore replaces rather than merges. Rollback is retained through post-reopen checks. Backup is unencrypted, contains no credentials, and does not include nonexistent attachments or use cloud transfer. |

---

## ADR-005 Detailed Text

**Decision:** Multi-currency financial storage using scaled INTEGER.

**Status:** Accepted — confirmed by user on 2026-07-22.

### Confirmed Requirements

- **Base reporting currency:** YER (Yemeni Rial).
- **Supported currencies:** YER, SAR (Saudi Riyal).
- **YER scale:** 0 (no decimal places; amounts stored as whole integer rials).
- **SAR scale:** 2 (2 decimal places; amounts stored as integer halalas).
- **Exchange-rate scale:** 6 (6 decimal places for exchange rate precision).
- **Default exchange rate:** Stored in settings; used only as a suggested value when entering new transactions.
- **Project exchange policy:** Each project may use either a fixed exchange rate or a per-transaction rate.
- **Historical transactions:** Never recalculated when the default rate changes. Every transaction stores an immutable exchange-rate snapshot.
- **Mixed-currency expense:** Stored as multiple linked expense lines (one per currency).
- **Reports:** Show original currency totals and unified YER totals.

### Storage Rules

1. **SQLite REAL and Dart `double` are prohibited** as authoritative money types. All financial values use scaled INTEGER storage.

2. **YER amounts** are stored as `INTEGER` with scale 0. The stored value IS the amount (e.g., 150000 = 150,000 YER).

3. **SAR amounts** are stored as `INTEGER` with scale 2. The stored value is amount × 100 (e.g., 15000050 = 150,000.50 SAR).

4. **Exchange rates** are stored as `INTEGER` with scale 6. The stored value is rate × 1,000,000 (e.g., 135250000 = 135.25 YER/SAR).

5. **Every non-YER transaction stores:**
   - Original amount (scaled INTEGER in original currency).
   - Original currency code (TEXT: `"YER"` or `"SAR"`).
   - Applied exchange rate (scaled INTEGER, scale 6).
   - Converted YER amount (scaled INTEGER, scale 0).
   - Rate source (TEXT: e.g., `"manual"`, `"default"`, `"project_fixed"`).
   - Rate date (TEXT: ISO date).

6. **Historical immutability:** Changing the current default exchange rate does NOT modify historical records. Each transaction's exchange-rate snapshot is permanent.

7. **Project exchange policy:** Each project stores an exchange policy field (`"fixed_rate"` or `"per_transaction"`). When fixed, a single rate applies to all transactions in that project. When per-transaction, each transaction uses its own rate.

8. **Mixed-currency expenses:** An expense in multiple currencies is stored as multiple linked expense lines. Each line has its own currency, amount, and exchange-rate snapshot. Lines are linked by a shared parent expense ID.

9. **Reports:** Both original currency totals and unified YER totals are computed and displayed. The unified YER total is derived from each transaction's stored converted YER amount (not recomputed from current rates).

### Unresolved Monetary Questions (Previous)

The following questions were previously "Decision Required" and are now resolved:

| Question | Resolution |
|---|---|
| What currency does the application use? | YER is the base reporting currency. SAR is also supported. |
| Is the decimal scale always 2? | No. YER uses scale 0. SAR uses scale 2. Exchange rates use scale 6. |
| Should `profit_margin` use the same representation as money? | `profit_margin` is a ratio, not a monetary amount. It remains `Decimal` quantized to 0.01. Stored as TEXT or INTEGER scale 2. |

### Remaining Questions

| Question | Context | Status |
|---|---|---|
| What is the initial default YER/SAR exchange rate? | 410.000000, represented as scale-6 INTEGER `410000000`; user-editable and future-transactions-only. | Resolved in Phase 10 |
| How are mixed-currency expense lines linked? | Need a parent expense ID or grouping mechanism. | Decision Required — proposed: shared `parent_expense_id` field. |
| Does `budget` on a project need currency designation? | Currently `Numeric(14,2)` with no currency. With multi-currency, budget must declare its currency. | Decision Required |
| Should the local settings table store the default exchange rate? | Yes: canonical `app_settings` row, scale-6 INTEGER, repository validation. | Resolved in Phase 10 |

---

## How to Add a New ADR

1. Assign the next sequential ID (ADR-011, ADR-012, etc.).
2. Set status to `Proposed`.
3. Fill all columns with specific, non-vague content.
4. Link the ADR from the relevant phase document.
5. Update the status to `Accepted` only when the decision is confirmed by the user or stakeholder.
6. Never set status to `Accepted` without evidence of confirmation.
# Phase 08 decisions — 2026-07-26

- Archived clients are excluded from the active-client KPI while historical
  projects remain visible.
- Payments minus expenses is named **net cash flow**.
- Finance timelines are complete, chronological, zero-filled calendar series
  controlled by an injectable reference date.
- Dashboard values remain derived; no result table is permitted.
- No audit/activity entry is fabricated; the UI truthfully presents project
  overview and an unavailable state.

# Phase 09 decisions — 2026-07-26

- Reports remain derived and no report-result table is permitted.
- Only Project Status, Financial Summary, and Expense Analysis are implemented.
- Active financial rows and their stored converted-YER snapshots are authoritative.
- Financial date ranges are inclusive and date-only.
- Payments minus Expenses is **Net cash flow**, not profit, debt, receivable, or outstanding balance.
- Payments and Expenses must be aggregated independently before Project joins.
- Archived Clients retain historical report data.
- Expense shares and Milestone progress use integer basis points with zero guards.
- The existing disabled export action remains disabled; Phase 09 does not introduce an export engine or a hidden remote call.
- The preserved FastAPI adapter is future-only; the runtime provider is local.
