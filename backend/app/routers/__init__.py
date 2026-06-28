"""Thin HTTP routers. One module per entity."""
from app.routers.auth import router as auth_router
from app.routers.clients import router as clients_router
from app.routers.health import router as health_router
from app.routers.projects import router as projects_router

__all__ = ["auth_router", "clients_router", "health_router", "projects_router"]