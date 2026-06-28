"""Payment request/response schemas (Pydantic v2)."""
from datetime import date, datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

PaymentMethodLiteral = Literal["cash", "bank_transfer", "cheque", "other"]


class PaymentCreate(BaseModel):
    project_id: UUID
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    payment_date: date
    method: PaymentMethodLiteral
    notes: Optional[str] = None


class PaymentUpdate(BaseModel):
    amount: Optional[Decimal] = Field(default=None, gt=0, max_digits=14, decimal_places=2)
    payment_date: Optional[date] = None
    method: Optional[PaymentMethodLiteral] = None
    notes: Optional[str] = None


class PaymentRead(BaseModel):
    id: UUID
    project_id: UUID
    amount: Decimal
    payment_date: date
    method: str
    notes: Optional[str]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)