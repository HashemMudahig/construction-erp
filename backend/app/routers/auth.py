"""Auth router — login endpoint."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success
from app.schemas.auth import LoginRequest, TokenResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=None)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> dict:
    service = AuthService(db)
    token = service.login(email=payload.email, password=payload.password)
    return success(
        data=TokenResponse(access_token=token).model_dump(),
        message="Login successful",
    )