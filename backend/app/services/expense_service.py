"""Expense service — business rules for expense CRUD."""
from typing import List, Optional

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.models.expense import Expense
from app.repositories.expense_repo import ExpenseRepository
from app.repositories.project_repo import ProjectRepository


class ExpenseService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = ExpenseRepository(db)
        self.project_repo = ProjectRepository(db)

    def _validate_project(self, project_id: str) -> None:
        if self.project_repo.get(project_id) is None:
            raise AppException(
                code="PROJECT_NOT_FOUND",
                http_status=404,
                message="Project not found",
                field="project_id",
                detail=f"Project {project_id} not found",
            )

    def list(
        self,
        project_id: Optional[str],
        category: Optional[str],
        skip: int,
        limit: int,
    ) -> List[Expense]:
        return self.repo.list(project_id=project_id, category=category, skip=skip, limit=limit)

    def get(self, expense_id: str) -> Expense:
        e = self.repo.get(expense_id)
        if e is None:
            raise AppException(
                code="EXPENSE_NOT_FOUND",
                http_status=404,
                message="Expense not found",
                field="id",
                detail=f"No expense with id {expense_id}",
            )
        return e

    def create(self, data: dict) -> Expense:
        self._validate_project(data["project_id"])
        e = self.repo.create(data)
        self.db.commit()
        return e

    def update(self, expense_id: str, data: dict) -> Expense:
        e = self.get(expense_id)
        updated = self.repo.update(e, data)
        self.db.commit()
        return updated

    def delete(self, expense_id: str) -> None:
        e = self.get(expense_id)
        self.repo.delete(e)
        self.db.commit()