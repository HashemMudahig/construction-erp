"""Smoke test: the FastAPI app imports and the root/health routes exist."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_app_imports() -> None:
    assert app.title == "Construction ERP"


def test_root_envelope() -> None:
    response = client.get("/")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True