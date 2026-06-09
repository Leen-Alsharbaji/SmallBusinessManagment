"""
Order and stock-transaction repositories.

Order writes are orchestrated by OrderService inside Firestore transactions;
this repository provides the low-level document operations.
"""

from datetime import datetime
from typing import Any

from app.db.firestore_client import FirestoreCollections, init_firebase
from app.config import get_settings


class OrderRepository:
    """Persists sales orders to Firestore."""

    def __init__(self, collections: FirestoreCollections | None = None):
        settings = get_settings()
        db = init_firebase(settings)
        cols = collections or FirestoreCollections(db, settings)
        self._orders = cols.orders

    def create_in_transaction(self, transaction, payload: dict[str, Any]) -> str:
        """Create an order document within an existing transaction.

        Args:
            transaction: Active Firestore transaction object.
            payload: Order fields excluding server timestamps.

        Returns:
            str: Generated order document ID.
        """
        doc_ref = self._orders.document()
        payload = {
            **payload,
            "createdAt": datetime.utcnow(),
        }
        transaction.set(doc_ref, payload)
        return doc_ref.id

    def list_all(self) -> list[dict[str, Any]]:
        """Return all orders (newest first)."""
        docs = self._orders.order_by("createdAt", direction="DESCENDING").stream()
        results = []
        for doc in docs:
            data = doc.to_dict() or {}
            data["id"] = doc.id
            results.append(data)
        return results


class StockTransactionRepository:
    """Audit log for every stock movement (orders, adjustments, sync)."""

    def __init__(self, collections: FirestoreCollections | None = None):
        settings = get_settings()
        db = init_firebase(settings)
        self._col = (collections or FirestoreCollections(db, settings)).stock_transactions

    def create_in_transaction(self, transaction, payload: dict[str, Any]) -> str:
        """Write an immutable stock transaction record atomically with stock change."""
        doc_ref = self._col.document()
        payload = {
            **payload,
            "createdAt": datetime.utcnow(),
        }
        transaction.set(doc_ref, payload)
        return doc_ref.id
