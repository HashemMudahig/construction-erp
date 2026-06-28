"""Dashboard service — orchestrates repository calls into response DTOs."""
from typing import List

from sqlalchemy.orm import Session

from app.repositories.dashboard_repository import DashboardRepository
from app.schemas.dashboard import (
    DashboardSummaryResponse,
    FinanceOverviewResponse,
    MonthlyPoint,
    ProjectOverviewItem,
)
from decimal import Decimal
from uuid import UUID


class DashboardService:
    def __init__(self, db: Session) -> None:
        self.repo = DashboardRepository(db)

    def get_summary(self) -> DashboardSummaryResponse:
        c = self.repo.counts()
        t = self.repo.totals()
        outstanding = t["payments"] - t["expenses"]
        return DashboardSummaryResponse(
            active_projects=c["active"],
            completed_projects=c["completed"],
            total_clients=c["clients"],
            outstanding_balances=outstanding,
            total_payments=t["payments"],
            total_expenses=t["expenses"],
        )

    def get_projects_overview(self) -> List[ProjectOverviewItem]:
        rows = self.repo.projects_overview()
        out = []
        for r in rows:
            balance = r["payments_sum"] - r["expenses_sum"]
            out.append(ProjectOverviewItem(
                project_id=UUID(r["id"]),
                name=r["name"],
                client_name=r["client_name"],
                status=r["status"],
                budget=r["budget"],
                payments_sum=r["payments_sum"],
                expenses_sum=r["expenses_sum"],
                balance=balance,
            ))
        return out

    def get_finance_overview(self) -> FinanceOverviewResponse:
        months = self.repo.finance_overview(12)
        return FinanceOverviewResponse(
            months=[MonthlyPoint(**m) for m in months],
        )