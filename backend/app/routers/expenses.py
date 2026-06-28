"""Expenses router — CRUD endpoints."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success
from app.core.security import require_user
from app.schemas.expense import ExpenseCreate, ExpenseRead, ExpenseUpdate
from app.services.expense_service import ExpenseService

router = APIRouter(prefix="/expenses", tags=["expenses"])


@router.get("")
def list_expenses(
    project_id: str | None = Query(default=None),
    category: str | None = Query(default=None),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ExpenseService(db)
    items = service.list(project_id=project_id, category=category, skip=skip, limit=limit)
    return success(
        data=[ExpenseRead.model_validate(e).model_dump(mode="json") for e in items],
        message="Expenses retrieved",
    )


@router.post("", status_code=201)
def create_expense(
    payload: ExpenseCreate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ExpenseService(db)
    e = service.create(payload.model_dump(mode="json"))
    return success(
        data=ExpenseRead.model_validate(e).model_dump(mode="json"),
        message="Expense created",
    )


@router.get("/{expense_id}")
def get_expense(
    expense_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ExpenseService(db)
    e = service.get(expense_id)
    return success(
        data=ExpenseRead.model_validate(e).model_dump(mode="json"),
        message="Expense retrieved",
    )


@router.put("/{expense_id}")
def update_expense(
    expense_id: str,
    payload: ExpenseUpdate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ExpenseService(db)
    e = service.update(expense_id, payload.model_dump(exclude_unset=True, mode="json"))
    return success(
        data=ExpenseRead.model_validate(e).model_dump(mode="json"),
        message="Expense updated",
    )


@router.delete("/{expense_id}")
def delete_expense(
    expense_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ExpenseService(db)
    service.delete(expense_id)
    return success(data={"id": expense_id}, message="Expense deleted")