"""Report service — orchestrates repository calls into response DTOs."""
from datetime import date
from decimal import Decimal
from typing import List, Optional
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.repositories.report_repository import ReportRepository
from app.schemas.reports import (
    ExpenseAnalysisReport,
    ExpenseCategoryBreakdown,
    FinancialSummaryReport,
    ProjectExpense,
    ProjectFinancial,
    ProjectStatusReportItem,
)


class ReportService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = ReportRepository(db)

    def _validate_dates(self, start_date: Optional[date], end_date: Optional[date]) -> None:
        if start_date and end_date and start_date > end_date:
            raise AppException(
                code="INVALID_DATE_RANGE",
                http_status=422,
                message="start_date cannot be after end_date",
                field="end_date",
                detail="start_date must be <= end_date",
            )

    def _validate_project(self, project_id: Optional[str]) -> None:
        if project_id and self.db.get(__import__("app.models.project", fromlist=["Project"]).Project, project_id) is None:
            raise AppException(
                code="PROJECT_NOT_FOUND",
                http_status=404,
                message="Project not found",
                field="project_id",
                detail=f"Project {project_id} not found",
            )

    def project_status_report(
        self,
        project_id: Optional[str] = None,
        status: Optional[str] = None,
    ) -> List[ProjectStatusReportItem]:
        self._validate_project(project_id)
        rows = self.repo.project_status(project_id=project_id, status=status)
        out = []
        for r in rows:
            balance = r["total_payments"] - r["total_expenses"]
            progress = (
                (Decimal(r["completed_milestones"]) / Decimal(r["milestone_count"]) * 100).quantize(Decimal("0.01"))
                if r["milestone_count"] > 0
                else Decimal("0.00")
            )
            out.append(ProjectStatusReportItem(
                project_id=UUID(r["project_id"]),
                name=r["name"],
                status=r["status"],
                budget=r["budget"],
                total_payments=r["total_payments"],
                total_expenses=r["total_expenses"],
                balance=balance,
                milestone_count=r["milestone_count"],
                completed_milestones=r["completed_milestones"],
                progress_pct=progress,
            ))
        return out

    def financial_summary_report(
        self,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> FinancialSummaryReport:
        self._validate_dates(start_date, end_date)
        data = self.repo.financial_summary(start_date=start_date, end_date=end_date)
        per_project = [
            ProjectFinancial(
                project_id=UUID(p["project_id"]),
                name=p["name"],
                income=p["income"],
                expenses=p["expenses"],
                net=p["net"],
            )
            for p in data["per_project"]
        ]
        return FinancialSummaryReport(
            start_date=start_date,
            end_date=end_date,
            total_income=data["total_income"],
            total_expenses=data["total_expenses"],
            net=data["net"],
            per_project=per_project,
        )

    def expense_analysis_report(
        self,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        project_id: Optional[str] = None,
    ) -> ExpenseAnalysisReport:
        self._validate_dates(start_date, end_date)
        self._validate_project(project_id)
        data = self.repo.expense_analysis(
            start_date=start_date, end_date=end_date, project_id=project_id
        )
        by_category = [
            ExpenseCategoryBreakdown(category=c["category"], total=c["total"], percentage=c["percentage"])
            for c in data["by_category"]
        ]
        by_project = [
            ProjectExpense(
                project_id=UUID(p["project_id"]),
                name=p["name"],
                total=p["total"],
                by_category=[
                    ExpenseCategoryBreakdown(category=c["category"], total=c["total"], percentage=c["percentage"])
                    for c in p["by_category"]
                ],
            )
            for p in data["by_project"]
        ]
        return ExpenseAnalysisReport(
            start_date=start_date,
            end_date=end_date,
            project_id=UUID(project_id) if project_id else None,
            grand_total=data["grand_total"],
            by_category=by_category,
            by_project=by_project,
        )