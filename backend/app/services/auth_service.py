"""Auth service — login verifies bcrypt and issues a JWT."""
from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.core.security import create_access_token, verify_password
from app.models.user import User


class AuthService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def login(self, email: str, password: str) -> str:
        user = self.db.query(User).filter(User.email == email).first()
        if not user or not verify_password(password, user.password_hash):
            raise AppException(
                code="AUTH_INVALID_CREDENTIALS",
                http_status=401,
                message="Invalid email or password",
                detail="Invalid email or password",
            )
        return create_access_token(subject=user.email)