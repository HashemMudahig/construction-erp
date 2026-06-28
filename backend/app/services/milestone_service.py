"""Milestone service — business rules for milestone CRUD."""
from typing import List, Optional

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.models.milestone import Milestone
from app.repositories.milestone_repo import MilestoneRepository
from app.repositories.project_repo import ProjectRepository


class MilestoneService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = MilestoneRepository(db)
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
        status: Optional[str],
        skip: int,
        limit: int,
    ) -> List[Milestone]:
        return self.repo.list(project_id=project_id, status=status, skip=skip, limit=limit)

    def get(self, milestone_id: str) -> Milestone:
        m = self.repo.get(milestone_id)
        if m is None:
            raise AppException(
                code="MILESTONE_NOT_FOUND",
                http_status=404,
                message="Milestone not found",
                field="id",
                detail=f"No milestone with id {milestone_id}",
            )
        return m

    def create(self, data: dict) -> Milestone:
        self._validate_project(data["project_id"])
        m = self.repo.create(data)
        self.db.commit()
        return m

    def update(self, milestone_id: str, data: dict) -> Milestone:
        m = self.get(milestone_id)
        updated = self.repo.update(m, data)
        self.db.commit()
        return updated

    def complete(self, milestone_id: str) -> Milestone:
        m = self.get(milestone_id)
        if m.status not in ("pending", "in_progress"):
            raise AppException(
                code="MILESTONE_INVALID_TRANSITION",
                http_status=400,
                message="Cannot complete milestone from current status",
                field="status",
                detail=f"Current status '{m.status}' cannot transition to 'completed'",
            )
        m.status = "completed"
        self.db.flush()
        self.db.commit()
        return m

    def delete(self, milestone_id: str) -> None:
        m = self.get(milestone_id)
        self.repo.delete(m)
        self.db.commit()