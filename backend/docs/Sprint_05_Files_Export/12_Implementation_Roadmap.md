# Sprint 05 — Implementation Roadmap

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Sprint Summary

| Item | Value |
| --- | --- |
| Sprint ID | S05 |
| Name | Files & Export |
| Period | 2026-08-31 to 2026-09-11 (10 working days) |
| Lead | Tech Lead |
| Total Story Points | 34 |
| Review Gate | Sprint Review at end of day 10 |

## 2. Backlog

| ID | Epic/Module | Task | Owner | Priority | SP | Dependency | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S05-T01 | Files / Backend | File model + upload endpoint (multipart, stored to disk) | Backend Developer | Critical | 8 | Sprint 01 | Upload stores file to disk + metadata in DB; returns file_id; linked to project. | File Upload API |
| S05-T02 | Files / Backend | File download + delete endpoints | Backend Developer | High | 5 | S05-T01 | Download streams file bytes; delete removes file + metadata. | File Download/Delete API |
| S05-T03 | Export / Backend | Export reports as CSV endpoint | Backend Developer | High | 5 | Sprint 04 | Returns CSV stream for project-status, financial-summary, expense-analysis reports. | CSV Export API |
| S05-T04 | Export / Backend | Export project summary as PDF-ready payload endpoint | Backend Developer | Medium | 5 | Sprint 04 | Returns structured project summary payload (project, milestones, payments, expenses) suitable for PDF rendering. | Project Export API |
| S05-T05 | Files+Export / Frontend | File management screen + export buttons | Frontend Developer | High | 8 | S05-T01, S05-T03 | Admin can upload/download/delete project files and trigger CSV/PDF export from reports. | File + Export Screens |
| S05-T06 | QA / Tests | File upload/download + export tests | QA Tester | High | 3 | S05-T01, S05-T02, S05-T03, S05-T04 | Test report covering file storage, download, delete, and export content. | QA Report |

## 3. Phases

| Phase | Days | Tasks | Output |
| --- | --- | --- | --- |
| Phase 1 — Files Backend | 1–4 | S05-T01, S05-T02 | File Upload/Download/Delete APIs + Alembic migration |
| Phase 2 — Export Backend | 5–7 | S05-T03, S05-T04 | CSV Export API + Project Export Payload API |
| Phase 3 — Frontend | 7–9 | S05-T05 | File management screen + export buttons in reports |
| Phase 4 — QA | 9–10 | S05-T06 | Test report + defect closure |

## 4. Critical Path

```
T01 (upload) ──► T02 (download/delete) ──► T05 (frontend files) ─┐
T03 (csv)  ──────────────────────────────► T05 (export buttons)─┤
T04 (project export) ────────────────────► T05 (export buttons)─┤
                                                                 ▼
                                                              T06 (QA)
```

Critical path: **T01 → T02 → T05 → T06**. T03 and T04 can proceed in parallel with T02.

## 5. Delivery Style

- Two-day check-ins (standups) led by Tech Lead.
- Code review required before merge to main (pull request + 1 approval).
- Trunk-based: feature branches `s05/files`, `s05/export`, `s05/frontend-files`.
- CI must pass (lint + typecheck + tests) before merge.
- Demo at Sprint Review using the Flutter app + real upload + CSV export.

## 6. Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Disk space exhaustion | Medium | High | Set `MAX_FILE_SIZE_MB`; monitor `disk_usage_bytes`; backup strategy |
| Path traversal exploit | Medium | Critical | Sanitize + UUID path + prefix check; security test in suite |
| Large file upload timeout | Medium | Medium | Stream upload; configure ASGI body limit; frontend progress UI |
| CSV encoding issues in Excel | Low | Low | Emit UTF-8 BOM; test in Excel |
| Orphaned disk files after failed deletes | Low | Low | Atomic delete (rename-then-commit); weekly reconciliation job |
| PDF-ready payload shape changes before rendering | Low | Low | Keep payload schema under test; document in OpenAPI |

## 7. Definition of Done

A task is done when:
- Code merged to main with passing CI.
- Acceptance criteria from the backlog table satisfied.
- Unit + integration tests added.
- Documentation (this folder) reflects the implementation.
- For T05: screen reviewed by Tech Lead; loading/empty/error states implemented.
- For T06: QA report signed off; no open Critical/High defects.

## 8. Closure Decision Rule

Sprint 05 is considered delivered when:
- All 6 backlog items meet their Definition of Done.
- Demo shows upload, download, delete, CSV export, and project export payload end-to-end.
- QA report is signed by QA Tester and Tech Lead.
- No Critical/High defects remain open.