"""Project model — construction work packages assigned to a client."""
from datetime import date
from decimal import Decimal
from typing import Literal

from sqlalchemy import CheckConstraint, Date, ForeignKey, Index, Numeric, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.mixins import TimestampMixin

ProjectStatus = Literal["planning", "active", "completed", "on_hold", "cancelled"]

PROJECT_STATUSES = ("planning", "active", "completed", "on_hold", "cancelled")


class Project(Base, TimestampMixin):
    __tablename__ = "projects"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    client_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("clients.id", ondelete="RESTRICT"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    budget: Mapped[Decimal] = mapped_column(
        Numeric(14, 2),
        nullable=False,
    )
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="planning",
        server_default="planning",
    )

    __table_args__ = (
        CheckConstraint("budget >= 0", name="chk_projects_budget_nonnegative"),
        CheckConstraint(
            "end_date IS NULL OR start_date IS NULL OR end_date >= start_date",
            name="chk_projects_dates",
        ),
        Index("idx_projects_client_id", "client_id"),
        Index("idx_projects_status", "status"),
    )