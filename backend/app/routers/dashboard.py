"""Dashboard router — read-only aggregation endpoints."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success
from app.core.security import require_user
from app.schemas.dashboard import (
    DashboardSummaryResponse,
    FinanceOverviewResponse,
    ProjectOverviewItem,
)
from app.services.dashboard_service import DashboardService

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/summary")
def summary(db: Session = Depends(get_db), _: str = Depends(require_user)) -> dict:
    data = DashboardService(db).get_summary()
    return success(
        data=DashboardSummaryResponse(
            active_projects=data.active_projects,
            completed_projects=data.completed_projects,
            total_clients=data.total_clients,
            outstanding_balances=data.outstanding_balances,
            total_payments=data.total_payments,
            total_expenses=data.total_expenses,
        ).model_dump(mode="json"),
        message="Dashboard summary retrieved",
    )


@router.get("/projects")
def projects(db: Session = Depends(get_db), _: str = Depends(require_user)) -> dict:
    data = DashboardService(db).get_projects_overview()
    return success(
        data=[item.model_dump(mode="json") for item in data],
        message="Projects overview retrieved",
    )


@router.get("/finance")
def finance(db: Session = Depends(get_db), _: str = Depends(require_user)) -> dict:
    data = DashboardService(db).get_finance_overview()
    return success(
        data=FinanceOverviewResponse(months=data.months).model_dump(mode="json"),
        message="Finance overview retrieved",
    )