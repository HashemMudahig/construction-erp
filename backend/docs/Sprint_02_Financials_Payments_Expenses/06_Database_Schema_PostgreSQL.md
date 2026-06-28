# 06 — Database Schema (PostgreSQL) — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. DDL

### 1.1 milestones
```sql
CREATE TABLE milestones (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    due_date    DATE NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending','in_progress','completed','overdue')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_milestones_project_id ON milestones(project_id);
CREATE INDEX idx_milestones_due_date   ON milestones(due_date);
```

### 1.2 payments
```sql
CREATE TABLE payments (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id   UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    amount       NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL,
    method       VARCHAR(20) NOT NULL
        CHECK (method IN ('cash','bank_transfer','cheque','other')),
    notes        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_payments_project_id   ON payments(project_id);
CREATE INDEX idx_payments_payment_date ON payments(payment_date);
```

### 1.3 expenses
```sql
CREATE TABLE expenses (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id   UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    category     VARCHAR(100) NOT NULL,
    amount       NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    expense_date DATE NOT NULL,
    notes        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_expenses_project_id   ON expenses(project_id);
CREATE INDEX idx_expenses_expense_date ON expenses(expense_date);
```

## 2. Foreign Key Policy

| Child | Parent | ON DELETE | Rationale |
| --- | --- | --- | --- |
| milestones.project_id | projects.id | CASCADE | Project delete removes its milestones. |
| payments.project_id | projects.id | CASCADE | Prevent orphan payments that would corrupt profitability sums. |
| expenses.project_id | projects.id | CASCADE | Prevent orphan expenses that would corrupt profitability sums. |

`RESTRICT` was considered to force explicit cleanup, but the single-admin app benefits from the simpler CASCADE contract documented in ADR-S02-03.

## 3. Money & Enums

- All amounts are `NUMERIC(14,2)` with a `CHECK (amount > 0)` constraint at the DB level, mirroring the Pydantic `Field(gt=0)`.
- `status`, `method` are `VARCHAR + CHECK` enums (portable, no PG enum type dependency). `category` is free-text `VARCHAR(100)` with an application-level allowlist (materials, labor, equipment, permits, other).
- Timestamps are `TIMESTAMPTZ` (UTC).

## 4. Indexes

| Index | Purpose |
| --- | --- |
| idx_*_project_id | Filter lists by project; profitability `SUM … WHERE project_id`. |
| idx_payments_payment_date | Chronological ordering/filter. |
| idx_expenses_expense_date | Chronological ordering/filter. |
| idx_milestones_due_date | Overdue detection query. |

## 5. Alembic Migration Plan

1. Create a new revision on top of the Sprint 01 head revision:
   `alembic revision -m "s02_milestones_payments_expenses"`.
2. The upgrade() function creates the three tables and the five indexes above (use `op.create_table`, `op.create_index`).
3. The downgrade() function drops tables in reverse dependency order (`expenses`, `payments`, `milestones`).
4. Run `alembic upgrade head` in dev and staging. The database grows from 3 tables (Sprint 01: users, clients, projects) to **6 tables**.
5. No data migration is required — Sprint 01 projects are eligible to receive financial records immediately after the migration.