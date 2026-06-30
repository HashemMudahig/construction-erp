"""Report repository — read-only aggregation queries for reports."""
from datetime import date
from decimal import Decimal
from typing import List, Optional

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.expense import Expense
from app.models.milestone import Milestone
from app.models.payment import Payment
from app.models.project import Project


class ReportRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def project_status(
        self,
        project_id: Optional[str] = None,
        status: Optional[str] = None,
    ) -> List[dict]:
        """Join projects + sums of payments/expenses + milestone counts.

        Uses subqueries to avoid the N-join cartesian product problem:
        joining payments + expenses + milestones directly multiplies rows.
        """
        # Subquery: total payments per project
        pay_sub = (
            select(Payment.project_id.label("pid"),
                   func.coalesce(func.sum(Payment.amount), 0).label("total_payments"))
            .group_by(Payment.project_id)
            .subquery()
        )
        # Subquery: total expenses per project
        exp_sub = (
            select(Expense.project_id.label("eid"),
                   func.coalesce(func.sum(Expense.amount), 0).label("total_expenses"))
            .group_by(Expense.project_id)
            .subquery()
        )
        # Subquery: milestone counts per project
        milestone_sub = (
            select(
                Milestone.project_id.label("mid"),
                func.count(Milestone.id).label("milestone_count"),
                func.count(Milestone.id).filter(Milestone.status == "completed").label("completed_milestones"),
            )
            .group_by(Milestone.project_id)
            .subquery()
        )

        q = (
            select(
                Project.id,
                Project.name,
                Project.status,
                Project.budget,
                func.coalesce(pay_sub.c.total_payments, 0).label("total_payments"),
                func.coalesce(exp_sub.c.total_expenses, 0).label("total_expenses"),
                func.coalesce(milestone_sub.c.milestone_count, 0).label("milestone_count"),
                func.coalesce(milestone_sub.c.completed_milestones, 0).label("completed_milestones"),
            )
            .outerjoin(pay_sub, pay_sub.c.pid == Project.id)
            .outerjoin(exp_sub, exp_sub.c.eid == Project.id)
            .outerjoin(milestone_sub, milestone_sub.c.mid == Project.id)
            .order_by(Project.name)
        )
        if project_id:
            q = q.where(Project.id == project_id)
        if status:
            q = q.where(Project.status == status)

        rows = self.db.execute(q).all()
        results = []
        for r in rows:
            results.append({
                "project_id": str(r.id),
                "name": r.name,
                "status": r.status,
                "budget": Decimal(str(r.budget)),
                "total_payments": Decimal(str(r.total_payments)),
                "total_expenses": Decimal(str(r.total_expenses)),
                "milestone_count": int(r.milestone_count or 0),
                "completed_milestones": int(r.completed_milestones or 0),
            })
        return results

    def financial_summary(
        self,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> dict:
        """Sum payments and expenses by date range, plus per-project breakdown."""
        # Total income
        pay_q = select(func.coalesce(func.sum(Payment.amount), 0))
        exp_q = select(func.coalesce(func.sum(Expense.amount), 0))
        if start_date:
            pay_q = pay_q.where(Payment.payment_date >= start_date)
            exp_q = exp_q.where(Expense.expense_date >= start_date)
        if end_date:
            pay_q = pay_q.where(Payment.payment_date <= end_date)
            exp_q = exp_q.where(Expense.expense_date <= end_date)

        total_income = Decimal(str(self.db.scalar(pay_q) or 0))
        total_expenses = Decimal(str(self.db.scalar(exp_q) or 0))

        # Per-project breakdown
        per_pay_q = (
            select(Payment.project_id, func.coalesce(func.sum(Payment.amount), 0).label("income"))
            .group_by(Payment.project_id)
        )
        per_exp_q = (
            select(Expense.project_id, func.coalesce(func.sum(Expense.amount), 0).label("expenses"))
            .group_by(Expense.project_id)
        )
        if start_date:
            per_pay_q = per_pay_q.where(Payment.payment_date >= start_date)
            per_exp_q = per_exp_q.where(Expense.expense_date >= start_date)
        if end_date:
            per_pay_q = per_pay_q.where(Payment.payment_date <= end_date)
            per_exp_q = per_exp_q.where(Expense.expense_date <= end_date)

        income_map = {str(r.project_id): Decimal(str(r.income)) for r in self.db.execute(per_pay_q).all()}
        expense_map = {str(r.project_id): Decimal(str(r.expenses)) for r in self.db.execute(per_exp_q).all()}

        all_pids = set(income_map.keys()) | set(expense_map.keys())
        per_project = []
        for pid in all_pids:
            inc = income_map.get(pid, Decimal("0"))
            exp = expense_map.get(pid, Decimal("0"))
            # Get project name
            proj = self.db.get(Project, pid)
            name = proj.name if proj else "Unknown"
            per_project.append({
                "project_id": pid,
                "name": name,
                "income": inc,
                "expenses": exp,
                "net": inc - exp,
            })
        per_project.sort(key=lambda x: x["name"])

        return {
            "total_income": total_income,
            "total_expenses": total_expenses,
            "net": total_income - total_expenses,
            "per_project": per_project,
        }

    def expense_analysis(
        self,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        project_id: Optional[str] = None,
    ) -> dict:
        """Group expenses by category and by project."""
        q = (
            select(
                Expense.category,
                Expense.project_id,
                Project.name.label("project_name"),
                func.coalesce(func.sum(Expense.amount), 0).label("total"),
            )
            .join(Project, Project.id == Expense.project_id)
            .group_by(Expense.category, Expense.project_id, Project.name)
            .order_by(Expense.category)
        )
        if start_date:
            q = q.where(Expense.expense_date >= start_date)
        if end_date:
            q = q.where(Expense.expense_date <= end_date)
        if project_id:
            q = q.where(Expense.project_id == project_id)

        rows = self.db.execute(q).all()
        grand_total = Decimal("0")
        category_map: dict[str, Decimal] = {}
        project_map: dict[str, dict] = {}

        for r in rows:
            total = Decimal(str(r.total))
            grand_total += total
            cat = r.category
            category_map[cat] = category_map.get(cat, Decimal("0")) + total

            pid = str(r.project_id)
            if pid not in project_map:
                project_map[pid] = {"project_id": pid, "name": r.project_name, "total": Decimal("0"), "categories": {}}
            project_map[pid]["total"] += total
            project_map[pid]["categories"][cat] = project_map[pid]["categories"].get(cat, Decimal("0")) + total

        # Build by_category with percentages
        by_category = []
        for cat, total in sorted(category_map.items()):
            pct = (total / grand_total * 100).quantize(Decimal("0.01")) if grand_total > 0 else Decimal("0.00")
            by_category.append({"category": cat, "total": total, "percentage": pct})

        # Build by_project with category breakdown
        by_project = []
        for pid, info in sorted(project_map.items(), key=lambda x: x[1]["name"]):
            proj_categories = []
            for cat, total in sorted(info["categories"].items()):
                pct = (total / info["total"] * 100).quantize(Decimal("0.01")) if info["total"] > 0 else Decimal("0.00")
                proj_categories.append({"category": cat, "total": total, "percentage": pct})
            by_project.append({
                "project_id": pid,
                "name": info["name"],
                "total": info["total"],
                "by_category": proj_categories,
            })

        return {
            "grand_total": grand_total,
            "by_category": by_category,
            "by_project": by_project,
        }