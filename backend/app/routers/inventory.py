"""
Inventory routers — product CRUD and stock adjustments.

Prefix: /inventory
Responsibility: Request validation and HTTP responses only.
"""

from typing import List

from fastapi import APIRouter, Depends

from app.dependencies import get_product_service, get_stock_service
from app.models.product import (
    ProductCreate,
    ProductResponse,
    ProductUpdate,
    StockAdjustmentRequest,
)
from app.services.product_service import ProductService
from app.services.stock_service import StockService

router = APIRouter(prefix="/inventory", tags=["inventory"])


@router.get("/products", response_model=List[ProductResponse])
async def list_products(service: ProductService = Depends(get_product_service)):
    """Return all unified catalog products."""
    return service.list_products()


@router.post("/products", response_model=ProductResponse)
async def create_product(
    product: ProductCreate,
    service: ProductService = Depends(get_product_service),
):
    """Create a new unified product."""
    return service.create_product(product)


@router.get("/products/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: str,
    service: ProductService = Depends(get_product_service),
):
    """Fetch a single product by Firestore document ID."""
    return service.get_product(product_id)


@router.put("/products/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: str,
    product: ProductUpdate,
    service: ProductService = Depends(get_product_service),
):
    """Update mutable product fields."""
    return service.update_product(product_id, product)


@router.delete("/products/{product_id}")
async def delete_product(
    product_id: str,
    service: ProductService = Depends(get_product_service),
):
    """Remove a product from the unified catalog."""
    service.delete_product(product_id)
    return {"message": "deleted"}


@router.post("/stock/adjust")
async def adjust_stock(
    adjustment: StockAdjustmentRequest,
    service: StockService = Depends(get_stock_service),
):
    """Apply a manual stock adjustment with audit logging."""
    return service.adjust_stock(adjustment)
