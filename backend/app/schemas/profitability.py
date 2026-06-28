"""Profitability response schema."""
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel


class ProjectProfitabilityResponse(BaseModel):
    project_id: UUID
    total_payments: Decimal
    total_expenses: Decimal
    balance: Decimal
    profit_margin: Decimal