"""Sprint 01 smoke test — exercises the full auth + clients + projects flow."""
from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def login():
    r = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@constructionerp.app", "password": "change-me-on-first-login"},
    )
    assert r.status_code == 200, r.json()
    return r.json()["data"]["access_token"]


def test_health() -> None:
    r = client.get("/api/v1/health")
    assert r.status_code == 200
    assert r.json()["success"] is True


def test_auth_and_crud_flow() -> None:
    token = login()
    H = {"Authorization": f"Bearer {token}"}

    # protected without token -> 401 AUTH_TOKEN_MISSING
    r = client.get("/api/v1/clients")
    assert r.status_code == 401
    assert r.json()["errors"][0]["code"] == "AUTH_TOKEN_MISSING"

    # bad login -> 401 AUTH_INVALID_CREDENTIALS
    r = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@constructionerp.app", "password": "wrong"},
    )
    assert r.status_code == 401
    assert r.json()["errors"][0]["code"] == "AUTH_INVALID_CREDENTIALS"

    # create client
    r = client.post(
        "/api/v1/clients",
        headers=H,
        json={"name": "Acme Builders", "phone": "+971501234567", "email": "acme@example.com"},
    )
    assert r.status_code == 201, r.json()
    cid = r.json()["data"]["id"]

    # list clients contains it
    r = client.get("/api/v1/clients", headers=H, params={"limit": 100})
    assert r.status_code == 200
    names = [c["name"] for c in r.json()["data"]]
    assert "Acme Builders" in names

    # search
    r = client.get("/api/v1/clients", headers=H, params={"search": "Acme"})
    assert r.status_code == 200
    assert any("Acme" in c["name"] for c in r.json()["data"])

    # get client
    r = client.get(f"/api/v1/clients/{cid}", headers=H)
    assert r.status_code == 200
    assert r.json()["data"]["id"] == cid

    # update client
    r = client.put(f"/api/v1/clients/{cid}", headers=H, json={"notes": "VIP client"})
    assert r.status_code == 200
    assert r.json()["data"]["notes"] == "VIP client"

    # create project with valid client
    r = client.post(
        "/api/v1/projects",
        headers=H,
        json={
            "client_id": cid,
            "name": "Tower A",
            "budget": "1500000.00",
            "start_date": "2026-08-01",
            "end_date": "2027-06-30",
            "status": "planning",
        },
    )
    assert r.status_code == 201, r.json()
    pid = r.json()["data"]["id"]
    assert r.json()["data"]["budget"] == "1500000.00"

    # project with invalid client -> 400 PROJECT_CLIENT_INVALID
    r = client.post(
        "/api/v1/projects",
        headers=H,
        json={"client_id": str(uuid4()), "name": "Bad", "budget": "100.00"},
    )
    assert r.status_code == 400
    assert r.json()["errors"][0]["code"] == "PROJECT_CLIENT_INVALID"

    # project with bad dates -> 400 PROJECT_DATE_INVALID
    r = client.post(
        "/api/v1/projects",
        headers=H,
        json={
            "client_id": cid,
            "name": "Bad Dates",
            "budget": "100.00",
            "start_date": "2027-01-01",
            "end_date": "2026-01-01",
        },
    )
    assert r.status_code == 400
    assert r.json()["errors"][0]["code"] == "PROJECT_DATE_INVALID"

    # list projects filtered by client_id
    r = client.get("/api/v1/projects", headers=H, params={"client_id": cid})
    assert r.status_code == 200
    assert any(p["id"] == pid for p in r.json()["data"])

    # delete client with projects -> 409 CLIENT_HAS_PROJECTS
    r = client.delete(f"/api/v1/clients/{cid}", headers=H)
    assert r.status_code == 409
    assert r.json()["errors"][0]["code"] == "CLIENT_HAS_PROJECTS"

    # delete project then client -> ok
    r = client.delete(f"/api/v1/projects/{pid}", headers=H)
    assert r.status_code == 200
    r = client.delete(f"/api/v1/clients/{cid}", headers=H)
    assert r.status_code == 200

    # validation error -> 422
    r = client.post("/api/v1/clients", headers=H, json={"name": ""})
    assert r.status_code == 422
    assert r.json()["errors"][0]["code"] == "VALIDATION_ERROR"

    # not found -> 404
    r = client.get(f"/api/v1/clients/{uuid4()}", headers=H)
    assert r.status_code == 404
    assert r.json()["errors"][0]["code"] == "CLIENT_NOT_FOUND"