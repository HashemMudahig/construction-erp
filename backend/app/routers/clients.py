"""Clients router — CRUD endpoints."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success
from app.core.security import require_user
from app.schemas.client import ClientCreate, ClientRead, ClientUpdate
from app.services.client_service import ClientService

router = APIRouter(prefix="/clients", tags=["clients"])


@router.get("")
def list_clients(
    search: str | None = Query(default=None),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ClientService(db)
    items = service.list(search=search, skip=skip, limit=limit)
    return success(
        data=[ClientRead.model_validate(c).model_dump(mode="json") for c in items],
        message="Clients retrieved",
    )


@router.post("", status_code=201)
def create_client(
    payload: ClientCreate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ClientService(db)
    client = service.create(payload.model_dump(mode="json"))
    return success(
        data=ClientRead.model_validate(client).model_dump(mode="json"),
        message="Client created",
    )


@router.get("/{client_id}")
def get_client(
    client_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ClientService(db)
    client = service.get(client_id)
    return success(
        data=ClientRead.model_validate(client).model_dump(mode="json"),
        message="Client retrieved",
    )


@router.put("/{client_id}")
def update_client(
    client_id: str,
    payload: ClientUpdate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ClientService(db)
    client = service.update(client_id, payload.model_dump(exclude_unset=True, mode="json"))
    return success(
        data=ClientRead.model_validate(client).model_dump(mode="json"),
        message="Client updated",
    )


@router.delete("/{client_id}")
def delete_client(
    client_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ClientService(db)
    service.delete(client_id)
    return success(data={"id": client_id}, message="Client deleted")