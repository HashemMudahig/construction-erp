"""Standard API response helpers."""
from typing import Any, List, Optional


def success(data: Any = None, message: str = "Operation completed") -> dict:
    return {"success": True, "message": message, "data": data}


def error(message: str, errors: Optional[List[Any]] = None) -> dict:
    return {"success": False, "message": message, "errors": errors or []}