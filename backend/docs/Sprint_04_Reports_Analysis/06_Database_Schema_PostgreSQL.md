# Sprint 04 — Database Schema & PostgreSQL

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. No New Tables

Sprint 04 introduces no new persistent tables and no Alembic migration is required for schema. Reports are computed on demand via aggregation queries over the existing tables: `clients`, `projects`, `milestones`, `payments`, `expenses`.

A migration may still be added solely to **create indexes** (see §4) if they do not already exist.

## 2. Relevant Existing Schema (recap)

- `projects(id uuid pk, client_id uuid, name, status, budget numeric, ...)` — statuses: `active`, `completed`, `on_hold`, `cancelled`.
- `payments(id uuid pk, project_id uuid, amount numeric, payment_date date)`.
- `expenses(id uuid pk, project_id uuid, category, amount numeric, expense_date date)`.
- `milestones(id uuid pk, project_id uuid, is_completed bool)`.

## 3. Aggregation Queries

### 3.1 Project Status Report

```sql
SELECT p.id, p.name, p.status, p.budget,
       COALESCE(SUM(pay.amount), 0) AS total_payments,
       COALESCE(SUM(ex.amount), 0)  AS total_expenses,
       COUNT(m.id)                              AS milestone_count,
       COUNT(m.id) FILTER (WHERE m.is_completed) AS completed_milestones
FROM projects p
LEFT JOIN payments   pay ON pay.project_id = p.id
LEFT JOIN expenses   ex  ON ex.project_id  = p.id
LEFT JOIN milestones m   ON m.project_id   = p.id
WHERE (:project_id IS NULL OR p.id = :project_id)
  AND (:status     IS NULL OR p.status = :status)
GROUP BY p.id, p.name, p.status, p.budget
ORDER BY p.name;
```

Balance and `progress_pct` computed in service (Decimal). Note: joining payments + expenses on the same project multiplies rows (cartesian). Prefer separate subqueries to avoid double counting:

```sql
SELECT p.id, p.name, p.status, p.budget,
       COALESCE(ps.total_payments, 0)  AS total_payments,
       COALESCE(es.total_expenses, 0) AS total_expenses,
       COALESCE(ms.milestone_count, 0),
       COALESCE(ms.completed, 0)
FROM projects p
LEFT JOIN (SELECT project_id, SUM(amount) total_payments FROM payments GROUP BY project_id) ps ON ps.project_id = p.id
LEFT JOIN (SELECT project_id, SUM(amount) total_expenses FROM expenses GROUP BY project_id) es ON es.project_id = p.id
LEFT JOIN (SELECT project_id, COUNT(*) milestone_count,
                  COUNT(*) FILTER (WHERE is_completed) completed
           FROM milestones GROUP BY project_id) ms ON ms.project_id = p.id
WHERE (:project_id IS NULL OR p.id = :project_id)
  AND (:status IS NULL OR p.status = :status);
```

### 3.2 Financial Summary Report

```sql
SELECT COALESCE(SUM(amount), 0) income
FROM payments
WHERE (:start_date IS NULL OR payment_date >= :start_date)
  AND (:end_date   IS NULL OR payment_date <= :end_date);

SELECT COALESCE(SUM(amount), 0) expenses
FROM expenses
WHERE (:start_date IS NULL OR expense_date >= :start_date)
  AND (:end_date   IS NULL OR expense_date <= :end_date);

SELECT p.id, p.name,
       COALESCE(SUM(pay.amount),0) income,
       COALESCE(SUM(ex.amount),0)  expenses
FROM projects p
LEFT JOIN payments pay ON pay.project_id = p.id
   AND (:start_date IS NULL OR pay.payment_date >= :start_date)
   AND (:end_date   IS NULL OR pay.payment_date <= :end_date)
LEFT JOIN expenses ex ON ex.project_id = p.id
   AND (:start_date IS NULL OR ex.expense_date >= :start_date)
   AND (:end_date   IS NULL OR ex.expense_date <= :end_date)
GROUP BY p.id, p.name;
```

### 3.3 Expense Analysis Report

```sql
SELECT category, SUM(amount) total
FROM expenses
WHERE (:start_date IS NULL OR expense_date >= :start_date)
  AND (:end_date   IS NULL OR expense_date <= :end_date)
  AND (:project_id IS NULL OR project_id = :project_id)
GROUP BY category
ORDER BY total DESC;
```

Percentages: `ROUND(total / NULLIF(grand_total,0) * 100, 2)` — computed in service with Decimal.

## 4. Index Recommendations

```sql
CREATE INDEX IF NOT EXISTS idx_payments_project_date  ON payments(project_id, payment_date);
CREATE INDEX IF NOT EXISTS idx_payments_date          ON payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_expenses_project_date  ON expenses(project_id, expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_date_category ON expenses(expense_date, category);
CREATE INDEX IF NOT EXISTS idx_expenses_project_category ON expenses(project_id, category);
CREATE INDEX IF NOT EXISTS idx_projects_status        ON projects(status);
```

## 5. Performance Notes

- Single-tenant, modest volume — on-demand aggregation is sufficient.
- Guard against very large ranges (consider a 1-year soft cap, see `13_Environment_Config.md`).
- All money columns are `numeric`; never cast to float.
- Timestamps/dates stored as UTC; filters compare on date values.