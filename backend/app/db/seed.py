"""Idempotent seed for the single admin account.

This module is intentionally lightweight in v1: there is one administrative user.
A real users table is added in Sprint 01; this seed becomes effective once that
table exists. Until then, running it is a no-op that simply prints intent.
"""
from app.core.config import settings
from app.core.security import hash_password


def seed_admin() -> None:
    """Print the admin account that should be created once the users table exists.

    In v1 the system has a single admin. The actual persistence is wired in
    Sprint 01 when the User model is introduced. This function stays idempotent.
    """
    print(f"[seed] Admin email: {settings.admin_email}")
    print(f"[seed] Admin password hash: {hash_password(settings.admin_password)[:12]}...")
    print("[seed] Admin account prepared. Persist once the users table is migrated.")


if __name__ == "__main__":
    seed_admin()