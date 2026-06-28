"""Sprint 02 smoke test — milestones, payments, expenses, profitability."""
from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def _login() -> str:
    r = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@constructionerp.app", "password": "change-me-on-first-login"},
    )
    assert r.status_code == 200, r.json()
    return r.json()["data"]["access_token"]


def _create_client(token: str) -> str:
    r = client.post(
        "/api/v1/clients",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Sprint02 Test Client"},
    )
    assert r.status_code == 201, r.json()
    return r.json()["data"]["id"]


def _create_project(token: str, client_id: str) -> str:
    r = client.post(
        "/api/v1/projects",
        headers={"Authorization": f"Bearer {token}"},
        json={"client_id": client_id, "name": "Sprint02 Tower", "budget": "1000000.00"},
    )
    assert r.status_code == 201, r.json()
    return r.json()["data"]["id"]


def test_milestone_crud_and_complete() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    cid = _create_client(token)
    pid = _create_project(token, cid)

    # create milestone
    r = client.post(
        "/api/v1/milestones",
        headers=H,
        json={"project_id": pid, "title": "Foundation", "due_date": "2026-09-01"},
    )
    assert r.status_code == 201, r.json()
    mid = r.json()["data"]["id"]
    assert r.json()["data"]["status"] == "pending"

    # milestone with invalid project -> 404
    r = client.post(
        "/api/v1/milestones",
        headers=H,
        json={"project_id": str(uuid4()), "title": "Bad", "due_date": "2026-09-01"},
    )
    assert r.status_code == 404
    assert r.json()["errors"][0]["code"] == "PROJECT_NOT_FOUND"

    # list milestones filtered by project
    r = client.get("/api/v1/milestones", headers=H, params={"project_id": pid})
    assert r.status_code == 200
    assert len(r.json()["data"]) == 1

    # complete milestone
    r = client.post(f"/api/v1/milestones/{mid}/complete", headers=H)
    assert r.status_code == 200
    assert r.json()["data"]["status"] == "completed"

    # complete again -> 400 invalid transition
    r = client.post(f"/api/v1/milestones/{mid}/complete", headers=H)
    assert r.status_code == 400
    assert r.json()["errors"][0]["code"] == "MILESTONE_INVALID_TRANSITION"

    # delete milestone
    r = client.delete(f"/api/v1/milestones/{mid}", headers=H)
    assert r.status_code == 200


def test_payment_crud_and_profitability() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    cid = _create_client(token)
    pid = _create_project(token, cid)

    # create payment
    r = client.post(
        "/api/v1/payments",
        headers=H,
        json={"project_id": pid, "amount": "500000.00", "payment_date": "2026-08-15", "method": "bank_transfer"},
    )
    assert r.status_code == 201, r.json()
    pay1 = r.json()["data"]["id"]

    # second payment
    r = client.post(
        "/api/v1/payments",
        headers=H,
        json={"project_id": pid, "amount": "200000.00", "payment_date": "2026-09-15", "method": "cash"},
    )
    assert r.status_code == 201

    # payment with zero amount -> 422
    r = client.post(
        "/api/v1/payments",
        headers=H,
        json={"project_id": pid, "amount": "0.00", "payment_date": "2026-09-15", "method": "cash"},
    )
    assert r.status_code == 422

    # payment with invalid project -> 404
    r = client.post(
        "/api/v1/payments",
        headers=H,
        json={"project_id": str(uuid4()), "amount": "100.00", "payment_date": "2026-09-15", "method": "cash"},
    )
    assert r.status_code == 404
    assert r.json()["errors"][0]["code"] == "PROJECT_NOT_FOUND"

    # list payments
    r = client.get("/api/v1/payments", headers=H, params={"project_id": pid})
    assert r.status_code == 200
    assert len(r.json()["data"]) == 2


def test_expense_crud() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    cid = _create_client(token)
    pid = _create_project(token, cid)

    # create expense
    r = client.post(
        "/api/v1/expenses",
        headers=H,
        json={"project_id": pid, "category": "materials", "amount": "150000.00", "expense_date": "2026-08-20"},
    )
    assert r.status_code == 201, r.json()
    eid = r.json()["data"]["id"]

    # expense with invalid category -> 422
    r = client.post(
        "/api/v1/expenses",
        headers=H,
        json={"project_id": pid, "category": "invalid_cat", "amount": "100.00", "expense_date": "2026-08-20"},
    )
    assert r.status_code == 422

    # list expenses filtered by project
    r = client.get("/api/v1/expenses", headers=H, params={"project_id": pid})
    assert r.status_code == 200
    assert len(r.json()["data"]) == 1

    # update expense
    r = client.put(f"/api/v1/expenses/{eid}", headers=H, json={"amount": "175000.00"})
    assert r.status_code == 200
    assert r.json()["data"]["amount"] == "175000.00"


def test_profitability() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    cid = _create_client(token)
    pid = _create_project(token, cid)

    # add payments totaling 700000
    client.post("/api/v1/payments", headers=H, json={"project_id": pid, "amount": "500000.00", "payment_date": "2026-08-15", "method": "bank_transfer"})
    client.post("/api/v1/payments", headers=H, json={"project_id": pid, "amount": "200000.00", "payment_date": "2026-09-15", "method": "cash"})

    # add expense of 175000
    client.post("/api/v1/expenses", headers=H, json={"project_id": pid, "category": "materials", "amount": "175000.00", "expense_date": "2026-08-20"})

    r = client.get(f"/api/v1/projects/{pid}/profitability", headers=H)
    assert r.status_code == 200, r.json()
    data = r.json()["data"]
    assert data["total_payments"] == "700000.00"
    assert data["total_expenses"] == "175000.00"
    assert data["balance"] == "525000.00"
    # profit_margin = 525000 / 700000 = 0.75
    assert data["profit_margin"] == "0.75"


def test_profitability_project_not_found() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    r = client.get(f"/api/v1/projects/{uuid4()}/profitability", headers=H)
    assert r.status_code == 404
    assert r.json()["errors"][0]["code"] == "PROJECT_NOT_FOUND"


def test_cascade_delete_project_removes_financials() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    cid = _create_client(token)
    pid = _create_project(token, cid)

    # add payment + expense + milestone
    client.post("/api/v1/payments", headers=H, json={"project_id": pid, "amount": "100000.00", "payment_date": "2026-08-15", "method": "cash"})
    client.post("/api/v1/expenses", headers=H, json={"project_id": pid, "category": "labor", "amount": "50000.00", "expense_date": "2026-08-20"})
    client.post("/api/v1/milestones", headers=H, json={"project_id": pid, "title": "Roof", "due_date": "2026-10-01"})

    # delete project -> CASCADE removes financials
    r = client.delete(f"/api/v1/projects/{pid}", headers=H)
    assert r.status_code == 200

    # verify payments gone
    r = client.get("/api/v1/payments", headers=H, params={"project_id": pid})
    assert r.status_code == 200
    assert len(r.json()["data"]) == 0

    # cleanup client
    client.delete(f"/api/v1/clients/{cid}", headers=H)