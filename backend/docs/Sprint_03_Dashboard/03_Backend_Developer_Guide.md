# 03 — Backend Developer Guide (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Module Layout
```
app/
  routers/dashboard.py
  services/dashboard_service.py
  repositories/dashboard_repository.py
  schemas/dashboard.py
```
Register the router in `app/main.py`: `app.include_router(dashboard.router, prefix="/api/v1/dashboard", tags=["dashboard"])`.

## 2. Schemas (`app/schemas/dashboard.py`)
```python
from pydantic import BaseModel, Field
from decimal import Decimal
from datetime import date
from uuid import UUID
from app.schemas.common import ResponseEnvelope  # S01

class DashboardSummaryResponse(BaseModel):
    active_projects: int
    completed_projects: int
    total_clients: int
    outstanding_balances: Decimal = Field(max_digits=14, decimal_places=2)
    total_payments: Decimal = Field(max_digits=14, decimal_places=2)
    total_expenses: Decimal = Field(max_digits=14, decimal_places=2)

class ProjectOverviewItem(BaseModel):
    project_id: UUID
    name: str
    client_name: str
    status: str
    budget: Decimal
    payments_sum: Decimal
    expenses_sum: Decimal
    balance: Decimal

class MonthlyPoint(BaseModel):
    month: str  # YYYY-MM
    income: Decimal
    expense: Decimal

class FinanceOverviewResponse(BaseModel):
    currency: str
    months: list[MonthlyPoint]
```

## 3. Repository (`app/repositories/dashboard_repository.py`)
All queries use the existing SQLAlchemy session; sums return `Decimal`.

```python
from sqlalchemy.orm import Session
from sqlalchemy import select, func, and_
from app.models.project import Project
from app.models.client import Client
from app.models.payment import Payment
from app.models.expense import Expense
from app.models.enums import ProjectStatus

class DashboardRepository:
    def __init__(self, db: Session):
        self.db = db

    def counts(self) -> dict:
        active = self.db.scalar(select(func.count()).select_from(Project)
                                .where(Project.status == ProjectStatus.ACTIVE))
        completed = self.db.scalar(select(func.count()).select_from(Project)
                                    .where(Project.status == ProjectStatus.COMPLETED))
        clients = self.db.scalar(select(func.count()).select_from(Client))
        return {"active": active, "completed": completed, "clients": clients}

    def totals(self) -> dict:
        pay = self.db.scalar(select(func.coalesce(func.sum(Payment.amount), 0))) or 0
        exp = self.db.scalar(select(func.coalesce(func.sum(Expense.amount), 0))) or 0
        return {"payments": Decimal(pay), "expenses": Decimal(exp)}

    def projects_overview(self) -> list[dict]:
        q = (
            select(
                Project.id, Project.name, Client.name.label("client_name"),
                Project.status, Project.budget,
                func.coalesce(func.sum(Payment.amount), 0).label("payments_sum"),
                func.coalesce(func.sum(Expense.amount), 0).label("expenses_sum"),
            )
            .join(Client, Client.id == Project.client_id)
            .outerjoin(Payment, Payment.project_id == Project.id)
            .outerjoin(Expense, Expense.project_id == Project.id)
            .group_by(Project.id, Client.name)
            .order_by(Project.name)
        )
        rows = self.db.execute(q).all()
        return [dict(r._mapping) for r in rows]

    def finance_overview(self, months: int = 12) -> list[dict]:
        q = (
            select(
                func.to_char(func.date_trunc("month", Payment.paid_at), "YYYY-MM").label("m"),
                func.coalesce(func.sum(Payment.amount), 0).label("income"),
            )
            .where(Payment.paid_at >= func.now() - func.cast(f"{months} months", ...)
            .group_by("m")
        )
        # mirror for expenses then merge by month (omitted for brevity)
```

