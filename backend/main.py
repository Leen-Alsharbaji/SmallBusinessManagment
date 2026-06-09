from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import users_collection
from marketplace_routes import router
from product_routes import router as product_router
from stock_routes import router as stock_router

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include marketplace routes
app.include_router(router, prefix="/api/auth")
app.include_router(product_router, prefix="/api")
app.include_router(stock_router, prefix="/api")
app.include_router(product_router, prefix="/api")
@app.get("/")
def root():
    return {"message": "Smart Inventory Hub API"}

@app.get("/user/{uid}")
def get_user(uid: str):
    doc = users_collection.document(uid).get()
    if not doc.exists:
        return {"error": "User not found"}
    return doc.to_dict()

@app.post("/user/{uid}")
def create_or_update_user(uid: str, display_name: str = None, email: str = None):
    user_data = {
        "uid": uid,
        "displayName": display_name,
        "email": email,
        "marketplaces": []
    }
    users_collection.document(uid).set(user_data, merge=True)
    return {"status": "success", "uid": uid}
