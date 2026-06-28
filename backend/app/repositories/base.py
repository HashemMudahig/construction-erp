"""Generic SQLAlchemy repository with common CRUD operations."""
from typing import Any, Generic, List, Optional, Type, TypeVar

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import Base

ModelT = TypeVar("ModelT", bound=Base)


class BaseRepository(Generic[ModelT]):
    model: Type[ModelT]

    def __init__(self, db: Session) -> None:
        self.db = db

    def get(self, id: str) -> Optional[ModelT]:
        return self.db.get(self.model, id)

    def list(self, skip: int = 0, limit: int = 20) -> List[ModelT]:
        stmt = select(self.model).offset(skip).limit(min(limit, 100))
        return list(self.db.scalars(stmt).all())

    def create(self, data: dict) -> ModelT:
        obj = self.model(**data)
        self.db.add(obj)
        self.db.flush()
        self.db.refresh(obj)
        return obj

    def update(self, obj: ModelT, data: dict) -> ModelT:
        for key, value in data.items():
            if value is not None:
                setattr(obj, key, value)
        self.db.flush()
        self.db.refresh(obj)
        return obj

    def delete(self, obj: ModelT) -> None:
        self.db.delete(obj)
        self.db.flush()

    def count(self) -> int:
        from sqlalchemy import func
        return int(self.db.scalar(select(func.count()).select_from(self.model)) or 0)