"""Health endpoints."""
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success

router = APIRouter(prefix="/health", tags=["health"])


@router.get("")
def health() -> dict:
    return success(data={"status": "ok"}, message="Service is healthy")


@router.get("/db")
def health_db(db: Session = Depends(get_db)) -> dict:
    try:
        db.execute(text("SELECT 1"))
        return success(data={"status": "ok"}, message="Database is healthy")
    except Exception as exc:  # pragma: no cover
        return {"success": False, "message": "Database health check failed", "errors": [str(exc)]}