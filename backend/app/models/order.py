"""Order-related Pydantic schemas for manual and marketplace sales."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ManualOrderCreate(BaseModel):
    """Manual order entry for WhatsApp / Instagram / off-platform sales.

    The service layer atomically decrements stock and writes audit records.
    """

    productId: str
    productName: str
    quantity: int = Field(gt=0)
    salesPrice: float = Field(ge=0)
    currency: str = "TRY"
    platform: str
    notes: str = ""
    saleDate: datetime


class OrderResponse(BaseModel):
    """Persisted order with generated identifiers."""

    id: str
    productId: str
    productName: str
    quantity: int
    salesPrice: float
    currency: str
    platform: str
    notes: str
    saleDate: datetime
    createdAt: datetime
    transactionId: Optional[str] = None
