# 08 — Security & Access Control — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Authentication

Every Sprint S02 endpoint (read and write) is protected by the Sprint 01 JWT bearer dependency `Depends(get_current_user)`. A missing, malformed, or expired token yields `401 Unauthorized` before any business logic runs. There is no anonymous access to financial data.

## 2. Single-Admin Model

The system remains a single administrative user. There is no RBAC, no project ownership, and no per-row authorization in v1. Any valid JWT (the one admin) can read and mutate any financial record. This simplicity was established in Sprint 01 and is carried forward unchanged.

## 3. Input Validation — Defense in Depth

Validation is enforced at three layers to prevent malformed money data:

| Layer | Rule |
| --- | --- |
| Pydantic schema | `amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)`; enum `Literal[...]` for method/status/category. |
| Service | Re-checks `amount > 0`, validates `project_id` existence, enforces milestone status transition rules. |
| Database | `CHECK (amount > 0)` on `payments.amount` and `expenses.amount`; `CHECK` on enum columns. |

A negative or zero amount is rejected at the schema; if it ever reaches the DB, the `CHECK` constraint aborts the transaction, guaranteeing no negative money is ever persisted.

## 4. Orphan Prevention

`project_id` existence is verified by the service before inserting any payment, expense, or milestone. Additionally, all FKs use `ON DELETE CASCADE`, so deleting a project removes dependent financial rows atomically — there is no path to an orphan payment/expense that would corrupt the profitability `SUM`.

## 5. No Direct Balance Mutation

Profitability is computed on demand from `SUM(amount)` queries. No `balance` column exists on `projects`, so there is no API or path that can mutate a stored balance directly. This removes an entire class of tampering/reconciliation bugs.

## 6. Audit Logging

The service layer emits structured audit log entries for mutating financial operations:

| Event | Fields logged |
| --- | --- |
| `payment_created` | payment_id, project_id, amount, method, payment_date, actor (admin user id), timestamp |
| `payment_updated` | payment_id, project_id, changed fields |
| `expense_created` | expense_id, project_id, category, amount, expense_date, actor, timestamp |
| `milestone_completed` | milestone_id, project_id, previous_status, new_status, timestamp |

Logs are written to the application logger (stdout/structured) — no separate audit table in v1 (deferred to S03). Amounts are logged as `Decimal` strings to preserve precision.

## 7. Transport & Secrets

- HTTPS only in production; HSTS enabled at the reverse proxy.
- JWT secret, DB URL, and admin credentials remain in environment variables (Sprint 01 config) — no secrets in code or migrations.
- Passwords hashed with bcrypt (unchanged from Sprint 01).

## 8. Threat Mitigation Summary

| Threat | Mitigation |
| --- | --- |
| Negative/zero amount injection | Schema + service + DB CHECK. |
| Orphan financial record | project_id existence check + CASCADE. |
| Tampered balance | Computed on demand, no stored column. |
| Unauthorized access | JWT on all endpoints. |
| SQL injection | SQLAlchemy parameterized queries (no raw string interpolation). |
| Mass assignment | Explicit Create/Update schemas, not raw ORM models. |