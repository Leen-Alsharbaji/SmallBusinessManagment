from fastapi import APIRouter, HTTPException
from datetime import datetime
import base64
import os
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2
from pydantic import BaseModel
from dotenv import load_dotenv

# Load local .env if present
load_dotenv()

# Fix: Change this to match your database.py location
from database import users_collection


router = APIRouter()

# Create encryption key (temporary in-code secret phrase)
SECRET_PHRASE = os.environ.get('ENCRYPTION_SECRET', "your-secret-phrase-change-this-in-production")
kdf = PBKDF2(
    algorithm=hashes.SHA256(),
    length=32,
    salt=b"smart_inventory_salt",
    iterations=100000,
)
key = base64.urlsafe_b64encode(kdf.derive(SECRET_PHRASE.encode()))
cipher = Fernet(key)

def encrypt_value(value: str) -> str:
    """Encrypt sensitive data"""
    if not value:
        return ""
    return cipher.encrypt(value.encode()).decode()

def decrypt_value(encrypted_value: str) -> str:
    """Decrypt sensitive data"""
    if not encrypted_value:
        return ""
    return cipher.decrypt(encrypted_value.encode()).decode()

@router.get("/user/{uid}")
async def get_user_profile(uid: str):
    """Get user profile info from Firestore"""
    user_doc = users_collection.document(uid).get()
    
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    
    user_data = user_doc.to_dict()
    
    # Return only non-sensitive data
    return {
        "uid": uid,
        "displayName": user_data.get("displayName", ""),
        "email": user_data.get("email", ""),
        "photoURL": user_data.get("photoURL", ""),
        "connected_platforms": user_data.get("connected_platforms", [])
    }

@router.post("/marketplace/trendyol")
async def connect_trendyol(uid: str, seller_id: str, api_password: str):
    """Encrypt and store Trendyol credentials"""
    
    # Encrypt the sensitive data
    encrypted_seller_id = encrypt_value(seller_id)
    encrypted_password = encrypt_value(api_password)
    
    # Prepare marketplace data
    marketplace_data = {
        "platform": "trendyol",
        "seller_id": encrypted_seller_id,
        "api_password": encrypted_password,
        "connected_at": datetime.now(),
        "status": "active"
    }
    
    # Get user document
    user_ref = users_collection.document(uid)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        # Create user document if it doesn't exist
        user_ref.set({
            "uid": uid,
            "marketplaces": [marketplace_data],
            "connected_platforms": ["trendyol"],
            "created_at": datetime.now()
        })
    else:
        # Update existing user
        user_data = user_doc.to_dict()
        marketplaces = user_data.get("marketplaces", [])
        
        # Remove existing Trendyol connection if exists
        marketplaces = [m for m in marketplaces if m.get("platform") != "trendyol"]
        marketplaces.append(marketplace_data)
        
        # Update connected platforms list
        connected_platforms = user_data.get("connected_platforms", [])
        if "trendyol" not in connected_platforms:
            connected_platforms.append("trendyol")
        
        user_ref.update({
            "marketplaces": marketplaces,
            "connected_platforms": connected_platforms,
            "updated_at": datetime.now()
        })
    
    return {
        "status": "success",
        "message": "Trendyol credentials saved and encrypted",
        "platform": "trendyol"
    }

@router.get("/marketplace/trendyol/{uid}")
async def get_trendyol_connection(uid: str):
    """Check if user has Trendyol connected (returns status only, not credentials)"""
    user_doc = users_collection.document(uid).get()
    
    if not user_doc.exists:
        return {"connected": False}
    
    user_data = user_doc.to_dict()
    marketplaces = user_data.get("marketplaces", [])
    
    trendyol_connection = None
    for m in marketplaces:
        if m.get("platform") == "trendyol":
            trendyol_connection = m
            break
    
    if trendyol_connection:
        return {
            "connected": True,
            "connected_at": trendyol_connection.get("connected_at"),
            "status": trendyol_connection.get("status")
        }
    
    return {"connected": False}