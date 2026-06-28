"""Payment service — business rules for payment CRUD."""
from typing import List, Optional

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.models.payment import Payment
from app.repositories.payment_repo import PaymentRepository
from app.repositories.project_repo import ProjectRepository


class PaymentService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = PaymentRepository(db)
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
        skip: int,
        limit: int,
    ) -> List[Payment]:
        return self.repo.list(project_id=project_id, skip=skip, limit=limit)

    def get(self, payment_id: str) -> Payment:
        p = self.repo.get(payment_id)
        if p is None:
            raise AppException(
                code="PAYMENT_NOT_FOUND",
                http_status=404,
                message="Payment not found",
                field="id",
                detail=f"No payment with id {payment_id}",
            )
        return p

    def create(self, data: dict) -> Payment:
        self._validate_project(data["project_id"])
        p = self.repo.create(data)
        self.db.commit()
        return p

    def update(self, payment_id: str, data: dict) -> Payment:
        p = self.get(payment_id)
        updated = self.repo.update(p, data)
        self.db.commit()
        return updated

    def delete(self, payment_id: str) -> None:
        p = self.get(payment_id)
        self.repo.delete(p)
        self.db.commit()