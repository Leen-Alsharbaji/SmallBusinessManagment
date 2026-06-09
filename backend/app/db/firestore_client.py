"""
Firestore client initialization and collection accessors.

This is the only module that directly imports firebase_admin, keeping all
other layers decoupled from Firebase SDK details.
"""

import firebase_admin
from firebase_admin import credentials, firestore

from app.config import Settings, get_settings

_db: firestore.Client | None = None


def init_firebase(settings: Settings | None = None) -> firestore.Client:
    """Initialize Firebase Admin SDK and return the Firestore client.

    Args:
        settings: Optional settings override (useful in tests).

    Returns:
        firestore.Client: Connected Firestore client instance.
    """
    global _db
    if _db is not None:
        return _db

    cfg = settings or get_settings()
    if not firebase_admin._apps:
        cred = credentials.Certificate(cfg.firebase_credentials_path)
        firebase_admin.initialize_app(cred)

    _db = firestore.client()
    return _db


def get_db() -> firestore.Client:
    """Return the initialized Firestore client, creating it if needed."""
    return init_firebase()


class FirestoreCollections:
    """Typed accessors for Firestore collection references."""

    def __init__(self, db: firestore.Client, settings: Settings):
        self.users = db.collection(settings.users_collection)
        self.products = db.collection(settings.products_collection)
        self.orders = db.collection(settings.orders_collection)
        self.stock_transactions = db.collection(settings.stock_transactions_collection)
        self.raw_products = db.collection(settings.raw_products_collection)
