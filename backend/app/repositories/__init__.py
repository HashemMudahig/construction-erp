"""SQLAlchemy data access repositories. One module per entity."""
from app.repositories.base import BaseRepository
from app.repositories.client_repo import ClientRepository
from app.repositories.project_repo import ProjectRepository

__all__ = ["BaseRepository", "ClientRepository", "ProjectRepository"]