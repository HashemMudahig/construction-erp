"""Project service — business rules for project CRUD."""
from typing import List, Optional

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.models.project import Project
from app.repositories.client_repo import ClientRepository
from app.repositories.project_repo import ProjectRepository


class ProjectService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = ProjectRepository(db)
        self.client_repo = ClientRepository(db)

    def list(
        self,
        client_id: Optional[str],
        status: Optional[str],
        skip: int,
        limit: int,
    ) -> List[Project]:
        return self.repo.list(client_id=client_id, status=status, skip=skip, limit=limit)

    def get(self, project_id: str) -> Project:
        project = self.repo.get(project_id)
        if project is None:
            raise AppException(
                code="PROJECT_NOT_FOUND",
                http_status=404,
                message="Project not found",
                field="id",
                detail=f"No project with id {project_id}",
            )
        return project

    def _validate_client(self, client_id: str) -> None:
        if self.client_repo.get(client_id) is None:
            raise AppException(
                code="PROJECT_CLIENT_INVALID",
                http_status=400,
                message="Referenced client does not exist",
                field="client_id",
                detail=f"Client {client_id} not found",
            )

    def _validate_dates(self, data: dict) -> None:
        start = data.get("start_date")
        end = data.get("end_date")
        if start and end and end < start:
            raise AppException(
                code="PROJECT_DATE_INVALID",
                http_status=400,
                message="end_date is before start_date",
                field="end_date",
                detail="end_date must be >= start_date",
            )

    def create(self, data: dict) -> Project:
        self._validate_client(data["client_id"])
        self._validate_dates(data)
        project = self.repo.create(data)
        self.db.commit()
        return project

    def update(self, project_id: str, data: dict) -> Project:
        project = self.get(project_id)
        if data.get("client_id") is not None:
            self._validate_client(data["client_id"])
        merged = {**project.__dict__, **{k: v for k, v in data.items() if v is not None}}
        self._validate_dates(merged)
        updated = self.repo.update(project, data)
        self.db.commit()
        return updated

    def delete(self, project_id: str) -> None:
        project = self.get(project_id)
        self.repo.delete(project)
        self.db.commit()