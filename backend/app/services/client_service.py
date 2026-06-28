"""Client service — business rules for client CRUD."""
from typing import List, Optional

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.models.client import Client
from app.repositories.client_repo import ClientRepository


class ClientService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = ClientRepository(db)

    def list(self, search: Optional[str], skip: int, limit: int) -> List[Client]:
        return self.repo.list(search=search, skip=skip, limit=limit)

    def get(self, client_id: str) -> Client:
        client = self.repo.get(client_id)
        if client is None:
            raise AppException(
                code="CLIENT_NOT_FOUND",
                http_status=404,
                message="Client not found",
                field="id",
                detail=f"No client with id {client_id}",
            )
        return client

    def create(self, data: dict) -> Client:
        client = self.repo.create(data)
        self.db.commit()
        return client

    def update(self, client_id: str, data: dict) -> Client:
        client = self.get(client_id)
        updated = self.repo.update(client, data)
        self.db.commit()
        return updated

    def delete(self, client_id: str) -> None:
        client = self.get(client_id)
        project_count = self.repo.count_projects(client_id)
        if project_count > 0:
            raise AppException(
                code="CLIENT_HAS_PROJECTS",
                http_status=409,
                message="Client has linked projects",
                field="id",
                detail=f"{project_count} projects attached",
            )
        self.repo.delete(client)
        self.db.commit()