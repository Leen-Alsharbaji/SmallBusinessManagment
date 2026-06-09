"""FastAPI dependency injection helpers."""

from app.services.marketplace_service import MarketplaceService
from app.services.order_service import OrderService
from app.services.product_service import ProductService
from app.services.stock_service import StockService
from app.services.sync_service import SyncService


def get_product_service() -> ProductService:
    return ProductService()


def get_stock_service() -> StockService:
    return StockService()


def get_order_service() -> OrderService:
    return OrderService()


def get_marketplace_service() -> MarketplaceService:
    return MarketplaceService()


def get_sync_service() -> SyncService:
    return SyncService()
