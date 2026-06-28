"""Dashboard repository — aggregation queries (read-only, no mutations)."""
from datetime import date
from decimal import Decimal
from typing import List

from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from app.models.client import Client
from app.models.expense import Expense
from app.models.payment import Payment
from app.models.project import Project


class DashboardRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def counts(self) -> dict:
        active = self.db.scalar(
            select(func.count()).select_from(Project).where(Project.status == "active")
        ) or 0
        completed = self.db.scalar(
            select(func.count()).select_from(Project).where(Project.status == "completed")
        ) or 0
        clients = self.db.scalar(select(func.count()).select_from(Client)) or 0
        return {"active": int(active), "completed": int(completed), "clients": int(clients)}

    def totals(self) -> dict:
        pay = self.db.scalar(select(func.coalesce(func.sum(Payment.amount), 0))) or 0
        exp = self.db.scalar(select(func.coalesce(func.sum(Expense.amount), 0))) or 0
        return {"payments": Decimal(str(pay)), "expenses": Decimal(str(exp))}

    def projects_overview(self) -> List[dict]:
        q = (
            select(
                Project.id,
                Project.name,
                Client.name.label("client_name"),
                Project.status,
                Project.budget,
                func.coalesce(func.sum(Payment.amount), 0).label("payments_sum"),
                func.coalesce(func.sum(Expense.amount), 0).label("expenses_sum"),
            )
            .join(Client, Client.id == Project.client_id)
            .outerjoin(Payment, Payment.project_id == Project.id)
            .outerjoin(Expense, Expense.project_id == Project.id)
            .group_by(Project.id, Client.name)
            .order_by(Project.name)
        )
        rows = self.db.execute(q).all()
        results = []
        for r in rows:
            results.append({
                "id": str(r.id),
                "name": r.name,
                "client_name": r.client_name,
                "status": r.status,
                "budget": Decimal(str(r.budget)),
                "payments_sum": Decimal(str(r.payments_sum)),
                "expenses_sum": Decimal(str(r.expenses_sum)),
            })
        return results

    def finance_overview(self, months: int = 12) -> List[dict]:
        """Monthly cash flow for the last N months.

        Uses payment_date / expense_date (DATE columns) truncated to month.
        Pads missing months with zeros.
        """
        # Income by month
        income_q = (
            select(
                func.to_char(
                    func.date_trunc("month", Payment.payment_date), "YYYY-MM"
                ).label("month"),
                func.coalesce(func.sum(Payment.amount), 0).label("income"),
            )
            .where(
                Payment.payment_date >= text(f"date_trunc('month', NOW()) - INTERVAL '{months - 1} months'")
            )
            .group_by("month")
            .order_by("month")
        )
        income_rows = self.db.execute(income_q).all()
        income_map = {r.month: Decimal(str(r.income)) for r in income_rows}

        # Expense by month
        expense_q = (
            select(
                func.to_char(
                    func.date_trunc("month", Expense.expense_date), "YYYY-MM"
                ).label("month"),
                func.coalesce(func.sum(Expense.amount), 0).label("expense"),
            )
            .where(
                Expense.expense_date >= text(f"date_trunc('month', NOW()) - INTERVAL '{months - 1} months'")
            )
            .group_by("month")
            .order_by("month")
        )
        expense_rows = self.db.execute(expense_q).all()
        expense_map = {r.month: Decimal(str(r.expense)) for r in expense_rows}

        # Build full month range padded with zeros
        all_months = sorted(set(income_map.keys()) | set(expense_map.keys()))
        results = []
        for m in all_months:
            results.append({
                "month": m,
                "income": income_map.get(m, Decimal("0.00")),
                "expense": expense_map.get(m, Decimal("0.00")),
            })
        return results