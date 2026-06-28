"""Milestones router — CRUD + complete endpoint."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success
from app.core.security import require_user
from app.schemas.milestone import MilestoneCreate, MilestoneRead, MilestoneUpdate
from app.services.milestone_service import MilestoneService

router = APIRouter(prefix="/milestones", tags=["milestones"])


@router.get("")
def list_milestones(
    project_id: str | None = Query(default=None),
    status: str | None = Query(default=None),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = MilestoneService(db)
    items = service.list(project_id=project_id, status=status, skip=skip, limit=limit)
    return success(
        data=[MilestoneRead.model_validate(m).model_dump(mode="json") for m in items],
        message="Milestones retrieved",
    )


@router.post("", status_code=201)
def create_milestone(
    payload: MilestoneCreate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = MilestoneService(db)
    m = service.create(payload.model_dump(mode="json"))
    return success(
        data=MilestoneRead.model_validate(m).model_dump(mode="json"),
        message="Milestone created",
    )


@router.get("/{milestone_id}")
def get_milestone(
    milestone_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = MilestoneService(db)
    m = service.get(milestone_id)
    return success(
        data=MilestoneRead.model_validate(m).model_dump(mode="json"),
        message="Milestone retrieved",
    )


@router.put("/{milestone_id}")
def update_milestone(
    milestone_id: str,
    payload: MilestoneUpdate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = MilestoneService(db)
    m = service.update(milestone_id, payload.model_dump(exclude_unset=True, mode="json"))
    return success(
        data=MilestoneRead.model_validate(m).model_dump(mode="json"),
        message="Milestone updated",
    )


@router.post("/{milestone_id}/complete")
def complete_milestone(
    milestone_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = MilestoneService(db)
    m = service.complete(milestone_id)
    return success(
        data=MilestoneRead.model_validate(m).model_dump(mode="json"),
        message="Milestone completed",
    )


@router.delete("/{milestone_id}")
def delete_milestone(
    milestone_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = MilestoneService(db)
    service.delete(milestone_id)
    return success(data={"id": milestone_id}, message="Milestone deleted")