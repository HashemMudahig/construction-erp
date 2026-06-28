# Sprint 04 — Backend Developer Guide

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. ReportService Methods

File: `app/services/report_service.py`. All methods are read-only and accept optional filters.

```python
class ReportService:
    def __init__(self, session: AsyncSession) -> None: ...

    async def project_status_report(
        self, project_id: UUID | None = None, status: str | None = None
    ) -> list[ProjectStatusReportItem]: ...

    async def financial_summary_report(
        self, start_date: date | None = None, end_date: date | None = None
    ) -> FinancialSummaryReport: ...

    async def expense_analysis_report(
        self, start_date: date | None = None,
        end_date: date | None = None,
        project_id: UUID | None = None,
    ) -> ExpenseAnalysisReport: ...
```

## 2. Repository Aggregation Queries

### 2.1 Project Status — join projects + clients + sums

```sql
SELECT p.id, p.name, p.status, p.budget,
       COALESCE(SUM(pay.amount), 0)  AS total_payments,
       COALESCE(SUM(ex.amount), 0)   AS total_expenses,
       COUNT(m.id)                   AS milestone_count,
       COUNT(m.id) FILTER (WHERE m.is_completed) AS completed_milestones
FROM projects p
JOIN clients c ON c.id = p.client_id
LEFT JOIN payments pay ON pay.project_id = p.id
LEFT JOIN expenses ex  ON ex.project_id  = p.id
LEFT JOIN milestones m ON m.project_id    = p.id
WHERE (:project_id IS NULL OR p.id = :project_id)
  AND (:status IS NULL OR p.status = :status)
GROUP BY p.id, p.name, p.status, p.budget;
```

Balance = `budget - total_expenses` (or `total_payments - total_expenses`; confirm per domain rule in PRD §7).

### 2.2 Financial Summary — sum by date range

```sql
SELECT COALESCE(SUM(amount), 0) AS income
FROM payments
WHERE (:start_date IS NULL OR payment_date >= :start_date)
  AND (:end_date   IS NULL OR payment_date <= :end_date);

SELECT COALESCE(SUM(amount), 0) AS expenses
FROM expenses
WHERE (:start_date IS NULL OR expense_date >= :start_date)
  AND (:end_date   IS NULL OR expense_date <= :end_date);
```

Per-project totals: same sums grouped by `project_id`.

### 2.3 Expense Analysis — group by category

```sql
SELECT e.category, e.project_id, p.name AS project_name,
       SUM(e.amount) AS total
FROM expenses e
JOIN projects p ON p.id = e.project_id
WHERE (:start_date IS NULL OR e.expense_date >= :start_date)
  AND (:end_date   IS NULL OR e.expense_date <= :end_date)
  AND (:project_id IS NULL OR e.project_id = :project_id)
GROUP BY e.category, e.project_id, p.name;
```

Percentages computed in service: `pct = total / grand_total * 100` using `Decimal`.

## 3. Schemas (`app/schemas/reports.py`)

```python
class ProjectStatusReportItem(BaseModel):
    project_id: UUID
    name: str
    status: str
    budget: Decimal
    total_payments: Decimal
    total_expenses: Decimal
    balance: Decimal
    milestone_count: int
    completed_milestones: int
    progress_pct: Decimal  # completed / total * 100

class FinancialSummaryReport(BaseModel):
    start_date: date | None
    end_date: date | None
    total_income: Decimal
    total_expenses: Decimal
    net: Decimal
    per_project: list[ProjectFinancial]

class ProjectFinancial(BaseModel):
    project_id: UUID
    name: str
    income: Decimal
    expenses: Decimal
    net: Decimal

class ExpenseCategoryBreakdown(BaseModel):
    category: str
    total: Decimal
    percentage: Decimal

class ExpenseAnalysisReport(BaseModel):
    start_date: date | None
    end_date: date | None
    project_id: UUID | None
    grand_total: Decimal
    by_category: list[ExpenseCategoryBreakdown]
    by_project: list[ProjectExpense]
```

## 4. Routers (`app/routers/reports.py`)

Three GET endpoints, all under `/api/v1/reports`, JWT required (`Depends(get_current_admin)`).

```python
@router.get("/project-status")
async def project_status(
    project_id: UUID | None = None,
    status: str | None = None,
    _: Admin = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session),
) -> StandardResponse[list[ProjectStatusReportItem]]: ...

@router.get("/financial-summary")
async def financial_summary(
    start_date: date | None = None,
    end_date: date | None = None,
    _: Admin = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session),
) -> StandardResponse[FinancialSummaryReport]: ...

@router.get("/expense-analysis")
async def expense_analysis(
    start_date: date | None = None,
    end_date: date | None = None,
    project_id: UUID | None = None,
    _: Admin = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session),
) -> StandardResponse[ExpenseAnalysisReport]: ...
```

Validate `start_date <= end_date` in router/service; raise `INVALID_DATE_RANGE` otherwise. Validate `project_id` exists; raise `PROJECT_NOT_FOUND` otherwise.

## 5. Conventions

- All money fields: `Decimal`, quantized to 2 decimals.
- Dates: inclusive bounds, UTC.
- Response envelope: `{"success": true, "message": "...", "data": ...}`.
- No writes anywhere in the reports module.