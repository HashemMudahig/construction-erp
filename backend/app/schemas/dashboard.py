"""Dashboard response schemas."""
from decimal import Decimal
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


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
    months: List[MonthlyPoint]