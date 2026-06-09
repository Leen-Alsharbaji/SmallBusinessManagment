"""
Order routers — manual WhatsApp/Instagram sales entry.

Prefix: /orders
"""

from typing import List

from fastapi import APIRouter, Depends

from app.dependencies import get_order_service
from app.models.order import ManualOrderCreate, OrderResponse
from app.services.order_service import OrderService

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post("/manual", response_model=OrderResponse)
async def create_manual_order(
    order: ManualOrderCreate,
    service: OrderService = Depends(get_order_service),
):
    """Record a manual sale with atomic stock decrement and audit trail."""
    return service.create_manual_order(order)


@router.get("/")
async def list_orders(service: OrderService = Depends(get_order_service)):
    """List all recorded orders."""
    return service.list_orders()
