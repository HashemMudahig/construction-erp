"""Payment repository."""
from decimal import Decimal
from typing import List, Optional

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.payment import Payment
from app.repositories.base import BaseRepository


class PaymentRepository(BaseRepository[Payment]):
    model = Payment

    def __init__(self, db: Session) -> None:
        super().__init__(db)

    def list(
        self,
        project_id: Optional[str] = None,
        skip: int = 0,
        limit: int = 20,
    ) -> List[Payment]:
        stmt = select(Payment)
        if project_id:
            stmt = stmt.where(Payment.project_id == project_id)
        stmt = stmt.order_by(Payment.payment_date.desc()).offset(skip).limit(min(limit, 100))
        return list(self.db.scalars(stmt).all())

    def sum_amount_by_project(self, project_id: str) -> Decimal:
        result = self.db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0))
            .where(Payment.project_id == project_id)
        )
        return Decimal(str(result or 0))