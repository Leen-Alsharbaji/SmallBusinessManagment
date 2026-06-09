"""
Product repository — all Firestore reads/writes for unified_products.

Routers and services must never import firebase_admin directly; they use
this repository instead.
"""

from datetime import datetime
from typing import Any

from google.cloud.firestore_v1 import DocumentSnapshot

from app.db.firestore_client import FirestoreCollections, get_db, init_firebase
from app.config import get_settings
from app.exceptions import NotFoundError


class ProductRepository:
    """Encapsulates CRUD operations on the unified products collection."""

    def __init__(self, collections: FirestoreCollections | None = None):
        settings = get_settings()
        db = init_firebase(settings)
        self._col = (collections or FirestoreCollections(db, settings)).products

    def _serialize(self, doc: DocumentSnapshot) -> dict[str, Any]:
        data = doc.to_dict() or {}
        data["id"] = doc.id
        return data

    def list_all(self) -> list[dict[str, Any]]:
        """Return every unified product document."""
        return [self._serialize(doc) for doc in self._col.stream()]

    def get_by_id(self, product_id: str) -> dict[str, Any]:
        """Fetch a single product or raise NotFoundError."""
        doc = self._col.document(product_id).get()
        if not doc.exists:
            raise NotFoundError(f"Product '{product_id}' not found")
        return self._serialize(doc)

    def create(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Create a product and return the persisted record."""
        now = datetime.utcnow()
        payload = {**payload, "createdAt": now, "updatedAt": now}
        doc_ref = self._col.document()
        doc_ref.set(payload)
        return {"id": doc_ref.id, **payload}

    def update(self, product_id: str, payload: dict[str, Any]) -> None:
        """Update mutable product fields."""
        doc_ref = self._col.document(product_id)
        if not doc_ref.get().exists:
            raise NotFoundError(f"Product '{product_id}' not found")
        payload["updatedAt"] = datetime.utcnow()
        doc_ref.update(payload)

    def delete(self, product_id: str) -> None:
        """Delete a product document."""
        doc_ref = self._col.document(product_id)
        if not doc_ref.get().exists:
            raise NotFoundError(f"Product '{product_id}' not found")
        doc_ref.delete()

    def get_snapshot_in_transaction(self, transaction, product_id: str) -> DocumentSnapshot:
        """Read a product snapshot inside an active Firestore transaction."""
        doc_ref = self._col.document(product_id)
        snapshot = doc_ref.get(transaction=transaction)
        if not snapshot.exists:
            raise NotFoundError(f"Product '{product_id}' not found")
        return snapshot

    @property
    def collection(self):
        """Expose collection ref for transactional writes in services."""
        return self._col
