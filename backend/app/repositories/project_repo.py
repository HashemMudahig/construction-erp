"""Project repository — filters by client_id and status."""
from typing import List, Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.project import Project
from app.repositories.base import BaseRepository


class ProjectRepository(BaseRepository[Project]):
    model = Project

    def __init__(self, db: Session) -> None:
        super().__init__(db)

    def list(
        self,
        client_id: Optional[str] = None,
        status: Optional[str] = None,
        skip: int = 0,
        limit: int = 20,
    ) -> List[Project]:
        stmt = select(Project)
        if client_id:
            stmt = stmt.where(Project.client_id == client_id)
        if status:
            stmt = stmt.where(Project.status == status)
        stmt = stmt.offset(skip).limit(min(limit, 100))
        return list(self.db.scalars(stmt).all())