"""Model registry module.

Re-exports `Base` and all entity models so Alembic and the app can import a
single package and register every table on the shared metadata.
"""
from app.core.database import Base  # noqa: F401
from app.models.client import Client  # noqa: F401
from app.models.project import Project  # noqa: F401
from app.models.user import User  # noqa: F401