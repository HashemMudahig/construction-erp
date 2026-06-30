"""Report response schemas (Pydantic v2)."""
from datetime import date
from decimal import Decimal
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel


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
    progress_pct: Decimal


class ProjectFinancial(BaseModel):
    project_id: UUID
    name: str
    income: Decimal
    expenses: Decimal
    net: Decimal


class FinancialSummaryReport(BaseModel):
    start_date: Optional[date]
    end_date: Optional[date]
    total_income: Decimal
    total_expenses: Decimal
    net: Decimal
    per_project: List[ProjectFinancial]


class ExpenseCategoryBreakdown(BaseModel):
    category: str
    total: Decimal
    percentage: Decimal


class ProjectExpense(BaseModel):
    project_id: UUID
    name: str
    total: Decimal
    by_category: List[ExpenseCategoryBreakdown]


class ExpenseAnalysisReport(BaseModel):
    start_date: Optional[date]
    end_date: Optional[date]
    project_id: Optional[UUID]
    grand_total: Decimal
    by_category: List[ExpenseCategoryBreakdown]
    by_project: List[ProjectExpense]