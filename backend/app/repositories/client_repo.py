"""Client repository — adds name search on top of CRUD."""
from typing import List, Optional

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.models.client import Client
from app.repositories.base import BaseRepository


class ClientRepository(BaseRepository[Client]):
    model = Client

    def __init__(self, db: Session) -> None:
        super().__init__(db)

    def list(
        self,
        search: Optional[str] = None,
        skip: int = 0,
        limit: int = 20,
    ) -> List[Client]:
        stmt = select(Client)
        if search:
            pattern = f"%{search}%"
            stmt = stmt.where(
                or_(
                    Client.name.ilike(pattern),
                    Client.email.ilike(pattern),
                    Client.phone.ilike(pattern),
                )
            )
        stmt = stmt.offset(skip).limit(min(limit, 100))
        return list(self.db.scalars(stmt).all())

    def count_projects(self, client_id: str) -> int:
        from sqlalchemy import func
        from app.models.project import Project
        return int(
            self.db.scalar(
                select(func.count())
                .select_from(Project)
                .where(Project.client_id == client_id)
            )
            or 0
        )