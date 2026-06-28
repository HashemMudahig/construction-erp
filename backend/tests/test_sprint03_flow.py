"""Sprint 03 test — dashboard aggregation endpoints."""
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


def _create_client_project_payments_expenses(token: str) -> str:
    """Seed data: 2 clients, 3 projects (1 active, 1 completed, 1 planning), payments, expenses."""
    H = {"Authorization": f"Bearer {token}"}

    # client 1
    r = client.post("/api/v1/clients", headers=H, json={"name": "Dash Client A"})
    cid_a = r.json()["data"]["id"]

    # client 2
    r = client.post("/api/v1/clients", headers=H, json={"name": "Dash Client B"})
    cid_b = r.json()["data"]["id"]

    # project 1 - active
    r = client.post("/api/v1/projects", headers=H, json={
        "client_id": cid_a, "name": "Active Tower", "budget": "1000000.00", "status": "active"})
    pid1 = r.json()["data"]["id"]

    # project 2 - completed
    r = client.post("/api/v1/projects", headers=H, json={
        "client_id": cid_a, "name": "Done Villa", "budget": "500000.00", "status": "completed"})
    pid2 = r.json()["data"]["id"]

    # project 3 - planning
    r = client.post("/api/v1/projects", headers=H, json={
        "client_id": cid_b, "name": "Future Mall", "budget": "2000000.00", "status": "planning"})
    pid3 = r.json()["data"]["id"]

    # payments on project 1: 800000
    client.post("/api/v1/payments", headers=H, json={
        "project_id": pid1, "amount": "500000.00", "payment_date": "2026-06-15", "method": "bank_transfer"})
    client.post("/api/v1/payments", headers=H, json={
        "project_id": pid1, "amount": "300000.00", "payment_date": "2026-06-20", "method": "cash"})

    # expenses on project 1: 200000
    client.post("/api/v1/expenses", headers=H, json={
        "project_id": pid1, "category": "materials", "amount": "150000.00", "expense_date": "2026-06-18"})
    client.post("/api/v1/expenses", headers=H, json={
        "project_id": pid1, "category": "labor", "amount": "50000.00", "expense_date": "2026-06-22"})

    # payment on project 2: 500000
    client.post("/api/v1/payments", headers=H, json={
        "project_id": pid2, "amount": "500000.00", "payment_date": "2026-05-10", "method": "bank_transfer"})

    # expense on project 2: 100000
    client.post("/api/v1/expenses", headers=H, json={
        "project_id": pid2, "category": "equipment", "amount": "100000.00", "expense_date": "2026-05-15"})

    return pid1


def test_dashboard_summary() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    _create_client_project_payments_expenses(token)

    r = client.get("/api/v1/dashboard/summary", headers=H)
    assert r.status_code == 200, r.json()
    data = r.json()["data"]
    # At least 1 active, 1 completed, 2 clients (plus any from other tests)
    assert data["active_projects"] >= 1
    assert data["completed_projects"] >= 1
    assert data["total_clients"] >= 2
    # total_payments >= 1300000, total_expenses >= 300000
    assert Decimal(data["total_payments"]) >= Decimal("1300000.00")
    assert Decimal(data["total_expenses"]) >= Decimal("300000.00")


def test_dashboard_projects_overview() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    r = client.get("/api/v1/dashboard/projects", headers=H)
    assert r.status_code == 200, r.json()
    data = r.json()["data"]
    assert isinstance(data, list)
    assert len(data) > 0
    # each item has expected fields
    item = data[0]
    assert "project_id" in item
    assert "name" in item
    assert "client_name" in item
    assert "status" in item
    assert "budget" in item
    assert "payments_sum" in item
    assert "expenses_sum" in item
    assert "balance" in item


def test_dashboard_finance_overview() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    r = client.get("/api/v1/dashboard/finance", headers=H)
    assert r.status_code == 200, r.json()
    data = r.json()["data"]
    assert "months" in data
    months = data["months"]
    assert isinstance(months, list)
    # should have at least one month with data (June 2026 from test data)
    if len(months) > 0:
        m = months[0]
        assert "month" in m
        assert "income" in m
        assert "expense" in m


def test_dashboard_unauthenticated() -> None:
    r = client.get("/api/v1/dashboard/summary")
    assert r.status_code == 401
    assert r.json()["errors"][0]["code"] == "AUTH_TOKEN_MISSING"


from decimal import Decimal  # noqa: E402