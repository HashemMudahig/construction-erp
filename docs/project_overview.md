# Project Overview

## ERP Concept

A Construction ERP centralizes construction company operations, combining client management, project planning, financial tracking, expenses, and reporting into a single system. It supports stakeholders with reliable data, automation, and dashboards to improve execution, visibility, and decision-making.

## Modules

### Clients
Manage client profiles, contacts, and billing information. Track client status, communication history, and project assignments.

### Projects
Manage construction work packages, schedules, budgets, and milestones. Each project links to a client and contains financial tracking items and progress indicators.

### Payments
Track customer payments, invoicing records, payment dates, amounts, and reconciliation against project budgets.

### Expenses
Record project expenses, supplier bills, procurement costs, and category-level spending to compare actual costs against planned budgets.

### Reports
Generate financial, project, and expense reports. Provide exportable summaries for project health, cash flow, and expense analysis.

## Workflow

1. Create clients and assign them to construction projects.
2. Open projects with initial budgets and schedule information.
3. Log payments and invoices tied to projects and clients.
4. Record expenses and supplier costs under relevant projects.
5. Use report dashboards for progress, budget variance, and financial status.

## Deployment Target

### Current State

The application currently requires a running FastAPI backend with PostgreSQL. All data operations (CRUD, dashboard, reports) depend on HTTP communication with the server.

### Planned Offline Migration

> **Status: Planned — Implementation has not started.**

The Flutter frontend is planned to become a single-user, single-device, fully offline application using a local SQLite database via the Drift ORM. Key characteristics:

- **Single user:** One administrative user, no multi-tenant or RBAC complexity.
- **Single device:** Data is stored locally on the device.
- **No server requirement:** The application functions in airplane mode.
- **No synchronization:** The first local release does not sync with a remote server.
- **Backend preservation:** The FastAPI backend remains in the repository, preserved and buildable, as a possible future remote adapter.

See [Offline Migration Documentation](offline_migration/README.md) for the full migration plan.
