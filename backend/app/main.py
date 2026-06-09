"""
FastAPI application factory.

Wires routers, CORS, exception handlers, and legacy route aliases so existing
Flutter clients continue to work during migration.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.exceptions import register_exception_handlers
from app.routers import auth, inventory, legacy, orders, sync


def create_app() -> FastAPI:
    """Build and configure the Smart Inventory Hub API application."""
    settings = get_settings()
    app = FastAPI(title=settings.app_name)

    origins = [o.strip() for o in settings.cors_origins.split(",")]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    register_exception_handlers(app)

    # Domain routers (Separation of Concerns endpoints)
    app.include_router(auth.router, prefix="/api")
    app.include_router(inventory.router, prefix="/api")
    app.include_router(orders.router, prefix="/api")
    app.include_router(sync.router, prefix="/api")
    app.include_router(legacy.router, prefix="/api")

    @app.get("/")
    def root():
        return {"message": settings.app_name}

    return app


app = create_app()
