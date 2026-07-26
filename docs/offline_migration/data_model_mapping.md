# Data Model Mapping

> **Status: Verified baseline — Phase 01. Local storage types are proposed, not yet implemented.**

This document maps every entity field across all storage layers: Flutter entity, Flutter DTO, FastAPI/Pydantic schema, SQLAlchemy/PostgreSQL model, and the proposed Drift/SQLite type. All field names, types, and behaviors have been verified against the actual source code.

## Conventions

- **UUID storage:** All UUIDs are stored as `TEXT` (36-character string) in SQLite. UUIDs are generated locally using UUID v4. The backend uses `gen_random_uuid()` via `pgcrypto`.
- **Date storage:** Dates are stored as `TEXT` in ISO 8601 format (`YYYY-MM-DD`) in SQLite. Date-only fields have no time component.
- **DateTime/timezone storage:** Timestamps are stored as `TEXT` in ISO 8601 format with UTC timezone (`YYYY-MM-DDTHH:MM:SSZ`) in SQLite. The backend uses `DateTime(timezone=True)` with `server_default=func.now()`.
- **Boolean storage:** Booleans are stored as `INTEGER` (0 or 1) in SQLite, mapped to `bool` in Dart via Drift.
- **Enum storage:** Enums are stored as `TEXT` with the same string values used by the backend.
- **Decimal/money storage:** ADR-005 Accepted — Multi-currency using scaled INTEGER. YER (scale 0) stored as INTEGER directly. SAR (scale 2) stored as INTEGER × 100. Exchange rates stored as INTEGER × 1,000,000 (scale 6). SQLite REAL and Dart `double` are prohibited. Every non-YER transaction stores an immutable exchange-rate snapshot (original amount, original currency, applied rate, converted YER amount, rate source, rate date). Historical transactions are never recalculated. The backend currently uses `Numeric(14,2)` with no currency designation — the local database adds multi-currency support.
- **Currency codes:** Stored as `TEXT` (`"YER"`, `"SAR"`). Base reporting currency is YER.
- **Exchange-rate snapshot:** Every non-YER transaction stores: `original_amount` (INTEGER, in original currency scale), `original_currency` (TEXT), `exchange_rate` (INTEGER, scale 6), `converted_yer_amount` (INTEGER, scale 0), `rate_source` (TEXT), `rate_date` (TEXT ISO date).
- **Project exchange policy:** Each project stores `exchange_policy` (TEXT: `"fixed_rate"` or `"per_transaction"`) and optionally `fixed_exchange_rate` (INTEGER, scale 6).
- **Mixed-currency expense:** Stored as multiple linked expense lines with a shared `parent_expense_id`.
- **Nullable fields:** Nullable fields are stored as `NULL` in SQLite when no value is provided.
- **Default values:** Defaults are enforced at the application layer (Dart/Drift), not at the SQLite level (unless using Drift's `clientDefault`).
- **updated_at column:** Only `clients` has an `updated_at` column (mixin + DB trigger). Projects, milestones, payments, expenses, and users have NO `updated_at` column.
- **Date parsing fallback:** Flutter DTOs fall back to `DateTime.now()` when `DateTime.tryParse` fails for `created_at`, `due_date`, `payment_date`, and `expense_date`. Project `start_date`/`end_date` return `null` on parse failure (nullable entity fields). This is a known defect that can silently mask bad data.

---

## User (retained for reference)

> The User entity is retained for backend compatibility. In local mode, there is no user authentication. The table is not created in the local database.

| Entity | Field | Flutter Type | FastAPI/Pydantic Type | SQLAlchemy/PostgreSQL Type | Proposed Drift/SQLite Type | Required | Default | Notes |
|---|---|---|---|---|---|---|---|---|
| User | id | String | UUID | String(36), gen_random_uuid() | N/A (not local) | YES | gen_random_uuid() | Retained for backend only |
| User | name | String | str | String(120) | N/A | YES | — | |
| User | email | String | EmailStr | String(255), unique, index | N/A | YES | — | |
| User | password_hash | String | — | String(255) | N/A | YES | — | Never exposed to frontend |
| User | role | String | — | String(20) | N/A | YES | "admin" | Always "admin" in v1 |
| User | created_at | DateTime | datetime | DateTime(timezone=True) | N/A | YES | func.now() | |

---

## Client

| Entity | Field | Flutter Type | FastAPI/Pydantic Type | SQLAlchemy/PostgreSQL Type | Proposed Drift/SQLite Type | Required | Default | Notes |
|---|---|---|---|---|---|---|---|---|
| Client | id | String | UUID | String(36), gen_random_uuid() | TEXT, UUID v4 | YES | UUID v4 (local) | Generated locally |
| Client | name | String | str (min 1, max 200) | String(200) | TEXT | YES | — | |
| Client | phone | String? | Optional[str] (max 40) | String(40) | TEXT | NO | NULL | |
| Client | email | String? | Optional[EmailStr] | String(255) | TEXT | NO | NULL | Email validation at app layer |
| Client | address | String? | Optional[str] (max 500) | String(500) | TEXT | NO | NULL | |
| Client | notes | String? | Optional[str] | Text | TEXT | NO | NULL | |
| Client | archived | bool | bool | Boolean | INTEGER (0/1) | YES | false (0) | Soft delete flag |
| Client | created_at | DateTime | datetime | DateTime(timezone=True), func.now() | TEXT (ISO 8601 UTC) | YES | current UTC time | Generated locally |
| Client | updated_at | DateTime | datetime | DateTime(timezone=True), func.now(), onupdate | TEXT (ISO 8601 UTC) | YES | current UTC time | Updated on every change |

**Delete behavior:** RESTRICT — cannot delete a client with linked projects. Enforced at application layer (check project count before delete).

**Indexes:** Consider adding index on `name` for search performance.

---

## Project

| Entity | Field | Flutter Type | FastAPI/Pydantic Type | SQLAlchemy/PostgreSQL Type | Proposed Drift/SQLite Type | Required | Default | Notes |
|---|---|---|---|---|---|---|---|---|
| Project | id | String | UUID | String(36), gen_random_uuid() | TEXT, UUID v4 | YES | UUID v4 (local) | Generated locally |
| Project | client_id | String | UUID | String(36), FK→clients.id RESTRICT | TEXT, FK→clients.id | YES | — | Foreign key enforced |
| Project | name | String | str (min 1, max 200) | String(200) | TEXT | YES | — | |
| Project | description | String? | Optional[str] | Text | TEXT | NO | NULL | |
| Project | budget | Decimal | Decimal (ge=0, max 14, dp 2) | Numeric(14,2), CHECK(>=0) | TEXT (Decimal string) | YES | — | Never REAL |
| Project | start_date | DateTime? | Optional[date] | Date | TEXT (YYYY-MM-DD) | NO | NULL | |
| Project | end_date | DateTime? | Optional[date] | Date, CHECK(>=start_date) | TEXT (YYYY-MM-DD) | NO | NULL | Validation at app layer |
| Project | status | String | Literal[5 values] | String(20) | TEXT | YES | "planning" | Enum: planning, active, completed, on_hold, cancelled |
| Project | created_at | DateTime | datetime | DateTime(timezone=True), func.now() | TEXT (ISO 8601 UTC) | YES | current UTC time | |

**Status enum values:** `planning`, `active`, `completed`, `on_hold`, `cancelled`

**Delete behavior:** CASCADE — deleting a project deletes its milestones, payments, and expenses. Enforced via FK ON DELETE CASCADE in SQLite.

**Indexes:** `client_id`, `status`.

**Budget ambiguity:** `Decision Required` — The field is named `budget` but may represent either the contract value or the planned budget. The current implementation treats it as a non-negative Decimal with no further semantics. This should be preserved as-is.

---

## Milestone

| Entity | Field | Flutter Type | FastAPI/Pydantic Type | SQLAlchemy/PostgreSQL Type | Proposed Drift/SQLite Type | Required | Default | Notes |
|---|---|---|---|---|---|---|---|---|
| Milestone | id | String | UUID | String(36), gen_random_uuid() | TEXT, UUID v4 | YES | UUID v4 (local) | |
| Milestone | project_id | String | UUID | String(36), FK→projects.id CASCADE | TEXT, FK→projects.id | YES | — | ON DELETE CASCADE |
| Milestone | title | String | str (min 1, max 255) | String(255) | TEXT | YES | — | |
| Milestone | description | String? | Optional[str] | Text | TEXT | NO | NULL | |
| Milestone | due_date | DateTime | date | Date | TEXT (YYYY-MM-DD) | YES | — | Date only, no time |
| Milestone | status | String | Literal[4 values] | String(20), CHECK IN(...) | TEXT | YES | "pending" | Enum: pending, in_progress, completed, overdue |
| Milestone | created_at | DateTime | datetime | DateTime(timezone=True), func.now() | TEXT (ISO 8601 UTC) | YES | current UTC time | |

**Status enum values:** `pending`, `in_progress`, `completed`, `overdue`

**Delete behavior:** CASCADE from project.

**Indexes:** `project_id`, `due_date`.

**Known inconsistency:** `MilestoneEntity` imports `decimal` but never uses it. Should be cleaned up during migration.

---

## Payment

| Entity | Field | Flutter Type | FastAPI/Pydantic Type | SQLAlchemy/PostgreSQL Type | Proposed Drift/SQLite Type | Required | Default | Notes |
|---|---|---|---|---|---|---|---|---|
| Payment | id | String | UUID | String(36), gen_random_uuid() | TEXT, UUID v4 | YES | UUID v4 (local) | |
| Payment | project_id | String | UUID | String(36), FK→projects.id CASCADE | TEXT, FK→projects.id | YES | — | ON DELETE CASCADE |
| Payment | amount | Decimal | Decimal (gt=0, max 14, dp 2) | Numeric(14,2), CHECK(>0) | TEXT (Decimal string) | YES | — | Never REAL |
| Payment | payment_date | DateTime | date | Date | TEXT (YYYY-MM-DD) | YES | — | Date only |
| Payment | method | String | Literal[4 values] | String(20), CHECK IN(...) | TEXT | YES | — | Enum: cash, bank_transfer, cheque, other |
| Payment | notes | String? | Optional[str] | Text | TEXT | NO | NULL | |
| Payment | created_at | DateTime | datetime | DateTime(timezone=True), func.now() | TEXT (ISO 8601 UTC) | YES | current UTC time | |

**Method enum values:** `cash`, `bank_transfer`, `cheque`, `other`

**Delete behavior:** CASCADE from project.

**Indexes:** `project_id`, `payment_date`.

**Not updatable:** `project_id` cannot be changed after creation.

---

## Expense

| Entity | Field | Flutter Type | FastAPI/Pydantic Type | SQLAlchemy/PostgreSQL Type | Proposed Drift/SQLite Type | Required | Default | Notes |
|---|---|---|---|---|---|---|---|---|
| Expense | id | String | UUID | String(36), gen_random_uuid() | TEXT, UUID v4 | YES | UUID v4 (local) | |
| Expense | project_id | String | UUID | String(36), FK→projects.id CASCADE | TEXT, FK→projects.id | YES | — | ON DELETE CASCADE |
| Expense | category | String | Literal[5 values] | String(100) | TEXT | YES | — | Enum: materials, labor, equipment, permits, other |
| Expense | amount | Decimal | Decimal (gt=0, max 14, dp 2) | Numeric(14,2), CHECK(>0) | TEXT (Decimal string) | YES | — | Never REAL |
| Expense | expense_date | DateTime | date | Date | TEXT (YYYY-MM-DD) | YES | — | Date only |
| Expense | notes | String? | Optional[str] | Text | TEXT | NO | NULL | |
| Expense | created_at | DateTime | datetime | DateTime(timezone=True), func.now() | TEXT (ISO 8601 UTC) | YES | current UTC time | |

**Category enum values:** `materials`, `labor`, `equipment`, `permits`, `other`

**Known inconsistency:** Backend has no DB-level CHECK constraint for category (Pydantic-only enforcement). The local database should add a CHECK constraint for improved data integrity.

**Delete behavior:** CASCADE from project.

**Indexes:** `project_id`, `expense_date`.

**Not updatable:** `project_id` cannot be changed after creation.

---

## Dashboard Result Models

These are derived models, not stored tables. They are computed from local queries.

| Model | Field | Flutter Type | Source |
|---|---|---|---|
| DashboardSummary | activeProjects | int | Count projects WHERE status = 'active' |
| DashboardSummary | completedProjects | int | Count projects WHERE status = 'completed' |
| DashboardSummary | totalClients | int | Count all clients (Decision Required: include archived?) |
| DashboardSummary | outstandingBalances | Decimal | Sum of project balances (payments_sum - expenses_sum) |
| DashboardSummary | totalPayments | Decimal | Sum of all payment amounts |
| DashboardSummary | totalExpenses | Decimal | Sum of all expense amounts |
| ProjectOverview | projectId | String | projects.id |
| ProjectOverview | name | String | projects.name |
| ProjectOverview | clientName | String | clients.name (JOIN) |
| ProjectOverview | status | String | projects.status |
| ProjectOverview | budget | Decimal | projects.budget |
| ProjectOverview | paymentsSum | Decimal | SUM(payments.amount) WHERE project_id = projects.id |
| ProjectOverview | expensesSum | Decimal | SUM(expenses.amount) WHERE project_id = projects.id |
| ProjectOverview | balance | Decimal | paymentsSum - expensesSum |
| MonthlyPoint | month | String | YYYY-MM format |
| MonthlyPoint | income | Decimal | SUM(payments.amount) WHERE month matches |
| MonthlyPoint | expense | Decimal | SUM(expenses.amount) WHERE month matches |

---

## Report Result Models

These are derived models, not stored tables.

| Model | Field | Flutter Type | Source |
|---|---|---|---|
| ProjectStatusItem | projectId | String | projects.id |
| ProjectStatusItem | name | String | projects.name |
| ProjectStatusItem | status | String | projects.status |
| ProjectStatusItem | budget | Decimal | projects.budget |
| ProjectStatusItem | totalPayments | Decimal | SUM(payments.amount) |
| ProjectStatusItem | totalExpenses | Decimal | SUM(expenses.amount) |
| ProjectStatusItem | balance | Decimal | totalPayments - totalExpenses |
| ProjectStatusItem | milestoneCount | int | COUNT(milestones) |
| ProjectStatusItem | completedMilestones | int | COUNT(milestones WHERE status = 'completed') |
| ProjectStatusItem | progressPct | Decimal | completedMilestones / milestoneCount * 100 |
| FinancialSummary | totalIncome | Decimal | SUM(payments.amount) in date range |
| FinancialSummary | totalExpenses | Decimal | SUM(expenses.amount) in date range |
| FinancialSummary | net | Decimal | totalIncome - totalExpenses |
| ExpenseAnalysis | grandTotal | Decimal | SUM(expenses.amount) with filters |
| CategoryBreakdown | percentage | Decimal | total / grandTotal * 100 |

---

## Attachments

> **Not currently implemented.** Attachments are planned for Sprint 05 but have not been implemented in the current codebase. The data model mapping for attachments will be added when they are implemented. The backup format (Phase 11) accounts for their future addition.

---

## Unresolved Decisions

| Decision | Context | Status |
|---|---|---|
| Should `total_clients` in dashboard include archived clients? | Verified: `dashboard_repository.counts()` counts all clients with no archived filter. The field name `total_clients` does not distinguish active from archived. | Decision Required |
| Is `budget` the contract value or the planned budget? | Field name is ambiguous. Backend stores `Numeric(14,2)` with `CHECK(>=0)`. No semantic documentation found. With multi-currency, budget must declare its currency. | Decision Required |
| Should the local database add a CHECK constraint for expense categories? | Verified: Backend has NO DB-level CHECK for expense categories (Pydantic-only enforcement). `Payment.method` and `Milestone.status` DO have DB CHECKs. | Decision Required |
| Should `overdue` milestone status be computed automatically or set manually? | Backend has the `overdue` enum value but no automatic computation. Status must be manually set. | Decision Required |
| What is the initial default YER/SAR exchange rate? | Needed for the settings seed value. ADR-005 confirmed the rate is stored as scaled INTEGER (scale 6) but the initial value is not specified. | Decision Required |
| How are mixed-currency expense lines linked? | ADR-005 confirmed mixed-currency expenses are stored as multiple linked lines. Proposed: shared `parent_expense_id` field. Needs confirmation. | Decision Required |
| Does `budget` on a project need currency designation? | ADR-005 confirmed multi-currency support. Budget currently has no currency. With multi-currency, budget must declare its currency. | Decision Required |
| What does `outstanding_balances` represent? | Verified: `outstanding_balances = total_payments - total_expenses` (overall net, NOT sum of negative balances). The field name is misleading. With multi-currency, this must be unified YER. | Decision Required |
| Should `profit_margin` be displayed as percentage or ratio? | Verified: `profit_margin = (balance / total_payments).quantize(Decimal("0.01"))` — no `* 100`. Value 0.50 means 50% margin. UI must multiply by 100. | Decision Required |

---

## Verified Enum Matrix

| Domain | Flutter values | FastAPI values | Database constraints | Match status | Notes |
|---|---|---|---|---|---|
| Project status | `planning`, `active`, `completed`, `on_hold`, `cancelled` (String, default `planning`) | `Literal["planning", "active", "completed", "on_hold", "cancelled"]` | NO DB CHECK constraint (Pydantic-only). Migration creates unused `sa.Enum` object. Column is `String(20)`. | Match | Flutter accepts any string; FastAPI rejects invalid values. No DB backstop. |
| Milestone status | `pending`, `in_progress`, `completed`, `overdue` (String, default `pending`) | `Literal["pending", "in_progress", "completed", "overdue"]` | DB CHECK: `status IN ('pending','in_progress','completed','overdue')` | Match | DB enforces at column level. |
| Payment method | `cash`, `bank_transfer`, `cheque`, `other` (String) | `Literal["cash", "bank_transfer", "cheque", "other"]` | DB CHECK: `method IN ('cash','bank_transfer','cheque','other')` | Match | DB enforces at column level. |
| Expense category | `materials`, `labor`, `equipment`, `permits`, `other` (String) | `Literal["materials", "labor", "equipment", "permits", "other"]` | NO DB CHECK constraint (Pydantic-only). Column is `String(100)`. | Match | Flutter accepts any string; FastAPI rejects invalid values. No DB backstop. |
| User role | N/A (not in Flutter) | `str`, default `"admin"`, server_default `"admin"` | NO DB CHECK. Column is `String(20)`. | N/A | Single admin user. No enum in code. |
| ReportType (Flutter only) | `projectStatus`, `financialSummary`, `expenseAnalysis` | N/A (backend uses URL paths) | N/A | Flutter-only | Used by `ReportFilters` to select endpoint. |

---

## Verified Date and Time Contracts

### Date-only fields

| Field | Entity | Backend type | Flutter DTO type | Flutter entity type | Serialization | Parse fallback |
|---|---|---|---|---|---|---|
| start_date | Project | `Date` (PG) | `String?` (JSON `start_date`) | `DateTime?` | `YYYY-MM-DD` string | `null` on parse failure |
| end_date | Project | `Date` (PG) | `String?` (JSON `end_date`) | `DateTime?` | `YYYY-MM-DD` string | `null` on parse failure |
| due_date | Milestone | `Date` (PG) | `String` (JSON `due_date`) | `DateTime` (non-null) | `YYYY-MM-DD` string | `DateTime.now()` on parse failure |
| payment_date | Payment | `Date` (PG) | `String` (JSON `payment_date`) | `DateTime` (non-null) | `YYYY-MM-DD` string | `DateTime.now()` on parse failure |
| expense_date | Expense | `Date` (PG) | `String` (JSON `expense_date`) | `DateTime` (non-null) | `YYYY-MM-DD` string | `DateTime.now()` on parse failure |

### DateTime/timestamp fields

| Field | Entity | Backend type | Flutter DTO type | Flutter entity type | Serialization | Parse fallback |
|---|---|---|---|---|---|---|
| created_at | All entities | `DateTime(timezone=True)`, `server_default=func.now()` | `String` (JSON `created_at`) | `DateTime` (non-null) | ISO 8601 with timezone (e.g., `2026-01-15T10:00:00Z`) | `DateTime.now()` on parse failure |
| updated_at | Client only | `DateTime(timezone=True)`, `server_default=func.now()`, `onupdate=func.now()` | `String` (JSON `updated_at`) | `DateTime` (non-null) | ISO 8601 with timezone | `DateTime.now()` on parse failure |

### Date parsing pattern (Flutter)

All date-only fields in Flutter DTOs append `T00:00:00` before parsing:
```dart
DateTime.tryParse('${dateString}T00:00:00')
```
This assumes the backend sends date-only strings (`YYYY-MM-DD`). If the backend sends full ISO timestamps for these fields, the append would create an invalid string and parsing would fail.

### Proposed storage policy (not yet implemented)

- **Date-only fields:** Store as `TEXT` in `YYYY-MM-DD` format. No time component. Display as date only.
- **Timestamp fields:** Store as `TEXT` in UTC ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`). Convert to local timezone only for display.
- **Parse fallback:** Replace `DateTime.now()` fallback with explicit error handling or null propagation. Silent fallback masks bad data.

---

## Verified Financial Contracts

### Monetary fields (current — single currency, backend)

| Field | Entity | Backend type | Flutter DTO type | Flutter entity type | Validation | Notes |
|---|---|---|---|---|---|---|
| budget | Project | `Numeric(14,2)`, `CHECK(>=0)` | `String` | `Decimal` | Pydantic: `Field(ge=0, max_digits=14, decimal_places=2)` | Serialized as string in JSON. No currency designation. |
| amount | Payment | `Numeric(14,2)`, `CHECK(>0)` | `String` | `Decimal` | Pydantic: `Field(gt=0, max_digits=14, decimal_places=2)` | Serialized as string in JSON. No currency designation. |
| amount | Expense | `Numeric(14,2)`, `CHECK(>0)` | `String` | `Decimal` | Pydantic: `Field(gt=0, max_digits=14, decimal_places=2)` | Serialized as string in JSON. No currency designation. |

### Monetary fields (proposed — multi-currency, local SQLite)

Per ADR-005, the local database adds multi-currency support. The following fields are PROPOSED and not yet implemented.

**Project:**

| Field | Proposed Drift/SQLite type | Required | Default | Notes |
|---|---|---|---|---|
| budget_amount | INTEGER | YES | — | Scaled by budget_currency_scale. |
| budget_currency | TEXT | YES | `"YER"` | `"YER"` (scale 0) or `"SAR"` (scale 2). Decision Required: does budget need a currency? |
| exchange_policy | TEXT | YES | `"per_transaction"` | `"fixed_rate"` or `"per_transaction"`. |
| fixed_exchange_rate | INTEGER | NO | NULL | Scale 6. Only used when exchange_policy = `"fixed_rate"`. |

**Payment:**

| Field | Proposed Drift/SQLite type | Required | Default | Notes |
|---|---|---|---|---|
| original_amount | INTEGER | YES | — | Scaled by original_currency scale. |
| original_currency | TEXT | YES | `"YER"` | `"YER"` (scale 0) or `"SAR"` (scale 2). |
| exchange_rate | INTEGER | NO | NULL | Scale 6. NULL when original_currency = `"YER"`. Required for non-YER. |
| converted_yer_amount | INTEGER | YES | — | Scale 0. Equal to original_amount when currency is YER. |
| rate_source | TEXT | NO | NULL | `"manual"`, `"default"`, `"project_fixed"`. NULL for YER. |
| rate_date | TEXT | NO | NULL | ISO date. NULL for YER. |

**Expense:**

| Field | Proposed Drift/SQLite type | Required | Default | Notes |
|---|---|---|---|---|
| original_amount | INTEGER | YES | — | Scaled by original_currency scale. |
| original_currency | TEXT | YES | `"YER"` | `"YER"` or `"SAR"`. |
| exchange_rate | INTEGER | NO | NULL | Scale 6. NULL when YER. |
| converted_yer_amount | INTEGER | YES | — | Scale 0. |
| rate_source | TEXT | NO | NULL | NULL for YER. |
| rate_date | TEXT | NO | NULL | NULL for YER. |
| parent_expense_id | TEXT | NO | NULL | For mixed-currency expenses: shared parent ID linking multiple lines. |

**Settings (default exchange rate):**

| Field | Proposed Drift/SQLite type | Required | Default | Notes |
|---|---|---|---|---|
| default_exchange_rate | INTEGER | YES | Decision Required | Scale 6. Suggested value for new transactions. |

### Derived financial fields

| Metric | Source fields | Current formula | Current layer | Result type | Precision behavior | Ambiguity |
|---|---|---|---|---|---|---|
| balance (project overview) | payments_sum, expenses_sum | `payments_sum - expenses_sum` | DashboardService | `Decimal` | Not quantized | None |
| balance (report) | total_payments, total_expenses | `total_payments - total_expenses` | ReportService | `Decimal` | Not quantized | None |
| outstanding_balances | total_payments, total_expenses | `total_payments - total_expenses` | DashboardService | `Decimal` | Not quantized | **Misleading name**: returns overall net, not sum of negative balances |
| net (financial summary) | total_income, total_expenses | `total_income - total_expenses` | ReportRepository | `Decimal` | Not quantized | None |
| profit_margin | balance, total_payments | `(balance / total_payments).quantize(Decimal("0.01"))` if `total_payments > 0` else `Decimal("0.00")` | ProfitabilityService | `Decimal` | Quantized to 0.01 | **Ratio not percentage**: 0.50 = 50%, no `* 100` |
| progress_pct | completed_milestones, milestone_count | `(completed / total * 100).quantize(Decimal("0.01"))` if `milestone_count > 0` else `Decimal("0.00")` | ReportService | `Decimal` | Quantized to 0.01 | None |
| percentage (expense category) | total, grand_total | `(total / grand_total * 100).quantize(Decimal("0.01"))` if `grand_total > 0` else `Decimal("0.00")` | ReportRepository | `Decimal` | Quantized to 0.01 | None |
| total_payments (dashboard) | All payment amounts | `coalesce(sum(Payment.amount), 0)` | DashboardRepository | `Decimal` | `Decimal(str(result or 0))` | None |
| total_expenses (dashboard) | All expense amounts | `coalesce(sum(Expense.amount), 0)` | DashboardRepository | `Decimal` | `Decimal(str(result or 0))` | None |
| payments_sum (project overview) | Payment.amount per project | `coalesce(sum(Payment.amount), 0)` via JOIN | DashboardRepository | `Decimal` | **DEFECT R-013**: Row multiplication when project has both payments and expenses | Inflated by expense count |
| expenses_sum (project overview) | Expense.amount per project | `coalesce(sum(Expense.amount), 0)` via JOIN | DashboardRepository | `Decimal` | **DEFECT R-013**: Row multiplication | Inflated by payment count |

### Known Decimal behavior in Flutter

- `Decimal.parse('0.00').toString()` returns `'0'` (trailing zeros stripped).
- `Decimal.parse('150000.50').toString()` returns `'150000.5'` (trailing zero stripped).
- `Decimal` division (`/`) returns `Rational`, not `Decimal`. `Rational.toString()` gives fraction form (e.g., `'7/10'`).
- The backend serializes `Decimal` as string with 2 decimal places via Pydantic `model_dump(mode="json")`.
- The Flutter `decimal` package does NOT preserve trailing zeros. This is a behavioral difference between backend serialization and Flutter local representation.

---

## Verified Delete and Archive Matrix

| Entity | Current behavior | Financial/historical risk | Proposed local policy | Decision status |
|---|---|---|---|---|
| Client delete | RESTRICT: `CLIENT_HAS_PROJECTS` 409 if client has any project (any status). DB FK `ondelete="RESTRICT"` is backstop. | Medium: prevents loss of project history. | Preserve: block delete when projects exist. | Accepted |
| Client archive | Sets `archived=true`. Does NOT delete. Client remains in database. | Low: no data loss. | Preserve: archive via field update. | Accepted |
| Project delete | CASCADE: deletes milestones, payments, expenses. DB FK `ondelete="CASCADE"`. | High: financial records (payments, expenses) are permanently lost. | Decision Required: cascade vs. soft delete. | Decision Required |
| Milestone delete | Direct delete (CASCADE from project). Individual delete has no special guard. | Low: milestones are progress indicators, not financial records. | Preserve: direct delete. | Accepted |
| Payment delete | Direct delete (CASCADE from project). Individual delete has no special guard. | High: financial audit concern. Payment records are evidence of transactions. | Decision Required: hard delete vs. soft delete. | Decision Required |
| Expense delete | Direct delete (CASCADE from project). Individual delete has no special guard. | High: financial audit concern. Expense records are evidence of costs. | Decision Required: hard delete vs. soft delete. | Decision Required |
# Phase 08 Dashboard derived contracts

- `DashboardSummary`: integer counts and converted-YER totals, plus derived
  `netCashFlowYer`.
- `DashboardProjectOverview`: display fields, integer finance totals, derived
  net cash flow, milestone counts, and integer 0–100 progress.
- `DashboardFinanceMonth`: integer year/month and finance totals, derived net
  cash flow, and canonical `YYYY-MM` key.
- These are query results, not tables; authoritative money never uses `double`
  or SQLite `REAL`.
