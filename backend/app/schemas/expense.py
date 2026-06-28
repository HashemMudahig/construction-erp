"""Expense request/response schemas (Pydantic v2)."""
from datetime import date, datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

ExpenseCategoryLiteral = Literal["materials", "labor", "equipment", "permits", "other"]


class ExpenseCreate(BaseModel):
    project_id: UUID
    category: ExpenseCategoryLiteral
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    expense_date: date
    notes: Optional[str] = None


class ExpenseUpdate(BaseModel):
    category: Optional[ExpenseCategoryLiteral] = None
    amount: Optional[Decimal] = Field(default=None, gt=0, max_digits=14, decimal_places=2)
    expense_date: Optional[date] = None
    notes: Optional[str] = None


class ExpenseRead(BaseModel):
    id: UUID
    project_id: UUID
    category: str
    amount: Decimal
    expense_date: date
    notes: Optional[str]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)