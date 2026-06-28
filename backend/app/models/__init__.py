"""ORM models. One module per entity.

Importing this package registers all tables on the shared `Base.metadata`.
"""
from app.core.database import Base
from app.models.client import Client
from app.models.expense import Expense, EXPENSE_CATEGORIES
from app.models.milestone import Milestone
from app.models.mixins import TimestampMixin, UpdatedAtMixin
from app.models.payment import Payment
from app.models.project import Project
from app.models.user import User

__all__ = [
    "Base", "Client", "Expense", "EXPENSE_CATEGORIES", "Milestone",
    "Payment", "Project", "TimestampMixin", "UpdatedAtMixin", "User",
]