### Example raw SQL for monthly cash flow
```sql
SELECT to_char(date_trunc('month', paid_at), 'YYYY-MM') AS month,
       COALESCE(SUM(amount), 0) AS income
  FROM payments
 WHERE paid_at >= date_trunc('month', NOW()) - INTERVAL '11 months'
 GROUP BY 1
 ORDER BY 1;
```

## 4. Service (`app/services/dashboard_service.py`)
```python
class DashboardService:
    def __init__(self, db: Session):
        self.repo = DashboardRepository(db)

    def get_summary(self) -> DashboardSummaryResponse:
        c = self.repo.counts(); t = self.repo.totals()
        outstanding = t["payments"] - t["expenses"]
        return DashboardSummaryResponse(
            active_projects=c["active"], completed_projects=c["completed"],
            total_clients=c["clients"], outstanding_balances=outstanding,
            total_payments=t["payments"], total_expenses=t["expenses"],
        )

    def get_projects_overview(self) -> list[ProjectOverviewItem]:
        rows = self.repo.projects_overview()
        out = []
        for r in rows:
            balance = Decimal(r["payments_sum"]) - Decimal(r["expenses_sum"])
            out.append(ProjectOverviewItem(
                project_id=r["id"], name=r["name"], client_name=r["client_name"],
                status=r["status"].value if hasattr(r["status"], "value") else r["status"],
                budget=Decimal(r["budget"]), payments_sum=Decimal(r["payments_sum"]),
                expenses_sum=Decimal(r["expenses_sum"]), balance=balance,
            ))
        return out

    def get_finance_overview(self) -> FinanceOverviewResponse:
        months = self.repo.finance_overview(12)
        return FinanceOverviewResponse(currency="USD",
            months=[MonthlyPoint(**m) for m in months])
```

## 5. Router (`app/routers/dashboard.py`)
```python
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_current_admin
from app.services.dashboard_service import DashboardService
from app.schemas.common import ResponseEnvelope, ok

router = APIRouter(dependencies=[Depends(get_current_admin)])

@router.get("/summary", response_model=ResponseEnvelope)
def summary(db: Session = Depends(get_db)):
    data = DashboardService(db).get_summary()
    return ok("dashboard.summary", data)

@router.get("/projects", response_model=ResponseEnvelope)
def projects(db: Session = Depends(get_db)):
    data = DashboardService(db).get_projects_overview()
    return ok("dashboard.projects", data)

@router.get("/finance", response_model=ResponseEnvelope)
def finance(db: Session = Depends(get_db)):
    data = DashboardService(db).get_finance_overview()
    return ok("dashboard.finance", data)
```

## 6. Aggregation SQL Snippets
```sql
-- Active / completed counts
SELECT status, COUNT(*) FROM projects
 WHERE status IN ('ACTIVE','COMPLETED') GROUP BY status;

-- Outstanding balance across all projects
SELECT (SELECT COALESCE(SUM(amount),0) FROM payments)
     - (SELECT COALESCE(SUM(amount),0) FROM expenses) AS outstanding;

-- Projects overview
SELECT p.id, p.name, c.name AS client_name, p.status, p.budget,
       COALESCE(SUM(pay.amount),0) AS payments_sum,
       COALESCE(SUM(exp.amount),0) AS expenses_sum
  FROM projects p
  JOIN clients c ON c.id = p.client_id
  LEFT JOIN payments pay ON pay.project_id = p.id
  LEFT JOIN expenses exp ON exp.project_id = p.id
 GROUP BY p.id, c.name
 ORDER BY p.name;
```

## 7. Conventions
- All money fields serialized as strings in JSON to preserve Decimal precision (Pydantic v2 `model_config = ConfigDict(json_encoders={Decimal: str})` or `str` field).
- No mutation functions in service/repository.
- UTC: rely on `paid_at`/`incurred_at` stored as UTC `TIMESTAMPTZ`.
- Round display values to 2 decimals in DTOs, never in storage.