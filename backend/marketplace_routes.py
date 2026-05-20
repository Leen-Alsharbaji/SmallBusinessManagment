
from fastapi import APIRouter, HTTPException
from datetime import datetime
import base64
from cryptography.fernet import Fernet
from pydantic import BaseModel

from database import users_collection

router = APIRouter()

class TrendyolCredentials(BaseModel):
    uid: str
    seller_id: str
    api_password: str

# Generate a simple key (for production, store this in environment variable)
# You can generate a key with: Fernet.generate_key()
# Save this key somewhere safe!
SECRET_KEY = b'YOUR_SECRET_KEY_HERE_32_bytes_long_please_change_this_in_production_'

# For first time setup, generate a key
try:
    cipher = Fernet(SECRET_KEY)
except:
    # Generate a new key and print it
    SECRET_KEY = Fernet.generate_key()
    print(f"\n=== IMPORTANT: Save this key ===")
    print(f"SECRET_KEY = {SECRET_KEY}")
    print(f"================================\n")
    cipher = Fernet(SECRET_KEY)

def encrypt_value(value: str) -> str:
    if not value:
        return ""
    return cipher.encrypt(value.encode()).decode()

def decrypt_value(encrypted_value: str) -> str:
    if not encrypted_value:
        return ""
    return cipher.decrypt(encrypted_value.encode()).decode()

@router.post("/marketplace/trendyol")
async def connect_trendyol(creds: TrendyolCredentials):
    """Encrypt and store Trendyol credentials"""
    
    encrypted_seller_id = encrypt_value(creds.seller_id)
    encrypted_password = encrypt_value(creds.api_password)
    
    marketplace_data = {
        "platform": "trendyol",
        "seller_id": encrypted_seller_id,
        "api_password": encrypted_password,
        "connected_at": datetime.now().isoformat(),
        "status": "active"
    }
    
    user_ref = users_collection.document(creds.uid)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        user_ref.set({
            "uid": creds.uid,
            "marketplaces": [marketplace_data],
            "connected_platforms": ["trendyol"],
            "created_at": datetime.now().isoformat()
        })
    else:
        user_data = user_doc.to_dict()
        marketplaces = user_data.get("marketplaces", [])
        marketplaces = [m for m in marketplaces if m.get("platform") != "trendyol"]
        marketplaces.append(marketplace_data)
        
        connected_platforms = user_data.get("connected_platforms", [])
        if "trendyol" not in connected_platforms:
            connected_platforms.append("trendyol")
        
        user_ref.update({
            "marketplaces": marketplaces,
            "connected_platforms": connected_platforms,
            "updated_at": datetime.now().isoformat()
        })
    
    return {
        "status": "success",
        "message": "Trendyol credentials saved and encrypted",
        "platform": "trendyol"
    }

@router.get("/marketplace/trendyol/{uid}")
async def get_trendyol_connection(uid: str):
    user_doc = users_collection.document(uid).get()
    
    if not user_doc.exists:
        return {"connected": False}
    
    user_data = user_doc.to_dict()
    marketplaces = user_data.get("marketplaces", [])
    
    for m in marketplaces:
        if m.get("platform") == "trendyol":
            return {
                "connected": True,
                "connected_at": m.get("connected_at"),
                "status": m.get("status")
            }
    
    return {"connected": False}
