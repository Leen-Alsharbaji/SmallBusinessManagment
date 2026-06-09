"""Product-related Pydantic schemas for inventory endpoints."""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class ProductCreate(BaseModel):
    """Payload for creating a unified inventory product."""

    name: str
    brand: str
    category: str
    description: str
    price: float
    totalStock: int = Field(ge=0)
    platforms: List[str]
    isManuallyReviewed: bool = True
    matchingConfidence: str = "high"
    sku: Optional[str] = None
    primaryImageUrl: Optional[str] = None


class ProductUpdate(BaseModel):
    """Partial product update payload."""

    name: Optional[str] = None
    brand: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    totalStock: Optional[int] = Field(default=None, ge=0)
    platforms: Optional[List[str]] = None
    isManuallyReviewed: Optional[bool] = None
    matchingConfidence: Optional[str] = None
    sku: Optional[str] = None
    primaryImageUrl: Optional[str] = None


class ProductResponse(ProductCreate):
    """Unified product returned to API consumers."""

    id: str
    createdAt: datetime
    updatedAt: datetime


class StockAdjustmentRequest(BaseModel):
    """Manual stock adjustment with audit metadata."""

    productId: str
    productName: str
    adjustmentType: str  # "increase" | "decrease"
    quantity: int = Field(gt=0)
    oldStock: int
    newStock: int = Field(ge=0)
    reason: str
    notes: str = ""
    adjustmentDate: datetime
