@echo off
REM Quick-start: docker postgres + migrate + seed + uvicorn
docker compose up -d postgres
timeout /t 3 /nobreak >nul
alembic upgrade head
python -m app.db.seed
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000