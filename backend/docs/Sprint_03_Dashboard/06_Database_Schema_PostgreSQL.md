# 06 — Database Schema & PostgreSQL (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. No New Tables
Sprint 03 does **not** introduce any new persistence. The dashboard reads existing tables from Sprints 01–02:

| Table | PK | Relevant columns |
| --- | --- | --- |
| clients | id (uuid) | name |
| projects | id (uuid) | client_id, name, status, budget |
| payments | id (uuid) | project_id, amount, paid_at |
| expenses | id (uuid) | project_id, amount, incurred_at |

No Alembic migration is required for new schema objects. Only optional index migrations may be added (see §4).

## 2. Aggregation Queries

### 2.1 Active / completed project counts
```sql
SELECT status, COUNT(*) AS cnt
  FROM projects
 WHERE status IN ('ACTIVE','COMPLETED')
 GROUP BY status;
```

### 2.2 Total clients
```sql
SELECT COUNT(*) AS total_clients FROM clients;
```

### 2.3 Outstanding balance (sum payments − sum expenses)
```sql
SELECT
  (SELECT COALESCE(SUM(amount),0) FROM payments)  AS total_payments,
  (SELECT COALESCE(SUM(amount),0) FROM expenses)  AS total_expenses,
  (SELECT COALESCE(SUM(amount),0) FROM payments)
  - (SELECT COALESCE(SUM(amount),0) FROM expenses) AS outstanding;
```

### 2.4 Projects overview (join + per-project sums)
```sql
SELECT p.id, p.name, c.name AS client_name, p.status, p.budget,
       COALESCE(SUM(pay.amount),0) AS payments_sum,
       COALESCE(SUM(exp.amount),0) AS expenses_sum,
       COALESCE(SUM(pay.amount),0) - COALESCE(SUM(exp.amount),0) AS balance
  FROM projects p
  JOIN clients  c   ON c.id = p.client_id
  LEFT JOIN payments pay ON pay.project_id = p.id
  LEFT JOIN expenses exp ON exp.project_id = p.id
 GROUP BY p.id, c.name
 ORDER BY p.name;
```

### 2.5 Monthly cash flow (last 12 months)
```sql
-- income
SELECT to_char(date_trunc('month', paid_at), 'YYYY-MM') AS month,
       COALESCE(SUM(amount),0) AS income
  FROM payments
 WHERE paid_at >= date_trunc('month', NOW()) - INTERVAL '11 months'
 GROUP BY 1
 ORDER BY 1;

-- expense
SELECT to_char(date_trunc('month', incurred_at), 'YYYY-MM') AS month,
       COALESCE(SUM(amount),0) AS expense
  FROM expenses
 WHERE incurred_at >= date_trunc('month', NOW()) - INTERVAL '11 months'
 GROUP BY 1
 ORDER BY 1;
```
Merge income/expense per `month` in the repository; pad missing months with `0.00`.

## 3. Data Types & Precision
- `amount` columns are `NUMERIC(14,2)` — sums remain exact `Decimal`.
- `paid_at` / `incurred_at` are `TIMESTAMPTZ` (UTC). Monthly grouping uses `date_trunc('month', <ts>)`.
- `status` is a `VARCHAR` enum-backed column; filter via string literals matching `ProjectStatus` enum.

## 4. Index Recommendations
Add (if missing) to keep aggregations fast as volume grows:

```sql
CREATE INDEX IF NOT EXISTS ix_projects_status       ON projects(status);
CREATE INDEX IF NOT EXISTS ix_payments_project_id   ON payments(project_id);
CREATE INDEX IF NOT EXISTS ix_payments_paid_at      ON payments(paid_at);
CREATE INDEX IF NOT EXISTS ix_expenses_project_id   ON expenses(project_id);
CREATE INDEX IF NOT EXISTS ix_expenses_incurred_at  ON expenses(incurred_at);
```

These are non-breaking; ship via an Alembic migration `s03_dashboard_indexes`.

## 5. Expected Query Performance
| Query | Estimated rows scanned | Expected time |
| --- | --- | --- |
| Counts | indexed `status` | < 20 ms |
| Totals | full scan payments/expenses | < 80 ms @ 10 k rows |
| Projects overview | hash join, grouped | < 150 ms @ 1 k projects |
| Finance 12 mo | range scan on date index | < 60 ms |

## 6. Migration Notes
- If indexes are added, generate migration: `alembic revision --autogenerate -m "s03 dashboard indexes"`.
- Downgrade drops indexes only; no table changes.
- Verify on staging with `EXPLAIN ANALYZE` for each aggregation query.