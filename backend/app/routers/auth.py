"""
Authentication and marketplace credential routers.

Prefix: /auth
Responsibility: HTTP I/O only — delegates to MarketplaceService.
"""

from fastapi import APIRouter, Depends

from app.dependencies import get_marketplace_service
from app.models.auth import TrendyolConnectionStatus, TrendyolCredentials
from app.services.marketplace_service import MarketplaceService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/marketplace/trendyol")
async def connect_trendyol(
    creds: TrendyolCredentials,
    service: MarketplaceService = Depends(get_marketplace_service),
):
    """Encrypt and store Trendyol seller credentials for a Firebase user."""
    return service.connect_trendyol(creds)


@router.get("/marketplace/trendyol/{uid}", response_model=TrendyolConnectionStatus)
async def trendyol_connection_status(
    uid: str,
    service: MarketplaceService = Depends(get_marketplace_service),
):
    """Return whether Trendyol credentials are stored for the given user."""
    return service.get_trendyol_status(uid)


@router.get("/marketplace/trendyol/{uid}/products")
async def trendyol_products(
    uid: str,
    service: MarketplaceService = Depends(get_marketplace_service),
):
    """Proxy product fetch through Postman Mock Trendyol API."""
    return service.fetch_trendyol_products(uid)


@router.get("/marketplace/trendyol/{uid}/orders")
async def trendyol_orders(
    uid: str,
    service: MarketplaceService = Depends(get_marketplace_service),
):
    """Proxy order fetch through Postman Mock Trendyol API."""
    return service.fetch_trendyol_orders(uid)
