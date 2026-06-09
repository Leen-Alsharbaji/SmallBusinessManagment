"""
Domain and HTTP exception types with global FastAPI handlers.

Ensures the API always returns structured JSON error payloads that the
Flutter client can deserialize into typed error states.
"""

from typing import Any

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    """Base application error with HTTP status mapping."""

    def __init__(self, message: str, status_code: int = 400, code: str = "app_error"):
        self.message = message
        self.status_code = status_code
        self.code = code
        super().__init__(message)


class NotFoundError(AppError):
    """Raised when a requested resource does not exist."""

    def __init__(self, message: str = "Resource not found"):
        super().__init__(message, status_code=404, code="not_found")


class InsufficientStockError(AppError):
    """Raised when an order would drive inventory below zero."""

    def __init__(self, message: str = "Insufficient stock for this order"):
        super().__init__(message, status_code=409, code="insufficient_stock")


class ExternalServiceError(AppError):
    """Raised when Postman Mock or another outbound API is unavailable."""

    def __init__(self, message: str = "External service unavailable"):
        super().__init__(message, status_code=502, code="external_service_error")


def error_payload(message: str, code: str, details: Any | None = None) -> dict[str, Any]:
    """Build a consistent API error response body."""
    payload: dict[str, Any] = {"error": {"message": message, "code": code}}
    if details is not None:
        payload["error"]["details"] = details
    return payload


def register_exception_handlers(app: FastAPI) -> None:
    """Attach global exception handlers to the FastAPI application."""

    @app.exception_handler(AppError)
    async def handle_app_error(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=error_payload(exc.message, exc.code),
        )

    @app.exception_handler(Exception)
    async def handle_unexpected_error(_: Request, exc: Exception) -> JSONResponse:
        return JSONResponse(
            status_code=500,
            content=error_payload(
                "An unexpected error occurred",
                "internal_server_error",
                details=str(exc),
            ),
        )
