# Sprint 05 — Testing & QA Checklists

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Testing Strategy

| Layer | Tool | Coverage Target |
| --- | --- | --- |
| Unit | pytest | FileService path safety, CSV formatting, payload assembly |
| Integration | pytest + httpx + tmp UPLOAD_DIR | upload → list → download → delete cycle |
| API contract | pytest + multipart forms | all status codes in `05_API_Contract_OpenAPI.md` |
| QA | manual + checklist | end-to-end happy path + edge cases |

Tests live under `backend/tests/sprint_05/` mirroring the module names.

## 2. Unit Tests

### 2.1 FileService — Path Safety

| Test | Expected |
| --- | --- |
| `secure_filename("../../etc/passwd")` | strips to `etc_passwd` (no path separators) |
| Upload with filename `..\..\windows\system32\config` | `PATH_TRAVERSAL_BLOCKED` raised |
| Upload with UUID-based path resolves inside `UPLOAD_DIR` | succeeds |
| Filename with control chars (`\x00`) | stripped; upload succeeds |
| Reserved Windows name `CON.txt` | renamed / rejected |

### 2.2 ExportService — CSV Formatting

| Test | Expected |
| --- | --- |
| CSV starts with UTF-8 BOM (`\ufeff`) | yes |
| Header row matches report columns | yes |
| Field containing comma is quoted | `"a,b"` |
| Field containing newline is quoted | `"line1\nline2"` |
| Empty report → CSV has header only | yes |
| `export_report_csv("invalid")` | raises `EXPORT_UNAVAILABLE` |

### 2.3 ExportService — Project Payload

| Test | Expected |
| --- | --- |
| Project with no milestones/payments/expenses | payload has empty arrays + zero summary |
| Project with data | payload contains all four sections + computed summary |
| Missing project | `PROJECT_NOT_FOUND` |
| Summary math: `total_paid - total_expenses`, `remaining_budget = budget - total_expenses` | correct |

## 3. Integration Tests

### 3.1 Upload → List → Download → Delete Cycle

```python
async def test_file_lifecycle(tmp_upload_dir, client, auth_headers, sample_project):
    # upload
    with open("tests/fixtures/sample.pdf", "rb") as f:
        r = await client.post("/api/v1/files/upload",
            files={"file": ("sample.pdf", f, "application/pdf")},
            data={"project_id": str(sample_project.id), "category": "contract"},
            headers=auth_headers)
    assert r.status_code == 201
    file_id = r.json()["data"]["file_id"]

    # list
    r = await client.get(f"/api/v1/files?project_id={sample_project.id}", headers=auth_headers)
    assert r.status_code == 200 and len(r.json()["data"]) == 1

    # download
    r = await client.get(f"/api/v1/files/{file_id}", headers=auth_headers)
    assert r.status_code == 200 and r.headers["content-type"] == "application/pdf"

    # delete
    r = await client.delete(f"/api/v1/files/{file_id}", headers=auth_headers)
    assert r.status_code == 204

    # verify gone
    r = await client.get(f"/api/v1/files/{file_id}", headers=auth_headers)
    assert r.status_code == 404
```

### 3.2 Size & Type Enforcement

| Test | Expected Status |
| --- | --- |
| Upload 26 MB file (limit 25) | 413 |
| Upload `.exe` file | 400 `INVALID_FILE_TYPE` |
| Upload valid `.pdf` within limit | 201 |
| Upload to non-existent `project_id` | 400 `PROJECT_NOT_FOUND` |

### 3.3 CSV Export Content Matches Report Data

```python
async def test_csv_matches_report(client, auth_headers, seeded_data):
    # GET /reports/project_status (Sprint 04 JSON)
    r_json = await client.get("/api/v1/reports/project_status", headers=auth_headers)
    # GET /export/reports?type=project_status&format=csv
    r_csv = await client.get("/api/v1/export/reports?type=project_status&format=csv", headers=auth_headers)
    csv_rows = list(csv.reader(io.StringIO(r_csv.text.lstrip("\ufeff"))))
    # assert headers + row count + key columns match
    assert csv_rows[0] == ["project_id","name","status","start_date","end_date","progress_pct"]
    assert len(csv_rows) - 1 == len(r_json.json()["data"])
```

### 3.4 Project Export Payload Completeness

| Assertion | Expected |
| --- | --- |
| `project` block present with `id`, `name`, `budget` | yes |
| `milestones` is a list (may be empty) | yes |
| `payments` is a list | yes |
| `expenses` is a list | yes |
| `summary.total_paid == sum(payments.amount)` | yes |
| `summary.total_expenses == sum(expenses.amount)` | yes |
| `summary.remaining_budget == budget - total_expenses` | yes |

## 4. QA Checklist (Manual)

| # | Scenario | Pass Criteria |
| --- | --- | --- |
| 1 | Upload PDF as `contract` | 201; file appears in project files tab |
| 2 | Upload PNG as `drawing` | 201; previewable |
| 3 | Upload 26 MB file | 413 with `FILE_TOO_LARGE` |
| 4 | Upload `.exe` | 400 with `INVALID_FILE_TYPE` |
| 5 | Download an uploaded file | bytes match original |
| 6 | Delete a file | row disappears; disk file gone; GET returns 404 |
| 7 | Delete a project | its files removed (cascade) |
| 8 | `GET /files?project_id=` for empty project | 200 with `[]` |
| 9 | CSV export project_status | file downloads; opens in Excel with correct columns |
| 10 | CSV export financial_summary | sums match dashboard |
| 11 | CSV export expense_analysis | rows match expense list |
| 12 | Project export payload | contains project + milestones + payments + expenses + summary |
| 13 | Path traversal attempt (`../x`) | 400 `PATH_TRAVERSAL_BLOCKED`; alert logged |
| 14 | All endpoints without JWT | 401 |
| 15 | Invalid report type | 400 `EXPORT_UNAVAILABLE` |

## 5. Test Report Deliverable (S05-T06)

QA produces a report containing:
- Test matrix (the checklist above) with pass/fail per item.
- Defects logged with severity.
- Coverage summary (unit + integration %).
- Sign-off by QA Tester and Tech Lead.

## 6. Definition of Done for QA

- All checklist items pass.
- No open Critical/High defects.
- Unit + integration test suite green on CI.
- Path traversal and size-limit tests explicitly included in the report.