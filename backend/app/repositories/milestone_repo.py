"""Milestone repository."""
from typing import List, Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.milestone import Milestone
from app.repositories.base import BaseRepository


class MilestoneRepository(BaseRepository[Milestone]):
    model = Milestone

    def __init__(self, db: Session) -> None:
        super().__init__(db)

    def list(
        self,
        project_id: Optional[str] = None,
        status: Optional[str] = None,
        skip: int = 0,
        limit: int = 20,
    ) -> List[Milestone]:
        stmt = select(Milestone)
        if project_id:
            stmt = stmt.where(Milestone.project_id == project_id)
        if status:
            stmt = stmt.where(Milestone.status == status)
        stmt = stmt.order_by(Milestone.due_date).offset(skip).limit(min(limit, 100))
        return list(self.db.scalars(stmt).all())