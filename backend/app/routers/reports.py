"""Reports router — read-only report endpoints."""
from datetime import date
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success
from app.core.security import require_user
from app.schemas.reports import (
    ExpenseAnalysisReport,
    FinancialSummaryReport,
    ProjectStatusReportItem,
)
from app.services.report_service import ReportService

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/project-status")
def project_status(
    project_id: Optional[UUID] = Query(default=None),
    status: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    data = ReportService(db).project_status_report(
        project_id=str(project_id) if project_id else None,
        status=status,
    )
    return success(
        data=[item.model_dump(mode="json") for item in data],
        message="Project status report generated",
    )


@router.get("/financial-summary")
def financial_summary(
    start_date: Optional[date] = Query(default=None),
    end_date: Optional[date] = Query(default=None),
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    data = ReportService(db).financial_summary_report(start_date=start_date, end_date=end_date)
    return success(
        data=FinancialSummaryReport(
            start_date=data.start_date,
            end_date=data.end_date,
            total_income=data.total_income,
            total_expenses=data.total_expenses,
            net=data.net,
            per_project=data.per_project,
        ).model_dump(mode="json"),
        message="Financial summary generated",
    )


@router.get("/expense-analysis")
def expense_analysis(
    start_date: Optional[date] = Query(default=None),
    end_date: Optional[date] = Query(default=None),
    project_id: Optional[UUID] = Query(default=None),
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    data = ReportService(db).expense_analysis_report(
        start_date=start_date,
        end_date=end_date,
        project_id=str(project_id) if project_id else None,
    )
    return success(
        data=ExpenseAnalysisReport(
            start_date=data.start_date,
            end_date=data.end_date,
            project_id=data.project_id,
            grand_total=data.grand_total,
            by_category=data.by_category,
            by_project=data.by_project,
        ).model_dump(mode="json"),
        message="Expense analysis generated",
    )