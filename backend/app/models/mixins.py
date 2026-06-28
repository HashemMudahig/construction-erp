"""Shared ORM mixins used across entity models.

`Base` (the declarative base) lives in `app.core.database` so Alembic and the
app share a single metadata. Mixins live here to avoid circular imports between
entity models and a shared `base.py`.
"""
from datetime import datetime
from sqlalchemy import DateTime, func
from sqlalchemy.orm import Mapped, mapped_column


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class UpdatedAtMixin:
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )