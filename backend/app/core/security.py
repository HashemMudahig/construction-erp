"""Security helpers: JWT tokens, password hashing, and auth dependency."""
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.exceptions import AppException

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(subject: str, expires_minutes: Optional[int] = None) -> str:
    minutes = expires_minutes if expires_minutes is not None else settings.access_token_expire_minutes
    expire = datetime.now(timezone.utc) + timedelta(minutes=minutes)
    payload = {"sub": subject, "exp": expire}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        return payload.get("sub")
    except JWTError:
        return None


def require_user(
    token: Optional[str] = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> str:
    """Dependency that protects endpoints. Returns the authenticated user's email.

    v1 has a single admin; we return the email as the principal identifier.
    """
    if not token:
        raise AppException(
            code="AUTH_TOKEN_MISSING",
            http_status=401,
            message="Authentication required",
            detail="Authorization header missing",
        )
    email = decode_access_token(token)
    if email is None:
        raise AppException(
            code="AUTH_TOKEN_INVALID",
            http_status=401,
            message="Authentication required",
            detail="Token signature invalid",
        )
    from app.models.user import User
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise AppException(
            code="AUTH_TOKEN_INVALID",
            http_status=401,
            message="Authentication required",
            detail="User no longer exists",
        )
    return email