"""Sprint 04 test — reports endpoints."""
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


def _seed_report_data(token: str) -> str:
    """Seed: 1 client, 1 project, 2 payments, 2 expenses, 2 milestones (1 completed)."""
    H = {"Authorization": f"Bearer {token}"}
    r = client.post("/api/v1/clients", headers=H, json={"name": "Report Test Client"})
    cid = r.json()["data"]["id"]
    r = client.post("/api/v1/projects", headers=H, json={
        "client_id": cid, "name": "Report Tower", "budget": "1000000.00", "status": "active"})
    pid = r.json()["data"]["id"]
    # payments
    client.post("/api/v1/payments", headers=H, json={
        "project_id": pid, "amount": "400000.00", "payment_date": "2026-07-01", "method": "bank_transfer"})
    client.post("/api/v1/payments", headers=H, json={
        "project_id": pid, "amount": "200000.00", "payment_date": "2026-07-15", "method": "cash"})
    # expenses
    client.post("/api/v1/expenses", headers=H, json={
        "project_id": pid, "category": "materials", "amount": "150000.00", "expense_date": "2026-07-10"})
    client.post("/api/v1/expenses", headers=H, json={
        "project_id": pid, "category": "labor", "amount": "100000.00", "expense_date": "2026-07-20"})
    # milestones
    client.post("/api/v1/milestones", headers=H, json={
        "project_id": pid, "title": "Foundation", "due_date": "2026-08-01"})
    r = client.post("/api/v1/milestones", headers=H, json={
        "project_id": pid, "title": "Roof", "due_date": "2026-09-01"})
    mid = r.json()["data"]["id"]
    client.post(f"/api/v1/milestones/{mid}/complete", headers=H)
    return pid


def test_project_status_report() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    pid = _seed_report_data(token)

    # all projects
    r = client.get("/api/v1/reports/project-status", headers=H)
    assert r.status_code == 200, r.json()
    data = r.json()["data"]
    assert isinstance(data, list)
    assert len(data) > 0
    # find our project
    item = next((d for d in data if d["project_id"] == pid), None)
    assert item is not None
    assert item["total_payments"] == "600000.00"
    assert item["total_expenses"] == "250000.00"
    assert item["balance"] == "350000.00"
    assert item["milestone_count"] == 2
    assert item["completed_milestones"] == 1
    assert item["progress_pct"] == "50.00"

    # filter by status
    r = client.get("/api/v1/reports/project-status", headers=H, params={"status": "active"})
    assert r.status_code == 200
    assert all(d["status"] == "active" for d in r.json()["data"])

    # filter by project_id
    r = client.get("/api/v1/reports/project-status", headers=H, params={"project_id": pid})
    assert r.status_code == 200
    assert len(r.json()["data"]) == 1

    # invalid project_id -> 404
    r = client.get("/api/v1/reports/project-status", headers=H, params={"project_id": str(uuid4())})
    assert r.status_code == 404
    assert r.json()["errors"][0]["code"] == "PROJECT_NOT_FOUND"


def test_financial_summary_report() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    _seed_report_data(token)

    # no date filter (all)
    r = client.get("/api/v1/reports/financial-summary", headers=H)
    assert r.status_code == 200, r.json()
    data = r.json()["data"]
    assert Decimal(data["total_income"]) >= Decimal("600000.00")
    assert Decimal(data["total_expenses"]) >= Decimal("250000.00")
    assert "per_project" in data
    assert isinstance(data["per_project"], list)

    # date range
    r = client.get("/api/v1/reports/financial-summary", headers=H,
                   params={"start_date": "2026-07-01", "end_date": "2026-07-31"})
    assert r.status_code == 200, r.json()

    # invalid date range -> 422
    r = client.get("/api/v1/reports/financial-summary", headers=H,
                   params={"start_date": "2026-08-01", "end_date": "2026-07-01"})
    assert r.status_code == 422
    assert r.json()["errors"][0]["code"] == "INVALID_DATE_RANGE"


def test_expense_analysis_report() -> None:
    token = _login()
    H = {"Authorization": f"Bearer {token}"}
    pid = _seed_report_data(token)

    r = client.get("/api/v1/reports/expense-analysis", headers=H)
    assert r.status_code == 200, r.json()
    data = r.json()["data"]
    assert Decimal(data["grand_total"]) >= Decimal("250000.00")
    assert "by_category" in data
    assert "by_project" in data
    # categories should include materials and labor
    cats = {c["category"] for c in data["by_category"]}
    assert "materials" in cats
    assert "labor" in cats
    # percentages should sum to ~100
    total_pct = sum(Decimal(c["percentage"]) for c in data["by_category"])
    assert total_pct <= Decimal("100.01")

    # filter by project_id
    r = client.get("/api/v1/reports/expense-analysis", headers=H, params={"project_id": pid})
    assert r.status_code == 200
    assert all(p["project_id"] == pid for p in r.json()["data"]["by_project"])

    # invalid date range -> 422
    r = client.get("/api/v1/reports/expense-analysis", headers=H,
                   params={"start_date": "2026-08-01", "end_date": "2026-07-01"})
    assert r.status_code == 422
    assert r.json()["errors"][0]["code"] == "INVALID_DATE_RANGE"

    # invalid project_id -> 404
    r = client.get("/api/v1/reports/expense-analysis", headers=H, params={"project_id": str(uuid4())})
    assert r.status_code == 404


def test_reports_unauthenticated() -> None:
    r = client.get("/api/v1/reports/project-status")
    assert r.status_code == 401
    assert r.json()["errors"][0]["code"] == "AUTH_TOKEN_MISSING"


from decimal import Decimal  # noqa: E402