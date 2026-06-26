# Small Business Management Platform - Complete Architectural Documentation

**Project Name:** Smart Inventory Hub API + Small Business Management Platform  
**Version:** 1.0  
**Date:** 2026-06-25  
**Architecture Type:** Microservices-style Distributed System  
**Stack:** Python FastAPI Backend + Flutter/Dart Frontend + Firestore NoSQL Database

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Principles](#architecture-principles)
3. [Backend Architecture](#backend-architecture)
4. [Frontend Architecture](#frontend-architecture)
5. [Data Flow](#data-flow)
6. [Database Schema](#database-schema)
7. [Integration Points](#integration-points)
8. [Security & Encryption](#security--encryption)
9. [API Endpoints Reference](#api-endpoints-reference)
10. [Technology Stack](#technology-stack)

---

## System Overview

### Purpose

This is a **unified inventory management system** designed for small e-commerce businesses to:
- Centralize product inventory across multiple sales channels (Trendyol, WhatsApp, Instagram, etc.)
- Track stock levels in real-time with audit logging
- Record manual sales from social media platforms
- Integrate with marketplace platforms (Trendyol) for product synchronization
- Apply NLP-based title unification to match marketplace listings with a unified catalog

### Core Domains

```
┌─────────────────────────────────────────────────────────────────┐
│                    Small Business Owner                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼──────────────┐
                │             │              │
                ▼             ▼              ▼
        ┌──────────────┐  ┌──────────┐  ┌─────────────┐
        │   Web UI     │  │ Mobile   │  │  Marketplace│
        │  (Flutter)   │  │ Flutter  │  │(Trendyol)   │
        └──────┬───────┘  └────┬─────┘  └─────┬───────┘
               │               │              │
               └───────────────┼──────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  FastAPI Backend    │
                    │  (Python)           │
                    │  Port 8000          │
                    └──────────┬──────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
    │   Firebase   │    │  Firestore   │    │  Trendyol    │
    │   Auth       │    │   Database   │    │  Mock API    │
    │              │    │              │    │  (Postman)   │
    └──────────────┘    └──────────────┘    └──────────────┘
```

### Key Features

| Feature | Purpose | Technology |
|---------|---------|-----------|
| **Unified Inventory** | Single source of truth for all products across channels | Firestore NoSQL |
| **Stock Tracking** | Real-time stock level updates with transaction audit trail | Firestore Transactions |
| **Manual Sales Recording** | Log WhatsApp/Instagram sales atomically (with stock deduction) | FastAPI + Firestore Tx |
| **Marketplace Integration** | Pull products from Trendyol and unify with catalog | TrendyolMockClient + NLP |
| **Title Unification (NLP)** | Automatic matching of marketplace titles to catalog using TF-IDF | scikit-learn |
| **Multi-Platform Support** | iOS, Android, and Web via Flutter | Flutter Cross-Platform |
| **User Authentication** | Email-based auth with Firebase | Firebase Auth |
| **Encrypted Credentials** | Secure storage of marketplace API credentials | Fernet Symmetric Encryption |

---

## Architecture Principles

### Design Patterns Used

| Pattern | Usage | Benefit |
|---------|-------|---------|
| **Repository Pattern** | Data access abstraction (ProductRepository, OrderRepository, etc.) | Decouples business logic from data source |
| **Dependency Injection** | Service injection via FastAPI dependencies | Loose coupling, easy testing |
| **Service Layer** | Business logic encapsulation (ProductService, OrderService, etc.) | Single responsibility, reusability |
| **Atomic Transactions** | Firestore transactions for order creation | Consistency (stock doesn't get over-sold) |
| **NLP Pipeline** | Text normalization → TF-IDF → Cosine Similarity | Robust title matching despite misspellings |
| **Provider Pattern (Flutter)** | State management with ChangeNotifier | Reactive UI updates |
| **Error Handling** | Custom exception hierarchy with typed error codes | Graceful error propagation to frontend |
| **Encryption at Rest** | Fernet symmetric encryption for marketplace credentials | Security compliance for API keys |

### Design Rationale

1. **Why Firestore?**
   - Serverless, scales automatically
   - Built-in authentication/authorization
   - Real-time updates via listeners
   - No infrastructure to manage
   - Ideal for MVP/SMB business model

2. **Why FastAPI?**
   - High performance (async/await native)
   - Auto-generated OpenAPI docs
   - Type-safe with Pydantic validation
   - Excellent for rapid development

3. **Why Flutter?**
   - Single codebase for iOS/Android/Web
   - Hot reload for quick iteration
   - Strong typing with Dart
   - Excellent performance

4. **Why Atomic Transactions for Orders?**
   - Prevents race conditions on stock levels
   - "Over-selling" is impossible even with concurrent orders
   - Audit trail is guaranteed consistent
   - Exactly-once order semantics

5. **Why NLP for Title Matching?**
   - Marketplace titles often differ from internal catalog names
   - Handles typos, variations, abbreviations
   - Configurable similarity threshold (default 0.8 = 80%)
   - No manual mapping required

---

## Backend Architecture

### High-Level Structure

```
backend/
├── main.py                          # Uvicorn entry point
├── requirements.txt                 # Python dependencies
└── app/
    ├── main.py                      # FastAPI app factory (create_app)
    ├── config.py                    # Environment settings
    ├── dependencies.py              # Dependency injection
    ├── exceptions.py                # Custom exception classes
    │
    ├── db/
    │   ├── __init__.py
    │   └── firestore_client.py      # Firebase/Firestore initialization
    │
    ├── models/                      # Pydantic data models
    │   ├── auth.py                  # TrendyolCredentials, TrendyolConnectionStatus
    │   ├── order.py                 # ManualOrderCreate, OrderResponse
    │   ├── product.py               # ProductCreate, ProductResponse, StockAdjustmentRequest
    │   └── sync.py                  # TitleMatchRequest, SyncRawProductRequest
    │
    ├── repositories/                # Data access layer
    │   ├── order_repository.py      # OrderRepository, StockTransactionRepository
    │   ├── product_repository.py    # ProductRepository
    │   └── user_repository.py       # UserRepository
    │
    ├── routers/                     # API endpoints
    │   ├── auth.py                  # /api/auth/* - Marketplace connections
    │   ├── inventory.py             # /api/inventory/* - Product CRUD & stock adjustment
    │   ├── orders.py                # /api/orders/* - Manual order recording
    │   ├── sync.py                  # /api/sync/* - NLP matching & product ingestion
    │   └── legacy.py                # /api/* - Backward compatibility
    │
    ├── services/                    # Business logic layer
    │   ├── marketplace_service.py   # Trendyol credential management
    │   ├── order_service.py         # Order creation with atomic transactions
    │   ├── product_service.py       # Product management
    │   ├── stock_service.py         # Stock adjustment & auditing
    │   ├── sync_service.py          # Marketplace product ingestion
    │   └── nlp/                     # NLP services
    │       ├── title_unification_service.py  # TF-IDF + Cosine Similarity matching
    │       └── text_utils.py                 # Turkish text normalization
    │
    └── integrations/                # External service integrations
        └── trendyol/
            ├── client.py            # TrendyolMockClient (HTTP wrapper)
            └── models.py            # TrendyolProduct, TrendyolOrder
```

### Request Flow Pattern

```
HTTP Request
    ↓
Router (e.g., /api/orders/manual)
    ↓
Dependency Injection (get_order_service, get_product_service)
    ↓
Service Layer (OrderService, ProductService)
    ├─ Business logic
    ├─ Validation
    └─ Transaction management
    ↓
Repository Layer (OrderRepository, ProductRepository)
    ├─ Firestore access
    └─ Query building
    ↓
Database (Firestore)
    ├─ Collections (unified_products, orders, stock_transactions)
    └─ Transactions (atomic multi-document updates)
    ↓
Response
    ├─ Success: Return model instance (auto JSON serialized)
    └─ Error: Custom exception (caught by global handler)
```

---

### Detailed Component Descriptions

#### **FastAPI App Factory** - [app/main.py](backend/app/main.py)

**Responsibility:** Initialize and configure the FastAPI application

```python
def create_app() -> FastAPI:
    app = FastAPI()
    
    # CORS Configuration
    app.add_middleware(
        CORSMiddleware,
        allow_origins="*",  # From config
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"]
    )
    
    # Root endpoint
    @app.get("/")
    async def root():
        return {"message": "Smart Inventory Hub API"}
    
    # Include routers with /api prefix
    app.include_router(auth.router, prefix="/api")
    app.include_router(inventory.router, prefix="/api")
    app.include_router(orders.router, prefix="/api")
    app.include_router(sync.router, prefix="/api")
    app.include_router(legacy.router, prefix="/api")
    
    # Global exception handlers
    @app.exception_handler(AppError)
    async def app_exception_handler(request, exc):
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"message": exc.message, "code": exc.code}}
        )
    
    return app
```

**Startup:**
```bash
uvicorn backend.app.main:create_app --reload --port 8000
```

---

#### **Configuration Management** - [app/config.py](backend/app/config.py)

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App
    app_name: str = "Smart Inventory Hub API"
    cors_origins: str = "*"
    firebase_credentials_path: str = "service-account.json"
    
    # Firestore Collections (configurable for multi-tenancy)
    users_collection: str = "Users"
    products_collection: str = "unified_products"
    orders_collection: str = "orders"
    stock_transactions_collection: str = "stock_transactions"
    raw_products_collection: str = "raw_products"
    
    # Trendyol Integration
    trendyol_mock_base_url: str = "https://your-postman-mock-url"
    trendyol_api_user_agent: str = "SmartInventoryHub/1.0"
    
    # NLP
    nlp_similarity_threshold: float = 0.8  # 80% match required
    
    # Encryption
    encryption_secret: str  # Fernet key
    
    class Config:
        env_file = ".env"
        case_sensitive = False
```

**Environment Variables:**
```bash
FIREBASE_CREDENTIALS_PATH=service-account.json
TRENDYOL_MOCK_BASE_URL=https://...
ENCRYPTION_SECRET=<fernet-key>
NLP_SIMILARITY_THRESHOLD=0.8
```

---

#### **Dependency Injection** - [app/dependencies.py](backend/app/dependencies.py)

```python
from fastapi import Depends

# Lazy singletons
_product_service = None
_order_service = None
_marketplace_service = None
_sync_service = None

async def get_product_service() -> ProductService:
    global _product_service
    if _product_service is None:
        _product_service = ProductService(ProductRepository())
    return _product_service

async def get_order_service() -> OrderService:
    global _order_service
    if _order_service is None:
        _order_service = OrderService(
            OrderRepository(),
            ProductRepository(),
            StockTransactionRepository()
        )
    return _order_service

async def get_marketplace_service() -> MarketplaceService:
    global _marketplace_service
    if _marketplace_service is None:
        _marketplace_service = MarketplaceService(UserRepository())
    return _marketplace_service

async def get_sync_service() -> SyncService:
    global _sync_service
    if _sync_service is None:
        _sync_service = SyncService(
            TitleUnificationService(),
            ProductRepository(),
            RawProductRepository()
        )
    return _sync_service
```

**Usage in Router:**
```python
@router.post("/orders/manual")
async def create_manual_order(
    payload: ManualOrderCreate,
    order_service: OrderService = Depends(get_order_service)
):
    return await order_service.create_manual_order(payload)
```

---

#### **Custom Exception Hierarchy** - [app/exceptions.py](backend/app/exceptions.py)

```python
class AppError(Exception):
    def __init__(self, message: str, code: str, status_code: int = 400, details: Any = None):
        self.message = message
        self.code = code
        self.status_code = status_code
        self.details = details
        super().__init__(self.message)

class NotFoundError(AppError):
    def __init__(self, message: str = "Resource not found", details: Any = None):
        super().__init__(message, "not_found", 404, details)

class InsufficientStockError(AppError):
    def __init__(self, available: int, requested: int):
        message = f"Insufficient stock. Available: {available}, Requested: {requested}"
        super().__init__(message, "insufficient_stock", 409, {
            "available": available,
            "requested": requested
        })

class ExternalServiceError(AppError):
    def __init__(self, service: str, message: str):
        super().__init__(
            f"External service error from {service}: {message}",
            "external_service_error",
            502
        )
```

**Error Response Format:**
```json
{
  "error": {
    "message": "Insufficient stock. Available: 5, Requested: 10",
    "code": "insufficient_stock",
    "details": {"available": 5, "requested": 10}
  }
}
```

---

### Data Models (Pydantic)

#### **Product Models** - [app/models/product.py](backend/app/models/product.py)

```python
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class ProductCreate(BaseModel):
    """Request body for creating a product"""
    name: str = Field(..., min_length=1, max_length=255)
    brand: str = Field(..., min_length=1, max_length=100)
    category: str = Field(..., min_length=1, max_length=100)
    description: str = Field(default="")
    price: float = Field(..., gt=0)
    totalStock: int = Field(..., ge=0)
    platforms: List[str] = Field(default_factory=list)
    sku: Optional[str] = None
    primaryImageUrl: Optional[str] = None
    isManuallyReviewed: bool = True
    matchingConfidence: str = "high"

class ProductResponse(ProductCreate):
    """Response model for product operations"""
    id: str
    createdAt: datetime
    updatedAt: datetime
    
    class Config:
        from_attributes = True

class StockAdjustmentRequest(BaseModel):
    """Request body for stock adjustment"""
    productId: str
    productName: str
    adjustmentType: str = Field(..., pattern="^(increase|decrease)$")
    quantity: int = Field(..., gt=0)
    oldStock: int = Field(..., ge=0)
    newStock: int = Field(..., ge=0)
    reason: str
    notes: Optional[str] = None
    adjustmentDate: datetime
```

#### **Order Models** - [app/models/order.py](backend/app/models/order.py)

```python
class ManualOrderCreate(BaseModel):
    """Request body for recording manual sales"""
    productId: str
    productName: str
    quantity: int = Field(..., gt=0)
    salesPrice: float = Field(..., ge=0)
    currency: str = "TRY"
    platform: str = Field(..., pattern="^(WhatsApp|Instagram|Trendyol|Hepsiburada|Other)$")
    notes: Optional[str] = None
    saleDate: datetime

class OrderResponse(BaseModel):
    """Response model for orders"""
    id: str
    productId: str
    productName: str
    quantity: int
    salesPrice: float
    currency: str
    platform: str
    notes: Optional[str]
    saleDate: datetime
    createdAt: datetime
    transactionId: Optional[str] = None
    
    class Config:
        from_attributes = True
```

#### **Authentication Models** - [app/models/auth.py](backend/app/models/auth.py)

```python
class TrendyolCredentials(BaseModel):
    """Marketplace connection credentials"""
    uid: str  # Firebase UID
    seller_id: str
    api_password: str

class TrendyolConnectionStatus(BaseModel):
    """Status of marketplace connection"""
    connected: bool
    connected_at: Optional[str]
    status: Optional[str] = "active"
```

---

### Services Layer - Business Logic

#### **ProductService** - [app/services/product_service.py](backend/app/services/product_service.py)

```python
class ProductService:
    def __init__(self, repo: ProductRepository):
        self.repo = repo
    
    async def list_products(self) -> List[dict]:
        """Get all products from unified catalog"""
        return self.repo.list_all()
    
    async def get_product(self, product_id: str) -> dict:
        """Get single product by ID"""
        product = self.repo.get_by_id(product_id)
        if not product:
            raise NotFoundError(f"Product {product_id} not found")
        return product
    
    async def create_product(self, payload: ProductCreate) -> dict:
        """Create new product in unified catalog"""
        product_dict = payload.dict()
        product_dict["createdAt"] = datetime.utcnow()
        product_dict["updatedAt"] = datetime.utcnow()
        return self.repo.create(product_dict)
    
    async def update_product(self, product_id: str, payload: ProductCreate) -> dict:
        """Update existing product"""
        product = await self.get_product(product_id)  # Verify exists
        update_data = payload.dict(exclude_unset=True)
        update_data["updatedAt"] = datetime.utcnow()
        self.repo.update(product_id, update_data)
        return self.repo.get_by_id(product_id)
    
    async def delete_product(self, product_id: str) -> None:
        """Delete product from catalog"""
        await self.get_product(product_id)  # Verify exists
        self.repo.delete(product_id)
    
    async def list_titles(self) -> List[str]:
        """Get all product titles for NLP matching"""
        products = self.repo.list_all()
        return [p["name"] for p in products]
```

#### **OrderService** - [app/services/order_service.py](backend/app/services/order_service.py)

**Key Feature:** Atomic transactions ensure stock consistency

```python
class OrderService:
    def __init__(
        self,
        order_repo: OrderRepository,
        product_repo: ProductRepository,
        stock_tx_repo: StockTransactionRepository
    ):
        self.order_repo = order_repo
        self.product_repo = product_repo
        self.stock_tx_repo = stock_tx_repo
    
    async def create_manual_order(self, payload: ManualOrderCreate) -> OrderResponse:
        """
        Create manual order with atomic stock deduction.
        
        Transaction Semantics:
        1. Read current product stock in transaction
        2. Validate sufficient stock exists
        3. Decrement product totalStock
        4. Write new order document
        5. Write stock_transactions audit record
        
        All-or-nothing: If any step fails, entire transaction rolls back.
        """
        db = get_firestore_client()
        transaction = db.transaction()
        
        @transaction.transactional
        def _execute_order_transaction(tx):
            # Step 1: Read product
            product_snap = self.product_repo.get_snapshot_in_transaction(
                tx, payload.productId
            )
            if not product_snap.exists:
                raise NotFoundError(f"Product {payload.productId} not found")
            
            product = product_snap.to_dict()
            current_stock = product.get("totalStock", 0)
            
            # Step 2: Validate stock
            if current_stock < payload.quantity:
                raise InsufficientStockError(
                    available=current_stock,
                    requested=payload.quantity
                )
            
            # Step 3: Decrement stock
            new_stock = current_stock - payload.quantity
            self.product_repo.collection.document(
                payload.productId
            ).update(
                {"totalStock": new_stock, "updatedAt": datetime.utcnow()},
                transaction=tx
            )
            
            # Step 4: Create order
            order_data = payload.dict()
            order_data["createdAt"] = datetime.utcnow()
            order_id = self.order_repo.create_in_transaction(tx, order_data)
            
            # Step 5: Create audit record
            stock_tx_data = {
                "type": "manual_sale",
                "productId": payload.productId,
                "productName": payload.productName,
                "quantityDelta": -payload.quantity,
                "oldStock": current_stock,
                "newStock": new_stock,
                "orderId": order_id,
                "createdAt": datetime.utcnow()
            }
            self.stock_tx_repo.create_in_transaction(tx, stock_tx_data)
            
            return order_id
        
        order_id = _execute_order_transaction(transaction)
        order = self.order_repo.get_by_id(order_id)
        return OrderResponse(**order)
    
    async def list_orders(self) -> List[OrderResponse]:
        """Get all orders, most recent first"""
        orders = self.order_repo.list_all()
        return [OrderResponse(**order) for order in orders]
```

**Why Transactions Are Critical:**

Without transactions (race condition):
```
Order 1 reads stock: 5
Order 2 reads stock: 5
Order 1 requests 4 units → allowed, decrements to 1
Order 2 requests 4 units → allowed, decrements to -3 (INVALID!)
```

With transactions (atomic):
```
Order 1 locks product → reads stock: 5 → decrements to 1 → unlocks
Order 2 waits for lock → reads stock: 1 → can't decrement by 4 → fails
Result: Both orders are either fully processed or fully rejected
```

#### **StockService** - [app/services/stock_service.py](backend/app/services/stock_service.py)

```python
class StockService:
    def __init__(self, product_repo: ProductRepository, stock_tx_repo: StockTransactionRepository):
        self.product_repo = product_repo
        self.stock_tx_repo = stock_tx_repo
    
    async def adjust_stock(self, adjustment: StockAdjustmentRequest) -> dict:
        """
        Adjust stock manually with audit trail.
        
        Creates immutable stock_transactions record for audit compliance.
        """
        # Verify product exists
        product = self.product_repo.get_by_id(adjustment.productId)
        if not product:
            raise NotFoundError(f"Product {adjustment.productId} not found")
        
        # Update product
        self.product_repo.update(
            adjustment.productId,
            {"totalStock": adjustment.newStock, "updatedAt": datetime.utcnow()}
        )
        
        # Create audit record
        tx_data = {
            "type": "adjustment",
            "productId": adjustment.productId,
            "productName": adjustment.productName,
            "quantityDelta": adjustment.newStock - adjustment.oldStock,
            "oldStock": adjustment.oldStock,
            "newStock": adjustment.newStock,
            "adjustmentType": adjustment.adjustmentType,
            "reason": adjustment.reason,
            "notes": adjustment.notes,
            "adjustmentDate": adjustment.adjustmentDate,
            "createdAt": datetime.utcnow()
        }
        self.stock_tx_repo.create(tx_data)
        
        return {"productId": adjustment.productId, "newStock": adjustment.newStock}
```

#### **MarketplaceService** - [app/services/marketplace_service.py](backend/app/services/marketplace_service.py)

```python
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2
import hashlib
import base64

class MarketplaceService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo
        self.trendyol_client = TrendyolMockClient()
    
    def _derive_encryption_key(self, salt: str) -> bytes:
        """
        Derive Fernet-compatible encryption key using PBKDF2.
        
        Algorithm: PBKDF2-HMAC-SHA256
        Iterations: 100,000
        """
        kdf = PBKDF2(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt.encode(),
            iterations=100000
        )
        key = base64.urlsafe_b64encode(kdf.derive(settings.encryption_secret.encode()))
        return key
    
    async def connect_trendyol(self, creds: TrendyolCredentials) -> dict:
        """
        Store Trendyol credentials with encryption.
        
        Storage:
        - seller_id: Plain text (can be public)
        - api_password: Encrypted with Fernet
        - connected_at: Timestamp
        - status: "active"
        """
        encryption_key = self._derive_encryption_key("smart_inventory_hub_salt")
        cipher = Fernet(encryption_key)
        
        encrypted_password = cipher.encrypt(creds.api_password.encode()).decode()
        
        marketplace_entry = {
            "platform": "trendyol",
            "seller_id": creds.seller_id,
            "api_password": encrypted_password,
            "connected_at": datetime.utcnow().isoformat(),
            "status": "active"
        }
        
        self.user_repo.save_marketplace_credentials(creds.uid, marketplace_entry)
        
        return {"status": "connected", "platform": "trendyol"}
    
    async def get_trendyol_status(self, uid: str) -> TrendyolConnectionStatus:
        """Get connection status of Trendyol account"""
        user = self.user_repo.get(uid)
        if not user:
            return TrendyolConnectionStatus(connected=False)
        
        trendyol_creds = user.get("marketplaces", {}).get("trendyol")
        if not trendyol_creds:
            return TrendyolConnectionStatus(connected=False)
        
        return TrendyolConnectionStatus(
            connected=True,
            connected_at=trendyol_creds.get("connected_at"),
            status=trendyol_creds.get("status", "active")
        )
    
    async def fetch_trendyol_products(self, uid: str) -> List[dict]:
        """
        Proxy fetch products from Trendyol.
        
        Retrieves stored credentials, decrypts password, and calls TrendyolMockClient.
        """
        user = self.user_repo.get(uid)
        if not user:
            raise NotFoundError(f"User {uid} not found")
        
        trendyol_creds = user.get("marketplaces", {}).get("trendyol")
        if not trendyol_creds:
            raise AppError("Trendyol not connected", "trendyol_not_connected", 400)
        
        # Decrypt password
        encryption_key = self._derive_encryption_key("smart_inventory_hub_salt")
        cipher = Fernet(encryption_key)
        try:
            api_password = cipher.decrypt(
                trendyol_creds["api_password"].encode()
            ).decode()
        except Exception as e:
            raise AppError("Failed to decrypt credentials", "decrypt_error", 500)
        
        # Fetch from Trendyol
        try:
            products = await self.trendyol_client.get_products(
                seller_id=trendyol_creds["seller_id"],
                api_password=api_password
            )
            return products
        except Exception as e:
            raise ExternalServiceError("Trendyol", str(e))
```

#### **SyncService** - [app/services/sync_service.py](backend/app/services/sync_service.py)

```python
class SyncService:
    def __init__(
        self,
        nlp_service: TitleUnificationService,
        product_repo: ProductRepository,
        raw_product_repo: RawProductRepository
    ):
        self.nlp_service = nlp_service
        self.product_repo = product_repo
        self.raw_product_repo = raw_product_repo
    
    async def match_title(self, request: TitleMatchRequest) -> TitleMatchResult:
        """
        Find best matching title from catalog using NLP.
        
        Returns confidence score for user review before unification.
        """
        best_title, similarity = self.nlp_service.find_best_match(
            request.raw_title,
            request.candidate_titles
        )
        
        return TitleMatchResult(
            matched=similarity >= settings.nlp_similarity_threshold,
            best_title=best_title,
            similarity=similarity,
            threshold=settings.nlp_similarity_threshold
        )
    
    async def ingest_raw_product(self, payload: SyncRawProductRequest) -> dict:
        """
        Ingest marketplace listing and attempt automatic title matching.
        
        Workflow:
        1. Fetch all catalog titles
        2. Find best NLP match
        3. If high confidence, auto-unify
        4. Create raw_products audit record
        5. Return match results
        """
        # Step 1: Get catalog titles
        catalog_titles = self.product_repo.get_all_titles()
        
        # Step 2: Find best match
        best_title, similarity = self.nlp_service.find_best_match(
            payload.raw_title,
            catalog_titles
        )
        
        # Step 3: Store raw product record
        raw_product_data = {
            "platform": payload.platform,
            "raw_title": payload.raw_title,
            "external_id": payload.external_id,
            "price": payload.price,
            "stock": payload.stock,
            "matched": similarity >= settings.nlp_similarity_threshold,
            "matchedTitle": best_title if similarity >= settings.nlp_similarity_threshold else None,
            "similarity": similarity,
            "ingestedAt": datetime.utcnow()
        }
        
        raw_product_id = self.raw_product_repo.create(raw_product_data)
        
        return {
            "id": raw_product_id,
            "matched": raw_product_data["matched"],
            "similarity": similarity,
            "matchedTitle": best_title,
            "status": "awaiting_review" if not raw_product_data["matched"] else "auto_matched"
        }
```

#### **TitleUnificationService (NLP)** - [app/services/nlp/title_unification_service.py](backend/app/services/nlp/title_unification_service.py)

**Algorithm:** TF-IDF + Cosine Similarity

```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

class TitleUnificationService:
    def __init__(self, threshold: float = 0.8):
        self.threshold = threshold
        self.vectorizer = TfidfVectorizer(
            analyzer='char',  # Character-level n-grams (handles typos)
            ngram_range=(2, 3),  # Bigrams and trigrams
            lowercase=True
        )
    
    def find_best_match(
        self,
        raw_title: str,
        candidate_titles: List[str]
    ) -> Tuple[Optional[str], float]:
        """
        Find best matching title from candidates using TF-IDF + Cosine Similarity.
        
        Process:
        1. Normalize Turkish text (remove diacritics, lowercase, strip punctuation)
        2. Compute TF-IDF vectors for normalized text
        3. Calculate cosine similarity between raw and each candidate
        4. Return best match if similarity >= threshold
        
        Example:
            raw_title = "iPhone 15 Pro Max - 256GB"
            candidates = ["iPhone 15 Pro Max 256GB", "iPhone 15 256GB", "Samsung Galaxy"]
            
            Normalized:
            - "iphone 15 pro max 256gb" → similarity 0.95 ✓ (matched)
            - "iphone 15 256gb" → similarity 0.87 ✓ (matched)
            - "samsung galaxy" → similarity 0.05 ✗ (no match)
            
            Result: ("iPhone 15 Pro Max 256GB", 0.95)
        """
        # Normalize all text
        normalized_raw = self._normalize_text(raw_title)
        normalized_candidates = [self._normalize_text(t) for t in candidate_titles]
        
        # Build TF-IDF vectors
        all_texts = [normalized_raw] + normalized_candidates
        try:
            tfidf_matrix = self.vectorizer.fit_transform(all_texts)
        except ValueError:
            # Handle empty or invalid input
            return None, 0.0
        
        # Calculate cosine similarities
        raw_vector = tfidf_matrix[0:1]
        candidate_vectors = tfidf_matrix[1:]
        
        if candidate_vectors.shape[0] == 0:
            return None, 0.0
        
        similarities = cosine_similarity(raw_vector, candidate_vectors)[0]
        
        # Find best match
        best_idx = np.argmax(similarities)
        best_similarity = float(similarities[best_idx])
        
        if best_similarity >= self.threshold:
            return candidate_titles[best_idx], best_similarity
        
        return None, best_similarity
    
    def _normalize_text(self, text: str) -> str:
        """
        Normalize text for comparison.
        
        Steps:
        1. Unicode NFKD decomposition (é → e)
        2. Strip accents
        3. Lowercase
        4. Remove punctuation and special chars
        5. Collapse whitespace
        """
        import unicodedata
        import re
        
        # NFKD decomposition (handles Turkish characters)
        text = unicodedata.normalize('NFKD', text)
        
        # Remove accents
        text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
        
        # Lowercase
        text = text.lower()
        
        # Remove punctuation
        text = re.sub(r'[^\w\s]', '', text)
        
        # Collapse whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text
```

**Example Matching:**

```
Raw Marketplace Title: "iPhone 15 PRO max 256gb"
Catalog Titles:
  - "iPhone 15 Pro Max 256GB"        → Similarity: 0.98 ✓ MATCH
  - "iPhone 15 Pro 128GB"            → Similarity: 0.87 ✓ MATCH
  - "Samsung Galaxy S24 Ultra"       → Similarity: 0.05 ✗ NO MATCH

Result: Match confidence 98%, matched title "iPhone 15 Pro Max 256GB"
```

---

### Repositories - Data Access Layer

#### **ProductRepository** - [app/repositories/product_repository.py](backend/app/repositories/product_repository.py)

```python
class ProductRepository:
    def __init__(self):
        self.db = get_firestore_client()
        self.collection = self.db.collection(settings.products_collection)
    
    def list_all(self) -> List[dict]:
        """Get all products, ordered by creation time"""
        docs = self.collection.order_by("createdAt", direction="DESCENDING").stream()
        return [{"id": doc.id, **doc.to_dict()} for doc in docs]
    
    def get_by_id(self, product_id: str) -> Optional[dict]:
        """Get single product"""
        doc = self.collection.document(product_id).get()
        if doc.exists:
            return {"id": doc.id, **doc.to_dict()}
        return None
    
    def create(self, data: dict) -> dict:
        """Create new product, returns with ID"""
        doc_ref = self.collection.document()
        doc_ref.set(data)
        return {"id": doc_ref.id, **data}
    
    def update(self, product_id: str, data: dict) -> None:
        """Update existing product"""
        self.collection.document(product_id).update(data)
    
    def delete(self, product_id: str) -> None:
        """Delete product"""
        self.collection.document(product_id).delete()
    
    def get_snapshot_in_transaction(
        self,
        transaction: Transaction,
        product_id: str
    ) -> DocumentSnapshot:
        """
        Get product snapshot within Firestore transaction.
        Used for atomic reads in OrderService.
        """
        return transaction.get(self.collection.document(product_id))
    
    def get_all_titles(self) -> List[str]:
        """Get all product titles for NLP matching"""
        products = self.list_all()
        return [p["name"] for p in products]
```

#### **OrderRepository** - [app/repositories/order_repository.py](backend/app/repositories/order_repository.py)

```python
class OrderRepository:
    def __init__(self):
        self.db = get_firestore_client()
        self.collection = self.db.collection(settings.orders_collection)
    
    def create_in_transaction(self, transaction: Transaction, data: dict) -> str:
        """
        Create order within transaction.
        Returns document ID for reference.
        """
        doc_ref = self.collection.document()
        transaction.set(doc_ref, data)
        return doc_ref.id
    
    def list_all(self) -> List[dict]:
        """Get all orders, most recent first"""
        docs = self.collection.order_by(
            "createdAt",
            direction="DESCENDING"
        ).stream()
        return [{"id": doc.id, **doc.to_dict()} for doc in docs]
    
    def get_by_id(self, order_id: str) -> Optional[dict]:
        """Get single order"""
        doc = self.collection.document(order_id).get()
        if doc.exists:
            return {"id": doc.id, **doc.to_dict()}
        return None


class StockTransactionRepository:
    """Audit trail for all stock movements"""
    
    def __init__(self):
        self.db = get_firestore_client()
        self.collection = self.db.collection(settings.stock_transactions_collection)
    
    def create_in_transaction(self, transaction: Transaction, data: dict) -> str:
        """Create audit record within transaction"""
        doc_ref = self.collection.document()
        transaction.set(doc_ref, data)
        return doc_ref.id
    
    def create(self, data: dict) -> str:
        """Create audit record outside transaction"""
        doc_ref = self.collection.document()
        doc_ref.set(data)
        return doc_ref.id
    
    def list_all_for_product(self, product_id: str) -> List[dict]:
        """Get all transactions for a product"""
        docs = self.collection.where(
            "productId", "==", product_id
        ).order_by("createdAt", direction="DESCENDING").stream()
        return [{"id": doc.id, **doc.to_dict()} for doc in docs]
```

#### **UserRepository** - [app/repositories/user_repository.py](backend/app/repositories/user_repository.py)

```python
class UserRepository:
    def __init__(self):
        self.db = get_firestore_client()
        self.collection = self.db.collection(settings.users_collection)
    
    def get(self, uid: str) -> Optional[dict]:
        """Get user profile"""
        doc = self.collection.document(uid).get()
        if doc.exists:
            return doc.to_dict()
        return None
    
    def upsert(self, uid: str, data: dict) -> None:
        """Create or update user"""
        self.collection.document(uid).set(data, merge=True)
    
    def save_marketplace_credentials(self, uid: str, marketplace_entry: dict) -> None:
        """Add or update marketplace credentials"""
        user = self.get(uid) or {}
        marketplaces = user.get("marketplaces", {})
        marketplaces[marketplace_entry["platform"]] = marketplace_entry
        
        connected_platforms = list(marketplaces.keys())
        
        self.upsert(uid, {
            "marketplaces": marketplaces,
            "connected_platforms": connected_platforms,
            "updated_at": datetime.utcnow()
        })
    
    def get_trendyol_marketplace(self, uid: str) -> Optional[dict]:
        """Get Trendyol credentials for user"""
        user = self.get(uid)
        if user:
            return user.get("marketplaces", {}).get("trendyol")
        return None
```

---

### API Routers

#### **Auth Router** - [app/routers/auth.py](backend/app/routers/auth.py)

```python
from fastapi import APIRouter, Depends
from app.models.auth import TrendyolCredentials, TrendyolConnectionStatus
from app.services import MarketplaceService
from app.dependencies import get_marketplace_service

router = APIRouter(tags=["auth"])

@router.post("/api/auth/marketplace/trendyol", response_model=dict)
async def connect_trendyol(
    creds: TrendyolCredentials,
    service: MarketplaceService = Depends(get_marketplace_service)
):
    """Connect Trendyol marketplace account with encrypted credential storage"""
    return await service.connect_trendyol(creds)

@router.get("/api/auth/marketplace/trendyol/{uid}", response_model=TrendyolConnectionStatus)
async def get_trendyol_status(
    uid: str,
    service: MarketplaceService = Depends(get_marketplace_service)
):
    """Get Trendyol connection status"""
    return await service.get_trendyol_status(uid)

@router.get("/api/auth/marketplace/trendyol/{uid}/products")
async def get_trendyol_products(
    uid: str,
    service: MarketplaceService = Depends(get_marketplace_service)
):
    """Proxy fetch Trendyol products"""
    return await service.fetch_trendyol_products(uid)

@router.get("/api/auth/marketplace/trendyol/{uid}/orders")
async def get_trendyol_orders(
    uid: str,
    service: MarketplaceService = Depends(get_marketplace_service)
):
    """Proxy fetch Trendyol orders"""
    return await service.fetch_trendyol_orders(uid)
```

#### **Inventory Router** - [app/routers/inventory.py](backend/app/routers/inventory.py)

```python
from fastapi import APIRouter, Depends
from app.models.product import ProductCreate, ProductResponse, StockAdjustmentRequest
from app.services import ProductService, StockService
from app.dependencies import get_product_service, get_stock_service

router = APIRouter(prefix="/inventory", tags=["inventory"])

@router.get("/products", response_model=List[ProductResponse])
async def list_products(
    service: ProductService = Depends(get_product_service)
):
    """Get all products from unified catalog"""
    return await service.list_products()

@router.post("/products", response_model=ProductResponse, status_code=201)
async def create_product(
    payload: ProductCreate,
    service: ProductService = Depends(get_product_service)
):
    """Create new product"""
    return await service.create_product(payload)

@router.get("/products/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: str,
    service: ProductService = Depends(get_product_service)
):
    """Get single product"""
    return await service.get_product(product_id)

@router.put("/products/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: str,
    payload: ProductCreate,
    service: ProductService = Depends(get_product_service)
):
    """Update product"""
    return await service.update_product(product_id, payload)

@router.delete("/products/{product_id}", status_code=204)
async def delete_product(
    product_id: str,
    service: ProductService = Depends(get_product_service)
):
    """Delete product"""
    await service.delete_product(product_id)

@router.post("/stock/adjust", response_model=dict)
async def adjust_stock(
    adjustment: StockAdjustmentRequest,
    service: StockService = Depends(get_stock_service)
):
    """Adjust stock with audit trail"""
    return await service.adjust_stock(adjustment)
```

#### **Orders Router** - [app/routers/orders.py](backend/app/routers/orders.py)

```python
from fastapi import APIRouter, Depends
from app.models.order import ManualOrderCreate, OrderResponse
from app.services import OrderService
from app.dependencies import get_order_service

router = APIRouter(prefix="/orders", tags=["orders"])

@router.post("/manual", response_model=OrderResponse, status_code=201)
async def create_manual_order(
    payload: ManualOrderCreate,
    service: OrderService = Depends(get_order_service)
):
    """
    Record manual WhatsApp/Instagram sale with atomic stock deduction.
    
    Transaction guarantees:
    - Stock is checked and decremented atomically
    - Order and audit record are created in same transaction
    - No over-selling is possible
    """
    return await service.create_manual_order(payload)

@router.get("/", response_model=List[OrderResponse])
async def list_orders(
    service: OrderService = Depends(get_order_service)
):
    """Get all recorded orders"""
    return await service.list_orders()
```

#### **Sync Router** - [app/routers/sync.py](backend/app/routers/sync.py)

```python
from fastapi import APIRouter, Depends
from app.models.sync import TitleMatchRequest, TitleMatchResult, SyncRawProductRequest
from app.services import SyncService
from app.dependencies import get_sync_service

router = APIRouter(prefix="/sync", tags=["sync"])

@router.post("/match-title", response_model=TitleMatchResult)
async def match_title(
    request: TitleMatchRequest,
    service: SyncService = Depends(get_sync_service)
):
    """
    Find best NLP match for marketplace title.
    
    Returns confidence score for user review before unification.
    """
    return await service.match_title(request)

@router.post("/raw-products")
async def ingest_raw_product(
    payload: SyncRawProductRequest,
    service: SyncService = Depends(get_sync_service)
):
    """
    Ingest marketplace product and attempt automatic unification.
    
    Workflow:
    1. Get catalog titles
    2. Run NLP matching
    3. Store raw product record
    4. Return match results
    """
    return await service.ingest_raw_product(payload)
```

---

## Frontend Architecture

### High-Level Structure

```
lib/
├── main.dart                        # Entry point & initialization
├── app.dart                         # Root widget (MaterialApp)
├── auth_gate.dart                   # Authentication state management
│
├── core/                            # Utilities & configuration
│   ├── config/
│   │   └── app_config.dart         # API base URL, constants
│   ├── errors/
│   │   └── api_exception.dart      # ApiError, ApiException classes
│   └── network/
│       └── api_client.dart         # HTTP client with error handling
│
├── data/                            # Data layer (repositories, models, data sources)
│   ├── datasources/
│   │   ├── product_remote_datasource.dart
│   │   └── order_remote_datasource.dart
│   ├── models/
│   │   ├── order.dart
│   │   └── product.dart
│   └── repositories/
│       ├── order_repository_impl.dart
│       └── product_repository_impl.dart
│
├── presentation/                    # UI layer (screens, providers, widgets)
│   ├── providers/
│   │   ├── order_provider.dart
│   │   └── product_provider.dart
│   ├── screens/
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── manual_order_entry/
│   │   │   └── manual_order_entry_screen.dart
│   │   └── ...
│   └── widgets/
│       ├── error_banner.dart
│       └── ...
│
├── screens/                         # Legacy screen files
│   ├── home.dart
│   ├── profile.dart
│   ├── sign_in_screen.dart
│   ├── product_stock_view.dart
│   ├── manual_new_product_entry_form.dart
│   └── manual_prodct_stock_update_form.dart
│
├── services/                        # API services (deprecated, use repositories)
│   ├── product_api_service.dart
│   ├── stock_api_service.dart
│   └── trendyol_api_services.dart
│
└── widgets/                         # Reusable widgets
    ├── app_scaffold.dart
    └── product_card.dart
```

### Application Flow

```
main.dart
    │
    ├─ Configure environment (.env)
    ├─ Initialize Firebase
    └─ Setup providers (ProductProvider, OrderProvider)
         │
         ▼
    MyApp (app.dart)
         │
         ├─ MaterialApp with routes
         └─ Theme configuration
             │
             ▼
        AuthGate (auth_gate.dart)
             │
             ├─ Listen to authStateChanges()
             │
             ├─ Unauthenticated → SignInScreen
             │
             └─ Authenticated → HomeScreen
                  │
                  ├─ AppScaffold (responsive wrapper)
                  │
                  ├─ Home
                  ├─ Profile (manage Trendyol connection)
                  ├─ Dashboard (analytics)
                  ├─ Product Stock View
                  ├─ Manual Sale Entry
                  ├─ Manual Stock Update
                  └─ Manual New Product Entry
```

---

### Entry Point & Initialization

#### **main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/order_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

#### **app.dart**

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Small Business Management Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/sign-in',
      routes: {
        '/sign-in': (context) => const SignInScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/product-stock': (context) => const ProductStockViewScreen(),
        '/manual-sale-entry-form': (context) => const ManualOrderEntryScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/manual-new-product-entry-form': (context) => const ManualProductEntryForm(),
        '/manual-product-stock-update-form': (context) => const ManualStockAdjustmentForm(),
      },
      home: const AuthGate(),
    );
  }
}
```

#### **auth_gate.dart**

```dart
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Authenticated
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Unauthenticated
        return const SignInScreen();
      },
    );
  }
}
```

---

### State Management

#### **ProductProvider** - [presentation/providers/product_provider.dart](lib/presentation/providers/product_provider.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/errors/api_exception.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Load products from API
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _repository.getProducts();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
    } catch (e) {
      _errorMessage = 'Unknown error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Find product by ID
  Product? findById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh products
  Future<void> refresh() async {
    await loadProducts();
  }
}
```

#### **OrderProvider** - [presentation/providers/order_provider.dart](lib/presentation/providers/order_provider.dart)

```dart
class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();
  
  bool _isSubmitting = false;
  String? _errorMessage;
  OrderResult? _lastResult;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  OrderResult? get lastResult => _lastResult;

  /// Submit manual order
  Future<bool> submitOrder(ManualOrder order) async {
    _isSubmitting = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      _lastResult = await _repository.submitManualOrder(order);
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      return false;
    } catch (e) {
      _errorMessage = 'Unknown error: ${e.toString()}';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

---

### Data Models

#### **Product Model** - [data/models/product.dart](lib/data/models/product.dart)

```dart
class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final double price;
  final int totalStock;
  final List<String> platforms;
  final String? sku;
  final String? primaryImageUrl;
  final bool isManuallyReviewed;
  final String matchingConfidence;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.price,
    required this.totalStock,
    required this.platforms,
    this.sku,
    this.primaryImageUrl,
    this.isManuallyReviewed = true,
    this.matchingConfidence = 'high',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      totalStock: json['totalStock'] ?? 0,
      platforms: List<String>.from(json['platforms'] ?? []),
      sku: json['sku'],
      primaryImageUrl: json['primaryImageUrl'],
      isManuallyReviewed: json['isManuallyReviewed'] ?? true,
      matchingConfidence: json['matchingConfidence'] ?? 'high',
    );
  }

  /// Display label for dropdowns/lists
  String get displayLabel => '$name - \$${price.toStringAsFixed(2)}';
}
```

#### **ManualOrder Model** - [data/models/order.dart](lib/data/models/order.dart)

```dart
class ManualOrder {
  final String productId;
  final String productName;
  final int quantity;
  final double salesPrice;
  final String currency;
  final String platform;
  final DateTime saleDate;
  final String notes;

  const ManualOrder({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.salesPrice,
    required this.currency,
    required this.platform,
    required this.saleDate,
    this.notes = '',
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'salesPrice': salesPrice,
      'currency': currency,
      'platform': platform,
      'saleDate': saleDate.toIso8601String(),
      'notes': notes,
    };
  }
}

class OrderResult {
  final String id;
  final String? transactionId;
  final String productName;
  final int quantity;

  const OrderResult({
    required this.id,
    this.transactionId,
    required this.productName,
    required this.quantity,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    return OrderResult(
      id: json['id'] ?? '',
      transactionId: json['transactionId'],
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }
}
```

---

### Repositories

#### **ProductRepository** - [data/repositories/product_repository_impl.dart](lib/data/repositories/product_repository_impl.dart)

```dart
class ProductRepository {
  final _dataSource = ProductRemoteDataSource();

  Future<List<Product>> getProducts() async {
    try {
      return await _dataSource.fetchProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> addProduct(Map<String, dynamic> payload) async {
    try {
      return await _dataSource.createProduct(payload);
    } catch (e) {
      rethrow;
    }
  }
}
```

#### **OrderRepository** - [data/repositories/order_repository_impl.dart](lib/data/repositories/order_repository_impl.dart)

```dart
class OrderRepository {
  final _dataSource = OrderRemoteDataSource();

  Future<OrderResult> submitManualOrder(ManualOrder order) async {
    try {
      return await _dataSource.submitManualOrder(order);
    } catch (e) {
      rethrow;
    }
  }
}
```

---

### API Client & Error Handling

#### **ApiClient** - [core/network/api_client.dart](lib/core/network/api_client.dart)

```dart
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late http.Client _httpClient;
  final Duration _timeout = const Duration(seconds: 30);

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _httpClient = http.Client();
  }

  String get baseUrl => AppConfig.apiBaseUrl;

  /// GET request
  Future<dynamic> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    try {
      final response = await _httpClient.get(url).timeout(_timeout);
      return _handleResponse(response);
    on http.ClientException catch (e) {
      throw ApiException(
        error: ApiError(message: 'Network error: ${e.message}', code: 'network_error'),
        statusCode: null,
      );
    } on TimeoutException {
      throw ApiException(
        error: ApiError(message: 'Request timeout', code: 'timeout'),
        statusCode: null,
      );
    }
  }

  /// POST request
  Future<dynamic> post(String path, dynamic body) async {
    final url = Uri.parse('$baseUrl$path');
    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = jsonDecode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    // Error response from FastAPI
    final error = ApiError.fromJson(body['error'] ?? {});
    throw ApiException(error: error, statusCode: statusCode);
  }

  void _handleError(dynamic error) {
    if (error is ApiException) {
      rethrow;
    }
    throw ApiException(
      error: ApiError(message: error.toString(), code: 'unknown_error'),
      statusCode: null,
    );
  }
}
```

#### **ApiException & ApiError** - [core/errors/api_exception.dart](lib/core/errors/api_exception.dart)

```dart
class ApiError {
  final String message;
  final String code;
  final dynamic details;

  ApiError({
    required this.message,
    required this.code,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'Unknown error',
      code: json['code'] ?? 'unknown',
      details: json['details'],
    );
  }

  @override
  String toString() => '$code: $message';
}

class ApiException implements Exception {
  final ApiError error;
  final int? statusCode;

  ApiException({required this.error, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): ${error.message}';
}
```

---

### Screens

#### **SignInScreen** - [screens/sign_in_screen.dart](lib/screens/sign_in_screen.dart)

```dart
class SignInScreen extends StatelessWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1E3B), Color(0xFF1E90FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FirebaseUIAuth(
            providers: [
              EmailAuthProvider(),
            ],
            onSignedIn: () {
              Navigator.of(context).pushReplacementNamed('/profile');
            },
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
```

#### **ProfileScreen** - [screens/profile.dart](lib/screens/profile.dart)

**Features:**
- Display Firebase Auth user info
- Manage Trendyol connection
- Connect/disconnect buttons

```dart
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _sellerIdController = TextEditingController();
  final _apiPasswordController = TextEditingController();
  bool _isTrendyolConnected = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _checkTrendyolStatus();
  }

  Future<void> _checkTrendyolStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await ApiClient().get(
        '/auth/marketplace/trendyol/${user.uid}',
      );
      setState(() {
        _isTrendyolConnected = response['connected'] ?? false;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _connectTrendyol() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _sellerIdController.text.isEmpty) return;

    setState(() => _isConnecting = true);

    try {
      await ApiClient().post(
        '/auth/marketplace/trendyol',
        {
          'uid': user.uid,
          'seller_id': _sellerIdController.text,
          'api_password': _apiPasswordController.text,
        },
      );
      
      setState(() {
        _isTrendyolConnected = true;
        _sellerIdController.clear();
        _apiPasswordController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trendyol connected successfully')),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.error.message}')),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return AppScaffold(
      title: 'Profile',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${user?.email}'),
                  const SizedBox(height: 8),
                  Text('Display Name: ${user?.displayName ?? 'Not set'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Trendyol connection
          Text(
            'Marketplace Connections',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          if (_isTrendyolConnected)
            Chip(
              label: const Text('Trendyol Connected'),
              backgroundColor: Colors.green.shade200,
            )
          else
            Column(
              children: [
                TextField(
                  controller: _sellerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Seller ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _connectTrendyol,
                  icon: const Icon(Icons.link),
                  label: _isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect Trendyol'),
                ),
              ],
            ),
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/sign-in');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
```

#### **DashboardScreen** - [presentation/screens/dashboard/dashboard_screen.dart](lib/presentation/screens/dashboard/dashboard_screen.dart)

```dart
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = provider.products;
          final totalProducts = products.length;
          final totalStock = products.fold<int>(0, (sum, p) => sum + p.totalStock);
          final lowStockItems = products.where((p) => p.totalStock < 5).length;
          final uniquePlatforms = <String>{};
          for (var p in products) {
            uniquePlatforms.addAll(p.platforms);
          }

          return GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _MetricCard(
                title: 'Total Products',
                value: totalProducts.toString(),
                color: Colors.blue,
              ),
              _MetricCard(
                title: 'Total Stock',
                value: totalStock.toString(),
                color: Colors.green,
              ),
              _MetricCard(
                title: 'Low Stock Items',
                value: lowStockItems.toString(),
                color: Colors.orange,
              ),
              _MetricCard(
                title: 'Platforms',
                value: uniquePlatforms.length.toString(),
                color: Colors.purple,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
```

#### **ManualOrderEntryScreen** - [presentation/screens/manual_order_entry/manual_order_entry_screen.dart](lib/presentation/screens/manual_order_entry/manual_order_entry_screen.dart)

```dart
class ManualOrderEntryScreen extends StatefulWidget {
  const ManualOrderEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualOrderEntryScreen> createState() => _ManualOrderEntryScreenState();
}

class _ManualOrderEntryScreenState extends State<ManualOrderEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedProductId;
  String? _selectedPlatform;
  String _currency = 'TRY';
  DateTime _saleDate = DateTime.now();
  
  late TextEditingController _quantityController;
  late TextEditingController _salePriceController;
  late TextEditingController _notesController;

  final List<String> _platforms = ['WhatsApp', 'Instagram', 'Trendyol', 'Hepsiburada', 'Other'];
  final List<String> _currencies = ['TRY', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _salePriceController = TextEditingController();
    _notesController = TextEditingController();
    
    // Load products on init
    Future.microtask(() {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _salePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null || _selectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select product and platform')),
      );
      return;
    }

    final products = context.read<ProductProvider>().products;
    final product = products.firstWhere((p) => p.id == _selectedProductId);

    final order = ManualOrder(
      productId: _selectedProductId!,
      productName: product.name,
      quantity: int.parse(_quantityController.text),
      salesPrice: double.parse(_salePriceController.text),
      currency: _currency,
      platform: _selectedPlatform!,
      saleDate: _saleDate,
      notes: _notesController.text,
    );

    final success = await context.read<OrderProvider>().submitOrder(order);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order recorded successfully')),
        );
        _clearForm();
        // Reload product list to reflect stock changes
        await context.read<ProductProvider>().loadProducts();
      } else {
        final error = context.read<OrderProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    _quantityController.clear();
    _salePriceController.clear();
    _notesController.clear();
    setState(() {
      _selectedProductId = null;
      _selectedPlatform = null;
      _currency = 'TRY';
      _saleDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Record Manual Sale',
      body: Consumer2<ProductProvider, OrderProvider>(
        builder: (context, productProvider, orderProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Product selection
                  DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    hint: const Text('Select Product'),
                    items: productProvider.products
                        .map((product) => DropdownMenuItem(
                          value: product.id,
                          child: Text('${product.name} (${product.totalStock} in stock)'),
                        ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedProductId = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Please select a product';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Quantity
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Must be positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Sales price
                  TextFormField(
                    controller: _salePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Sales Price',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Currency
                  DropdownButtonFormField<String>(
                    value: _currency,
                    items: _currencies
                        .map((curr) => DropdownMenuItem(
                          value: curr,
                          child: Text(curr),
                        ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _currency = value ?? 'TRY');
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Platform
                  DropdownButtonFormField<String>(
                    value: _selectedPlatform,
                    hint: const Text('Select Platform'),
                    items: _platforms
                        .map((platform) => DropdownMenuItem(
                          value: platform,
                          child: Text(platform),
                        ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedPlatform = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Sale date picker
                  ListTile(
                    title: Text('Sale Date: ${_saleDate.toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _saleDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _saleDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Error message
                  if (orderProvider.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ErrorBanner(
                        message: orderProvider.errorMessage!,
                        onRetry: _submitOrder,
                      ),
                    ),
                  
                  // Submit button
                  ElevatedButton(
                    onPressed: orderProvider.isSubmitting ? null : _submitOrder,
                    child: orderProvider.isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Record Order'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

### Reusable Widgets

#### **AppScaffold** - [widgets/app_scaffold.dart](lib/widgets/app_scaffold.dart)

```dart
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const AppScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: isSmallScreen ? _buildDrawer(context) : null,
      body: isSmallScreen
          ? body
          : Row(
              children: [
                SizedBox(width: 250, child: _buildDrawer(context)),
                Expanded(child: body),
              ],
            ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
          _DrawerItem(
            icon: Icons.home,
            label: 'Home',
            onTap: () => _navigate(context, '/home'),
          ),
          _DrawerItem(
            icon: Icons.person,
            label: 'Profile',
            onTap: () => _navigate(context, '/profile'),
          ),
          _DrawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () => _navigate(context, '/dashboard'),
          ),
          _DrawerItem(
            icon: Icons.inventory,
            label: 'Product Stock',
            onTap: () => _navigate(context, '/product-stock'),
          ),
          _DrawerItem(
            icon: Icons.sell,
            label: 'Manual Sale Entry',
            onTap: () => _navigate(context, '/manual-sale-entry-form'),
          ),
          _DrawerItem(
            icon: Icons.edit_location,
            label: 'Manual Stock Update',
            onTap: () => _navigate(context, '/manual-product-stock-update-form'),
          ),
          _DrawerItem(
            icon: Icons.add_box,
            label: 'New Product',
            onTap: () => _navigate(context, '/manual-new-product-entry-form'),
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.logout,
            label: 'Sign Out',
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/sign-in');
            },
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
    if (MediaQuery.of(context).size.width < 800) {
      Navigator.pop(context);
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
```

---

## Data Flow

### User Creation Flow

```
User signs in with email → Firebase Auth creates user
                         ↓
                    AuthGate detects auth state change
                         ↓
                    Navigates to HomeScreen
                         ↓
                    User exists in Firebase Auth
                         ↓
                    (No automatic Firestore record until profile interaction)
```

### Product Management Flow

```
Inventory Router: POST /api/inventory/products
        ↓ (ProductCreate data)
        ↓
ProductService.create_product()
        ↓ (validates data)
        ↓
ProductRepository.create()
        ↓ (generates doc ID)
        ↓
Firestore unified_products collection
        ↓ (returns with ID)
        ↓
ProductResponse (JSON serialized)
        ↓
Frontend displays in ProductProvider
```

### Manual Order Flow (with atomic transaction)

```
Frontend: ManualOrderEntryScreen
        ↓
OrderProvider.submitOrder(ManualOrder)
        ↓ HTTP POST /api/orders/manual
        ↓
OrderService.create_manual_order()
        ↓
BEGIN TRANSACTION:
  1. Read product stock in transaction lock
  2. Validate: requested ≤ available
  3. UPDATE unified_products.totalStock -= quantity
  4. CREATE orders document
  5. CREATE stock_transactions audit record
COMMIT TRANSACTION
        ↓
If any step fails, ROLLBACK all changes
        ↓
Return OrderResponse with order ID
        ↓
Frontend: Show success message
        ↓
ProductProvider.loadProducts() → refresh UI with updated stock
```

### Title Matching (Sync) Flow

```
TrendyolMockClient fetches products
        ↓
SyncService.ingest_raw_product()
        ↓
TitleUnificationService.find_best_match()
        ├─ Normalize marketplace title
        ├─ Normalize catalog titles
        ├─ TF-IDF vectorization
        ├─ Cosine similarity calculation
        └─ Return best match + score
        ↓
IF similarity >= 0.8:
  → Auto-match ✓
ELSE:
  → Flag for manual review
        ↓
Store in raw_products collection
        with match details
```

---

## Database Schema

### Firestore Structure

```
root/
├── Users/
│   └── {uid}/
│       ├── marketplaces
│       │   └── trendyol
│       │       ├── platform: "trendyol"
│       │       ├── seller_id: "SELLER123"
│       │       ├── api_password: "encrypted-value"
│       │       ├── connected_at: "2024-06-25T10:30:00Z"
│       │       └── status: "active"
│       ├── connected_platforms: ["trendyol"]
│       ├── created_at: Timestamp
│       └── updated_at: Timestamp
│
├── unified_products/
│   └── {product_id}/
│       ├── name: "iPhone 15 Pro Max"
│       ├── brand: "Apple"
│       ├── category: "Electronics"
│       ├── description: "..."
│       ├── price: 999.99
│       ├── totalStock: 50
│       ├── platforms: ["Trendyol", "WhatsApp"]
│       ├── sku: "APL-IP15PM-256"
│       ├── primaryImageUrl: "https://..."
│       ├── isManuallyReviewed: true
│       ├── matchingConfidence: "high"
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
├── orders/
│   └── {order_id}/
│       ├── productId: "product-id"
│       ├── productName: "iPhone 15 Pro Max"
│       ├── quantity: 5
│       ├── salesPrice: 999.99
│       ├── currency: "TRY"
│       ├── platform: "WhatsApp"
│       ├── notes: "Customer notes"
│       ├── saleDate: Timestamp
│       └── createdAt: Timestamp
│
├── stock_transactions/
│   └── {tx_id}/
│       ├── type: "manual_sale|adjustment|sync"
│       ├── productId: "product-id"
│       ├── productName: "Product Name"
│       ├── quantityDelta: -5
│       ├── oldStock: 50
│       ├── newStock: 45
│       ├── orderId: "order-id"
│       ├── adjustmentType: "decrease|increase"
│       ├── reason: "Manual order"
│       ├── adjustmentDate: Timestamp
│       └── createdAt: Timestamp
│
└── raw_products/
    └── {raw_id}/
        ├── platform: "Trendyol"
        ├── raw_title: "iPhone 15 PRO max 256gb"
        ├── external_id: "trendyol-12345"
        ├── price: 999.99
        ├── stock: 30
        ├── matched: true
        ├── matchedTitle: "iPhone 15 Pro Max"
        ├── similarity: 0.98
        └── ingestedAt: Timestamp
```

---

## Integration Points

### Frontend ↔ Backend Communication

```
HTTPS/HTTP Requests
Base URL: http://localhost:8000 (development) or production URL

Headers:
  Content-Type: application/json
  (No auth required - Firebase Auth is client-side only)

Response Format:
{
  "id": "...",
  "data": {...}
}

Error Format:
{
  "error": {
    "message": "...",
    "code": "insufficient_stock|not_found|...",
    "details": {...}
  }
}
```

### Authentication Flow

```
Firebase Auth (client-side)
    ↓
User signs in with email
    ↓
Firebase creates auth token
    ↓
AuthGate listens to authStateChanges()
    ↓
If authenticated → Access all screens
    ↓
User's UID available for Firestore queries
    ↓
Marketplace credentials saved to Firestore under Users/{uid}/marketplaces
```

### Real-Time Updates

- Product list: Loaded via GET /api/inventory/products (manual refresh)
- Orders: Loaded via GET /api/orders (manual refresh)
- Stock levels: Updated atomically via transactions

(No WebSocket listeners currently - all updates are via HTTP polling)

---

## Security & Encryption

### Marketplace Credential Encryption

**Algorithm:** Fernet (symmetric encryption)

```
1. Key Derivation:
   - PBKDF2-HMAC-SHA256
   - Salt: "smart_inventory_hub_salt"
   - Iterations: 100,000
   - Output length: 32 bytes
   
2. Encryption:
   - Fernet (AES-128 + HMAC)
   - Encrypts api_password before storage
   - Stored in Firestore Users/{uid}/marketplaces/trendyol/api_password
   
3. Decryption:
   - Retrieved from Firestore
   - Decrypted with same key derivation
   - Used for Trendyol API calls
   - Never stored in plaintext
```

**Example:**

```python
# Encryption
key = PBKDF2(salt="smart_inventory_hub_salt").derive(secret_key)
cipher = Fernet(key)
encrypted = cipher.encrypt(b"api-password-123")
# Store encrypted in Firestore

# Decryption
cipher = Fernet(key)
decrypted = cipher.decrypt(encrypted)  # b"api-password-123"
```

### CORS Configuration

```python
CORSMiddleware(
    allow_origins="*",  # In production: ["https://yourdomain.com"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)
```

### Firebase Security Rules (Recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own document
    match /Users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    
    // Products: public read, admin only write
    match /unified_products/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && isAdmin(request.auth.uid);
    }
    
    // Orders: user can read own, admin can write
    match /orders/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && isAdmin(request.auth.uid);
    }
    
    // Stock transactions: admin only
    match /stock_transactions/{document=**} {
      allow read, write: if request.auth != null && isAdmin(request.auth.uid);
    }
  }
  
  function isAdmin(uid) {
    return get(/databases/$(database)/documents/Users/$(uid)).data.isAdmin == true;
  }
}
```

---

## API Endpoints Reference

### Complete Endpoint Map

#### Authentication
```
POST   /api/auth/marketplace/trendyol
       Connect Trendyol account (store encrypted credentials)
GET    /api/auth/marketplace/trendyol/{uid}
       Get Trendyol connection status
GET    /api/auth/marketplace/trendyol/{uid}/products
       Fetch Trendyol product list
GET    /api/auth/marketplace/trendyol/{uid}/orders
       Fetch Trendyol order list
```

#### Inventory
```
GET    /api/inventory/products
       List all unified products (response: List[ProductResponse])
POST   /api/inventory/products
       Create new product (body: ProductCreate)
GET    /api/inventory/products/{product_id}
       Get single product
PUT    /api/inventory/products/{product_id}
       Update product (body: ProductCreate)
DELETE /api/inventory/products/{product_id}
       Delete product
POST   /api/inventory/stock/adjust
       Adjust stock manually (body: StockAdjustmentRequest)
```

#### Orders
```
POST   /api/orders/manual
       Record manual sale (body: ManualOrderCreate)
       (Atomic transaction: validates stock, decrements, creates order)
GET    /api/orders/
       List all orders (response: List[OrderResponse])
```

#### Sync (Marketplace Integration)
```
POST   /api/sync/match-title
       NLP title matching (body: TitleMatchRequest)
       Returns: TitleMatchResult with similarity score
POST   /api/sync/raw-products
       Ingest marketplace product (body: SyncRawProductRequest)
       Returns: Raw product record with match results
```

#### Legacy (Backward Compatibility)
```
GET    /api/products
       → Redirects to /api/inventory/products
POST   /api/products
       → Redirects to /api/inventory/products
GET    /api/stock
       → Redirects to /api/inventory/stock/adjust
```

---

## Technology Stack

### Backend
| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Web Framework** | FastAPI | 0.136.1 | REST API framework |
| **Server** | Uvicorn | 0.47.0 | ASGI server |
| **Data Validation** | Pydantic | 2.13.4 | Request/response models |
| **Database** | Firestore | 2.16.0+ | NoSQL cloud database |
| **Firebase** | firebase-admin | 6.5.0+ | Firebase Admin SDK |
| **Encryption** | cryptography | 48.0.0 | Fernet symmetric encryption |
| **NLP** | scikit-learn | 1.4.0+ | TF-IDF vectorization |
| **Environment** | python-dotenv | 1.0.0 | .env configuration |
| **Python** | Python | 3.9+ | Language runtime |

### Frontend
| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Framework** | Flutter | Latest | Cross-platform UI framework |
| **Language** | Dart | Latest | Flutter language |
| **State Management** | Provider | Latest | ChangeNotifier pattern |
| **HTTP Client** | http | Latest | REST API client |
| **Authentication** | Firebase Auth | Latest | User authentication |
| **Firebase** | firebase_core | Latest | Firebase SDK |
| **UI Auth** | firebase_ui_auth | Latest | Pre-built auth UI |
| **Environment** | flutter_dotenv | Latest | .env configuration |

### Infrastructure
| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Database** | Firebase Firestore | NoSQL document database |
| **Authentication** | Firebase Authentication | User auth & management |
| **Marketplace Integration** | Trendyol API (via Postman Mock) | Marketplace product/order sync |
| **Encryption** | Fernet (PBKDF2-HMAC-SHA256) | Credential security |

---

## Why This Architecture Works

### 1. **Scalability**
- Firestore automatically scales
- Stateless FastAPI servers (easy horizontal scaling)
- NLP processing is lightweight (TF-IDF, not deep learning)

### 2. **Real-Time Consistency**
- Atomic Firestore transactions guarantee stock consistency
- No race conditions possible
- Audit trail ensures accountability

### 3. **User Experience**
- Flutter provides fast, responsive UI across platforms
- Provider pattern keeps UI logic simple
- Error handling with user-friendly messages

### 4. **Maintainability**
- Clean separation of concerns (routers → services → repositories)
- Type-safe with Pydantic (Python) and Dart
- Comprehensive error handling with custom exceptions

### 5. **Security**
- Encrypted marketplace credentials (Fernet)
- Firebase Auth for user authentication
- Firestore security rules for data access control

### 6. **Cost Efficiency**
- Serverless Firestore (pay per read/write)
- No infrastructure to manage
- Trendyol integration via mock (can easily switch to real API)

---

**End of Architecture Document**

Generated: 2026-06-25  
Project: Smart Business Management Platform  
For: Final Project Report
