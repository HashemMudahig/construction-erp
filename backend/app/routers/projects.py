"""Projects router — CRUD endpoints."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success
from app.core.security import require_user
from app.schemas.project import ProjectCreate, ProjectRead, ProjectUpdate
from app.services.project_service import ProjectService

router = APIRouter(prefix="/projects", tags=["projects"])


@router.get("")
def list_projects(
    client_id: str | None = Query(default=None),
    status: str | None = Query(default=None),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ProjectService(db)
    items = service.list(client_id=client_id, status=status, skip=skip, limit=limit)
    return success(
        data=[ProjectRead.model_validate(p).model_dump(mode="json") for p in items],
        message="Projects retrieved",
    )


@router.post("", status_code=201)
def create_project(
    payload: ProjectCreate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ProjectService(db)
    project = service.create(payload.model_dump(mode="json"))
    return success(
        data=ProjectRead.model_validate(project).model_dump(mode="json"),
        message="Project created",
    )


@router.get("/{project_id}")
def get_project(
    project_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ProjectService(db)
    project = service.get(project_id)
    return success(
        data=ProjectRead.model_validate(project).model_dump(mode="json"),
        message="Project retrieved",
    )


@router.put("/{project_id}")
def update_project(
    project_id: str,
    payload: ProjectUpdate,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ProjectService(db)
    project = service.update(project_id, payload.model_dump(exclude_unset=True, mode="json"))
    return success(
        data=ProjectRead.model_validate(project).model_dump(mode="json"),
        message="Project updated",
    )


@router.delete("/{project_id}")
def delete_project(
    project_id: str,
    db: Session = Depends(get_db),
    _: str = Depends(require_user),
) -> dict:
    service = ProjectService(db)
    service.delete(project_id)
    return success(data={"id": project_id}, message="Project deleted")