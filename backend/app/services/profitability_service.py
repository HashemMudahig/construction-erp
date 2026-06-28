"""Project profitability service — computes payments, expenses, balance, margin."""
from decimal import Decimal
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.models.project import Project
from app.repositories.expense_repo import ExpenseRepository
from app.repositories.payment_repo import PaymentRepository
from app.schemas.profitability import ProjectProfitabilityResponse


class ProjectProfitabilityService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.payment_repo = PaymentRepository(db)
        self.expense_repo = ExpenseRepository(db)

    def calculate_profit(self, project_id: str) -> ProjectProfitabilityResponse:
        project = self.db.get(Project, project_id)
        if project is None:
            raise AppException(
                code="PROJECT_NOT_FOUND",
                http_status=404,
                message="Project not found",
                field="id",
                detail=f"Project {project_id} not found",
            )

        total_payments = self.payment_repo.sum_amount_by_project(project_id)
        total_expenses = self.expense_repo.sum_amount_by_project(project_id)
        balance = total_payments - total_expenses
        profit_margin = (
            (balance / total_payments).quantize(Decimal("0.01"))
            if total_payments > 0
            else Decimal("0.00")
        )
        return ProjectProfitabilityResponse(
            project_id=UUID(project_id),
            total_payments=total_payments,
            total_expenses=total_expenses,
            balance=balance,
            profit_margin=profit_margin,
        )