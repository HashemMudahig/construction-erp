"""Milestone request/response schemas (Pydantic v2)."""
from datetime import date, datetime
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

MilestoneStatusLiteral = Literal["pending", "in_progress", "completed", "overdue"]


class MilestoneCreate(BaseModel):
    project_id: UUID
    title: str = Field(min_length=1, max_length=255)
    description: Optional[str] = None
    due_date: date
    status: MilestoneStatusLiteral = "pending"


class MilestoneUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=255)
    description: Optional[str] = None
    due_date: Optional[date] = None
    status: Optional[MilestoneStatusLiteral] = None


class MilestoneRead(BaseModel):
    id: UUID
    project_id: UUID
    title: str
    description: Optional[str]
    due_date: date
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)