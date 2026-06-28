"""Pagination helper for list endpoints."""
from typing import Any, Dict, List


def paginate(items: List[Any], skip: int = 0, limit: int = 50) -> Dict[str, Any]:
    return {
        "items": items,
        "skip": skip,
        "limit": limit,
        "count": len(items),
    }