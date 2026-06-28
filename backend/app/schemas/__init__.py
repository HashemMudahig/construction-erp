"""Pydantic request/response schemas. One module per entity."""
from app.schemas.auth import LoginRequest, TokenResponse
from app.schemas.client import ClientCreate, ClientRead, ClientUpdate
from app.schemas.expense import ExpenseCreate, ExpenseRead, ExpenseUpdate
from app.schemas.milestone import MilestoneCreate, MilestoneRead, MilestoneUpdate
from app.schemas.payment import PaymentCreate, PaymentRead, PaymentUpdate
from app.schemas.profitability import ProjectProfitabilityResponse
from app.schemas.project import ProjectCreate, ProjectRead, ProjectUpdate

__all__ = [
    "ClientCreate", "ClientRead", "ClientUpdate",
    "ExpenseCreate", "ExpenseRead", "ExpenseUpdate",
    "LoginRequest", "TokenResponse",
    "MilestoneCreate", "MilestoneRead", "MilestoneUpdate",
    "PaymentCreate", "PaymentRead", "PaymentUpdate",
    "ProjectCreate", "ProjectRead", "ProjectProfitabilityResponse", "ProjectUpdate",
]