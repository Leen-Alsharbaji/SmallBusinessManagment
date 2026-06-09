"""
Legacy route aliases for backward compatibility during frontend migration.

Maps old /api/products and /api/stock paths to the new /api/inventory routes.
"""

from fastapi import APIRouter, Depends

from app.dependencies import get_product_service, get_stock_service
from app.models.product import ProductCreate, StockAdjustmentRequest
from app.services.product_service import ProductService
from app.services.stock_service import StockService

router = APIRouter(tags=["legacy"])


@router.get("/products/")
async def legacy_list_products(service: ProductService = Depends(get_product_service)):
    return service.list_products()


@router.post("/products/")
async def legacy_create_product(
    product: ProductCreate,
    service: ProductService = Depends(get_product_service),
):
    return service.create_product(product)


@router.get("/products/{product_id}")
async def legacy_get_product(
    product_id: str,
    service: ProductService = Depends(get_product_service),
):
    return service.get_product(product_id)


@router.put("/products/{product_id}")
async def legacy_update_product(
    product_id: str,
    product: ProductCreate,
    service: ProductService = Depends(get_product_service),
):
    from app.models.product import ProductUpdate

    return service.update_product(product_id, ProductUpdate(**product.model_dump()))


@router.delete("/products/{product_id}")
async def legacy_delete_product(
    product_id: str,
    service: ProductService = Depends(get_product_service),
):
    service.delete_product(product_id)
    return {"message": "deleted"}


@router.post("/stock/adjust")
async def legacy_adjust_stock(
    adjustment: StockAdjustmentRequest,
    service: StockService = Depends(get_stock_service),
):
    return service.adjust_stock(adjustment)
