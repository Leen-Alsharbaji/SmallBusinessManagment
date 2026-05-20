from fastapi import APIRouter
from database import users_collection
from datetime import datetime

router = APIRouter()

@router.get("/marketplace/trendyol/{uid}")
def check_trendyol_connection(uid: str):
    """Check if user has Trendyol connected"""
    doc = users_collection.document(uid).get()
    
    if not doc.exists:
        return {"connected": False}
    
    user_data = doc.to_dict()
    marketplaces = user_data.get("marketplaces", [])
    
    for m in marketplaces:
        if m.get("platform") == "trendyol":
            return {
                "connected": True,
                "connected_at": m.get("connected_at")
            }
    
    return {"connected": False}

@router.post("/marketplace/trendyol")
def connect_trendyol(uid: str, seller_id: str, api_password: str):
    """Save Trendyol credentials for the given user."""
    
    marketplace_data = {
        "platform": "trendyol",
        "seller_id": seller_id,
        "api_password": api_password,
        "connected_at": datetime.now().isoformat()
    }
    
    user_ref = users_collection.document(uid)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        user_ref.set({
            "uid": uid,
            "marketplaces": [marketplace_data]
        })
    else:
        user_data = user_doc.to_dict()
        marketplaces = user_data.get("marketplaces", [])
        
        # Remove old Trendyol connection if exists
        marketplaces = [m for m in marketplaces if m.get("platform") != "trendyol"]
        marketplaces.append(marketplace_data)
        
        user_ref.update({"marketplaces": marketplaces})
    
    return {"status": "success", "platform": "trendyol"}
