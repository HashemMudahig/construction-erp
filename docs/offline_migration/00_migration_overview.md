# Phase 00 — Migration Overview

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Establish the business rationale, scope, assumptions, and high-level plan for converting the Construction ERP from a server-dependent application to a local-first, fully offline, single-user, single-device Flutter application.

## Current State

The Construction ERP is a two-tier application:

- **Frontend:** Flutter application using Riverpod for state management, GoRouter for navigation, and Dio for HTTP communication with the backend.
- **Backend:** FastAPI application using SQLAlchemy 2.x ORM, Alembic migrations, PostgreSQL, Pydantic v2 schemas, and JWT-based authentication.

All data operations (CRUD for clients, projects, milestones, payments, expenses; dashboard aggregations; report generation) require a running backend accessible over HTTP. The Dio provider at `frontend/lib/core/network/dio_provider.dart` configures a base URL of `http://10.0.2.2:8000/api/v1` (Android emulator alias for host localhost).

The dashboard providers at `frontend/lib/features/dashboard/presentation/dashboard_providers.dart` currently return static mock data as a temporary measure, but the application architecture still depends on Dio and the backend response envelope.

## Target State

- A Flutter application that stores all data in a local SQLite database via the Drift ORM.
- No runtime network dependency. The application must function in airplane mode.
- Single administrative user on a single device.
- No synchronization with a remote server in the first local release.
- The FastAPI backend source code remains in the repository, preserved and buildable, but is not invoked at runtime.

## Scope

- Flutter frontend becomes local-first/offline.
- FastAPI backend remains preserved as a possible future remote adapter.
- Single user, single device, no server requirement.
- No synchronization in the first local release.

## Out of Scope

- Multi-user or multi-device support.
- Real-time or background synchronization.
- Cloud backup (local backup to file is in scope; cloud sync is not).
- Removal of FastAPI backend source code.
- Changes to backend application behavior.

## Prerequisites

None. This is the first phase.

## Relevant Current Files

- `frontend/lib/core/network/dio_provider.dart` — Current HTTP client configuration.
- `frontend/lib/core/config/app_config.dart` — Current backend base URL.
- `frontend/lib/core/constants/endpoints.dart` — All API endpoint constants.
- `frontend/lib/core/router/app_router.dart` — Current routing (includes auth redirect).
- `frontend/lib/features/auth/` — Current authentication implementation.
- `backend/app/main.py` — FastAPI application entry point.
- `backend/app/models/` — All SQLAlchemy ORM models.
- `backend/app/schemas/` — All Pydantic schemas.

## Expected New Files

- `docs/offline_migration/` directory and all phase documents (this file and its siblings).
- `docs/offline_migration/architecture_target.md` — Target architecture document.
- `docs/offline_migration/data_model_mapping.md` — Field-level mapping document.
- `docs/offline_migration/decision_log.md` — Decision log.
- `docs/offline_migration/risk_register.md` — Risk register.

## Data Model Impact

No data model changes in this phase. This phase is documentation-only.

## Repository and Provider Impact

No repository or provider changes in this phase. This phase is documentation-only.

## Implementation Tasks

- [ ] Confirm business rationale for local conversion with stakeholders.
- [ ] Confirm single-user and single-device assumptions.
- [ ] Confirm that no synchronization is needed in the first local release.
- [ ] Confirm that the FastAPI backend must remain preserved.
- [ ] Review and approve the phase list and dependencies.
- [ ] Review and approve the decision log initial entries.
- [ ] Review and approve the risk register.

## Validation Plan

This phase is documentation-only. No code validation is required.

## Acceptance Criteria

1. Migration overview document is complete and reviewed.
2. Phase list is agreed upon.
3. Decision log contains initial ADRs (ADR-001 through ADR-010).
4. Risk register contains identified risks.
5. All stakeholders confirm the migration scope and constraints.

## Risks

See [risk_register.md](risk_register.md) for the full risk register. Key risks for this phase:

- R-002: App uninstall causes total data loss — mitigated by backup/restore (Phase 11).
- R-019: Documentation becomes stale — mitigated by mandatory history updates after each phase.

## Rollback Strategy

This phase is documentation-only. No rollback is needed. Documents can be revised or withdrawn.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 00 status to Ready.
- `docs/history.md` — Add entry for migration overview approval.
- `docs/offline_migration/decision_log.md` — Mark ADRs as Accepted if approved.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None (documentation-only)
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent