"""Idempotent seed for the single admin account.

Run after `alembic upgrade head`:
    python -m app.db.seed

Creates exactly one admin row if no users exist; no-op otherwise.
"""
from app.core.config import settings
from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models.user import User


def seed_admin() -> None:
    db = SessionLocal()
    try:
        existing = db.query(User).first()
        if existing is not None:
            print(f"[seed] Users already present (first: {existing.email}). Skipping.")
            return
        admin = User(
            name=settings.admin_name,
            email=settings.admin_email,
            password_hash=hash_password(settings.admin_password),
            role="admin",
        )
        db.add(admin)
        db.commit()
        print(f"[seed] Admin created: {admin.email}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_admin()