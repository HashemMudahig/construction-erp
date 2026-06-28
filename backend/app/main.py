"""FastAPI application factory."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.exceptions import register_exception_handlers
from app.core.response import success
from app.routers import auth_router, clients_router, health_router, projects_router

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Construction ERP API",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_exception_handlers(app)

app.include_router(health_router, prefix="/api/v1")
app.include_router(auth_router, prefix="/api/v1")
app.include_router(clients_router, prefix="/api/v1")
app.include_router(projects_router, prefix="/api/v1")


@app.get("/")
def root() -> dict:
    return success(data={"service": settings.app_name}, message="Construction ERP API Running")