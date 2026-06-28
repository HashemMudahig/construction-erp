"""Pydantic request/response schemas. One module per entity."""
from app.schemas.auth import LoginRequest, TokenResponse
from app.schemas.client import ClientCreate, ClientRead, ClientUpdate
from app.schemas.project import ProjectCreate, ProjectRead, ProjectUpdate

__all__ = [
    "ClientCreate", "ClientRead", "ClientUpdate",
    "LoginRequest", "TokenResponse",
    "ProjectCreate", "ProjectRead", "ProjectUpdate",
]