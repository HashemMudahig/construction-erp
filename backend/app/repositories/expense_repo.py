"""Expense repository."""
from decimal import Decimal
from typing import List, Optional

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.expense import Expense
from app.repositories.base import BaseRepository


class ExpenseRepository(BaseRepository[Expense]):
    model = Expense

    def __init__(self, db: Session) -> None:
        super().__init__(db)

    def list(
        self,
        project_id: Optional[str] = None,
        category: Optional[str] = None,
        skip: int = 0,
        limit: int = 20,
    ) -> List[Expense]:
        stmt = select(Expense)
        if project_id:
            stmt = stmt.where(Expense.project_id == project_id)
        if category:
            stmt = stmt.where(Expense.category == category)
        stmt = stmt.order_by(Expense.expense_date.desc()).offset(skip).limit(min(limit, 100))
        return list(self.db.scalars(stmt).all())

    def sum_amount_by_project(self, project_id: str) -> Decimal:
        result = self.db.scalar(
            select(func.coalesce(func.sum(Expense.amount), 0))
            .where(Expense.project_id == project_id)
        )
        return Decimal(str(result or 0))