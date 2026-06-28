#!/usr/bin/env bash
set -euo pipefail
docker compose up -d postgres
sleep 3
alembic upgrade head
python -m app.db.seed
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000