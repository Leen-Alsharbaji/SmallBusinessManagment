"""
Application configuration loaded from environment variables.

Centralizes all external service URLs, encryption secrets, and NLP thresholds
so routers and services remain free of hard-coded infrastructure details.
"""

from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime settings for the Smart Inventory Hub API."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "Smart Inventory Hub API"
    cors_origins: str = "*"

    firebase_credentials_path: str = "service-account.json"

    # Firestore collection names (single source of truth)
    users_collection: str = "Users"
    products_collection: str = "unified_products"
    orders_collection: str = "orders"
    stock_transactions_collection: str = "stock_transactions"
    raw_products_collection: str = "raw_products"

    # Trendyol integration via Postman Mock Service (never hit live production)
    trendyol_mock_base_url: str = (
        "https://YOUR-POSTMAN-MOCK-ID.mock.pstmn.io"
    )
    trendyol_api_user_agent: str = "SmartInventoryHub - SelfIntegration"

    # NLP Title Unification Engine
    nlp_similarity_threshold: float = 0.8

    # Fernet encryption key for marketplace credentials (32 url-safe base64 bytes)
    encryption_secret: str = "change-me-in-production-use-env-var"


@lru_cache
def get_settings() -> Settings:
    """Return cached application settings singleton.

    Returns:
        Settings: Parsed environment-backed configuration.
    """
    return Settings()
