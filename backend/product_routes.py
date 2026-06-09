# product_routes.py
from fastapi import APIRouter, HTTPException
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
from database import products_collection  

router = APIRouter(prefix="/products", tags=["products"])

class ProductCreate(BaseModel):
    name: str
    brand: str
    category: str
    description: str
    price: float
    totalStock: int
    platforms: List[str]
    isManuallyReviewed: bool = True
    matchingConfidence: str = "high"
    sku: Optional[str] = None
    primaryImageUrl: Optional[str] = None

class ProductResponse(ProductCreate):
    id: str
    createdAt: datetime
    updatedAt: datetime

@router.post("/", response_model=ProductResponse)
async def create_product(product: ProductCreate):
    doc_ref = products_collection.document()
    product_data = product.dict()
    product_data["createdAt"] = datetime.utcnow()
    product_data["updatedAt"] = datetime.utcnow()
    doc_ref.set(product_data)
    return {"id": doc_ref.id, **product_data}

@router.get("/")
async def get_products():
    docs = products_collection.stream()
    products = []
    for doc in docs:
        data = doc.to_dict()
        data["id"] = doc.id
        products.append(data)
    return products

@router.get("/{product_id}")
async def get_product(product_id: str):
    doc = products_collection.document(product_id).get()
    if not doc.exists:
        raise HTTPException(404, "Product not found")
    data = doc.to_dict()
    data["id"] = doc.id
    return data

@router.put("/{product_id}")
async def update_product(product_id: str, product: ProductCreate):
    doc_ref = products_collection.document(product_id)
    if not doc_ref.get().exists:
        raise HTTPException(404, "Product not found")
    update_data = product.dict()
    update_data["updatedAt"] = datetime.utcnow()
    doc_ref.update(update_data)
    return {"message": "updated"}

@router.delete("/{product_id}")
async def delete_product(product_id: str):
    doc_ref = products_collection.document(product_id)
    if not doc_ref.get().exists:
        raise HTTPException(404, "Product not found")
    doc_ref.delete()
    return {"message": "deleted"}

@router.get("/")
async def get_products():
    docs = products_collection.stream()
    products = []
    for doc in docs:
        data = doc.to_dict()
        data["id"] = doc.id
        products.append(data)
    return products  
