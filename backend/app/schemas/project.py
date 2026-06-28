"""Project request/response schemas (Pydantic v2)."""
from datetime import date, datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

ProjectStatusLiteral = Literal["planning", "active", "completed", "on_hold", "cancelled"]


class ProjectBase(BaseModel):
    client_id: UUID
    name: str = Field(min_length=1, max_length=200)
    description: Optional[str] = None
    budget: Decimal = Field(ge=0, max_digits=14, decimal_places=2)
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    status: ProjectStatusLiteral = "planning"


class ProjectCreate(ProjectBase):
    pass


class ProjectUpdate(BaseModel):
    client_id: Optional[UUID] = None
    name: Optional[str] = Field(default=None, min_length=1, max_length=200)
    description: Optional[str] = None
    budget: Optional[Decimal] = Field(
        default=None, ge=0, max_digits=14, decimal_places=2
    )
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    status: Optional[ProjectStatusLiteral] = None


class ProjectRead(ProjectBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)