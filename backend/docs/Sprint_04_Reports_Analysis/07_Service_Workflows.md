# Sprint 04 — Service Workflows

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Project Status Report

```mermaid
sequenceDiagram
    participant FE as Flutter ReportsScreen
    participant RT as ReportsRouter
    participant Svc as ReportService
    participant Repo as Repositories
    participant DB as PostgreSQL
    FE->>RT: GET /reports/project-status?project_id&status
    RT->>RT: JWT verify; validate params
    RT->>Svc: project_status_report(project_id, status)
    Svc->>Repo: get_project_status_rows(filters)
    Repo->>DB: aggregation query (subquery form)
    DB-->>Repo: rows
    Repo-->>Svc: raw rows
    Svc->>Svc: compute balance, progress_pct (Decimal)
    Svc-->>RT: list[ProjectStatusReportItem]
    RT-->>FE: 200 {success, message, data[]}
```

## 2. Financial Summary Report

```mermaid
sequenceDiagram
    participant FE as Flutter ReportsScreen
    participant RT as ReportsRouter
    participant Svc as ReportService
    participant Repo as Repositories
    participant DB as PostgreSQL
    FE->>RT: GET /reports/financial-summary?start_date&end_date
    RT->>RT: JWT verify; start_date <= end_date
    RT->>Svc: financial_summary_report(start_date, end_date)
    Svc->>Repo: sum_payments(range); sum_expenses(range); per_project(range)
    Repo->>DB: 3 aggregation queries
    DB-->>Repo: income, expenses, per-project rows
    Repo-->>Svc: totals
    Svc->>Svc: net = income - expenses (Decimal)
    Svc-->>RT: FinancialSummaryReport
    RT-->>FE: 200 {success, message, data}
```

## 3. Expense Analysis Report

```mermaid
sequenceDiagram
    participant FE as Flutter ReportsScreen
    participant RT as ReportsRouter
    participant Svc as ReportService
    participant Repo as ExpenseRepository
    participant DB as PostgreSQL
    FE->>RT: GET /reports/expense-analysis?start_date&end_date&project_id
    RT->>RT: JWT verify; validate dates; project_id exists
    RT->>Svc: expense_analysis_report(filters)
    Svc->>Repo: expenses_grouped_by_category(filters); expenses_grouped_by_project(filters)
    Repo->>DB: GROUP BY queries
    DB-->>Repo: category rows; project rows
    Repo-->>Svc: grouped totals
    Svc->>Svc: grand_total = SUM(categories)
    Svc->>Svc: pct = total / grand_total * 100 (Decimal)
    Svc-->>RT: ExpenseAnalysisReport
    RT-->>FE: 200 {success, message, data}
```

## 4. Business Rules Applied in Workflows

- **Read-only:** No INSERT/UPDATE/DELETE in any report path. Services never call repository write methods.
- **UTC:** All date comparisons use UTC; frontend sends `YYYY-MM-DD`.
- **Decimal money:** All `amount` values are `Numeric`; sums use `COALESCE(SUM(amount), 0)`. Percentages computed via `Decimal` division, quantized to 2 dp.
- **Inclusive bounds:** `>= start_date AND <= end_date`.
- **Filter omission:** A NULL filter means "all"; the query uses `(:param IS NULL OR col = :param)` pattern so the same query plan handles both.
- **Validation ordering:** JWT first, then date range, then project_id existence, then run query. Fail fast.
- **Empty results:** Valid filters with no matching rows return `200` with empty arrays / zero totals (not an error).