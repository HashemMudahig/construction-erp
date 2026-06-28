"""Thin HTTP routers. One module per entity."""
from app.routers.auth import router as auth_router
from app.routers.clients import router as clients_router
from app.routers.dashboard import router as dashboard_router
from app.routers.expenses import router as expenses_router
from app.routers.health import router as health_router
from app.routers.milestones import router as milestones_router
from app.routers.payments import router as payments_router
from app.routers.projects import router as projects_router

__all__ = [
    "auth_router", "clients_router", "dashboard_router", "expenses_router",
    "health_router", "milestones_router", "payments_router", "projects_router",
]