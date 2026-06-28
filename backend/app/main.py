"""FastAPI application factory."""
from fastapi import APIRouter, Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.response import success

api_v1 = APIRouter(prefix="/api/v1")


@api_v1.get("/health")
def health() -> dict:
    return success(data={"status": "ok"}, message="Service is healthy")


@api_v1.get("/health/db")
def health_db(db: Session = Depends(get_db)) -> dict:
    try:
        db.execute(text("SELECT 1"))
        return success(data={"status": "ok"}, message="Database is healthy")
    except Exception as exc:  # pragma: no cover
        return {"success": False, "message": "Database health check failed", "errors": [str(exc)]}


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Construction ERP API",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root() -> dict:
    return success(data={"service": settings.app_name}, message="Construction ERP API Running")


app.include_router(api_v1)