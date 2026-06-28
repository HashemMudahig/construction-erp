"""Milestone model — project milestones."""
from datetime import date
from typing import Literal

from sqlalchemy import CheckConstraint, Date, ForeignKey, Index, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.mixins import TimestampMixin

MilestoneStatus = Literal["pending", "in_progress", "completed", "overdue"]


class Milestone(Base, TimestampMixin):
    __tablename__ = "milestones"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    project_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    due_date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="pending",
        server_default="pending",
    )

    __table_args__ = (
        CheckConstraint(
            "status IN ('pending','in_progress','completed','overdue')",
            name="chk_milestones_status",
        ),
        Index("idx_milestones_project_id", "project_id"),
        Index("idx_milestones_due_date", "due_date"),
    )