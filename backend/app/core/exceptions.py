"""Application exceptions and FastAPI exception handlers.

Services raise `AppException` with a stable error code and HTTP status.
A single FastAPI handler maps it to the standard error envelope.
"""
from typing import Any, List, Optional

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


class AppException(Exception):
    def __init__(
        self,
        code: str,
        http_status: int,
        message: str,
        field: Optional[str] = None,
        detail: Optional[str] = None,
    ) -> None:
        self.code = code
        self.http_status = http_status
        self.message = message
        self.field = field
        self.detail = detail if detail is not None else message
        super().__init__(message)

    def to_error(self) -> dict:
        err: dict = {"code": self.code, "detail": self.detail}
        if self.field is not None:
            err["field"] = self.field
        return err


def _envelope(success: bool, message: str, errors: Optional[List[Any]] = None) -> dict:
    body: dict = {"success": success, "message": message}
    if errors is not None:
        body["errors"] = errors
    return body


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppException)
    async def handle_app_exception(_: Request, exc: AppException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.http_status,
            content=_envelope(False, exc.message, [exc.to_error()]),
        )

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(_: Request, exc: RequestValidationError) -> JSONResponse:
        errors: List[dict] = []
        for err in exc.errors():
            field = ".".join(str(loc) for loc in err.get("loc", []) if loc != "body")
            errors.append({
                "code": "VALIDATION_ERROR",
                "field": field or None,
                "detail": err.get("msg", "Validation error"),
            })
        return JSONResponse(
            status_code=422,
            content=_envelope(False, "Validation failed", errors),
        )

    @app.exception_handler(Exception)
    async def handle_unexpected(_: Request, exc: Exception) -> JSONResponse:
        return JSONResponse(
            status_code=500,
            content=_envelope(False, "Internal server error", [
                {"code": "INTERNAL_ERROR", "detail": "An unexpected error occurred"},
            ]),
        )