"""Outbound marketplace integration models."""

from pydantic import BaseModel


class TrendyolProduct(BaseModel):
    """Subset of Trendyol Public API product fields used by sync."""

    id: int
    title: str
    stockCode: str | None = None
    quantity: int = 0
    salePrice: float | None = None
    barcode: str | None = None


class TrendyolOrder(BaseModel):
    """Subset of Trendyol order line items."""

    orderNumber: str
    status: str
    totalPrice: float
    lines: list[dict] = []
