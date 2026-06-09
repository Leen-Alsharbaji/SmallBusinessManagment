# stock_routes.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from database import products_collection  # only use products_collection

router = APIRouter(prefix="/stock", tags=["stock"])

class StockAdjustment(BaseModel):
    productId: str
    productName: str
    adjustmentType: str  # "increase" or "decrease"
    quantity: int
    oldStock: int
    newStock: int
    reason: str
    notes: str
    adjustmentDate: datetime

@router.post("/adjust")
async def adjust_stock(adjustment: StockAdjustment):
    # Update product stock in unified_products
    product_ref = products_collection.document(adjustment.productId)
    product = product_ref.get()
    if not product.exists:
        raise HTTPException(404, "Product not found")
    
    product_ref.update({
        "totalStock": adjustment.newStock,
        "updatedAt": datetime.utcnow()
    })
    
   
    
    return {"message": "Stock adjusted successfully"}