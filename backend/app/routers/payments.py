"""Payments router — CRUD endpoints."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success
from app.core.security import require_user
from app.schemas.payment import PaymentCreate, PaymentRead, PaymentUpdate
from app.services.payment_service import PaymentService

router = APIRouter(prefix="/payments", tags=["payments"])


@router.get("")
def list_payments(
    project_id: str | None = Query(default=None),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = PaymentService(db)
    items = service.list(project_id=project_id, skip=skip, limit=limit)
    return success(
        data=[PaymentRead.model_validate(p).model_dump(mode="json") for p in items],
        message="Payments retrieved",
    )


@router.post("", status_code=201)
def create_payment(
    payload: PaymentCreate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = PaymentService(db)
    p = service.create(payload.model_dump(mode="json"))
    return success(
        data=PaymentRead.model_validate(p).model_dump(mode="json"),
        message="Payment created",
    )


@router.get("/{payment_id}")
def get_payment(
    payment_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = PaymentService(db)
    p = service.get(payment_id)
    return success(
        data=PaymentRead.model_validate(p).model_dump(mode="json"),
        message="Payment retrieved",
    )


@router.put("/{payment_id}")
def update_payment(
    payment_id: str,
    payload: PaymentUpdate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = PaymentService(db)
    p = service.update(payment_id, payload.model_dump(exclude_unset=True, mode="json"))
    return success(
        data=PaymentRead.model_validate(p).model_dump(mode="json"),
        message="Payment updated",
    )


@router.delete("/{payment_id}")
def delete_payment(
    payment_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = PaymentService(db)
    service.delete(payment_id)
    return success(data={"id": payment_id}, message="Payment deleted")