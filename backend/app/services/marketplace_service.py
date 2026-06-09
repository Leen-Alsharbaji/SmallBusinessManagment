"""
Marketplace credential management and Trendyol proxy orchestration.
"""

import base64
from datetime import datetime

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

from app.config import get_settings
from app.exceptions import NotFoundError
from app.integrations.trendyol.client import TrendyolMockClient
from app.models.auth import TrendyolConnectionStatus, TrendyolCredentials
from app.repositories.user_repository import UserRepository


class MarketplaceService:
    """Encrypts credentials and proxies Trendyol calls via Postman Mock."""

    def __init__(self, user_repo: UserRepository | None = None):
        self._users = user_repo or UserRepository()
        self._cipher = self._build_cipher()

    def _build_cipher(self) -> Fernet:
        settings = get_settings()
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=b"smart_inventory_hub_salt",
            iterations=100_000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(settings.encryption_secret.encode()))
        return Fernet(key)

    def _encrypt(self, value: str) -> str:
        return self._cipher.encrypt(value.encode()).decode()

    def _decrypt(self, value: str) -> str:
        return self._cipher.decrypt(value.encode()).decode()

    def connect_trendyol(self, creds: TrendyolCredentials) -> dict:
        """Encrypt and persist Trendyol seller credentials."""
        marketplace_data = {
            "platform": "trendyol",
            "seller_id": self._encrypt(creds.seller_id),
            "api_password": self._encrypt(creds.api_password),
            "connected_at": datetime.now().isoformat(),
            "status": "active",
        }
        self._users.save_marketplace_credentials(creds.uid, marketplace_data)
        return {
            "status": "success",
            "message": "Trendyol credentials saved and encrypted",
            "platform": "trendyol",
        }

    def get_trendyol_status(self, uid: str) -> TrendyolConnectionStatus:
        entry = self._users.get_trendyol_marketplace(uid)
        if not entry:
            return TrendyolConnectionStatus(connected=False)
        return TrendyolConnectionStatus(
            connected=True,
            connected_at=entry.get("connected_at"),
            status=entry.get("status"),
        )

    def _trendyol_client_for_user(self, uid: str) -> TrendyolMockClient:
        entry = self._users.get_trendyol_marketplace(uid)
        if not entry:
            raise NotFoundError("Trendyol is not connected for this user")

        seller_id = self._decrypt(entry["seller_id"])
        api_password = self._decrypt(entry["api_password"])
        return TrendyolMockClient(seller_id=seller_id, api_password=api_password)

    def fetch_trendyol_products(self, uid: str) -> list[dict]:
        client = self._trendyol_client_for_user(uid)
        products = client.get_products()
        return [p.model_dump() for p in products]

    def fetch_trendyol_orders(self, uid: str) -> list[dict]:
        client = self._trendyol_client_for_user(uid)
        orders = client.get_orders()
        return [o.model_dump() for o in orders]
