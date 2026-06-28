"""SQLAlchemy data access repositories. One module per entity."""
from app.repositories.base import BaseRepository
from app.repositories.client_repo import ClientRepository
from app.repositories.expense_repo import ExpenseRepository
from app.repositories.milestone_repo import MilestoneRepository
from app.repositories.payment_repo import PaymentRepository
from app.repositories.project_repo import ProjectRepository

__all__ = [
    "BaseRepository", "ClientRepository", "ExpenseRepository",
    "MilestoneRepository", "PaymentRepository", "ProjectRepository",
]