"""
User repository — profile and encrypted marketplace credential storage.
"""

from datetime import datetime
from typing import Any

from app.db.firestore_client import FirestoreCollections, init_firebase
from app.config import get_settings
from app.exceptions import NotFoundError


class UserRepository:
    """Firestore access for Users collection documents."""

    def __init__(self, collections: FirestoreCollections | None = None):
        settings = get_settings()
        db = init_firebase(settings)
        self._users = (collections or FirestoreCollections(db, settings)).users

    def get(self, uid: str) -> dict[str, Any]:
        doc = self._users.document(uid).get()
        if not doc.exists:
            raise NotFoundError(f"User '{uid}' not found")
        return doc.to_dict() or {}

    def upsert(self, uid: str, data: dict[str, Any]) -> None:
        self._users.document(uid).set(data, merge=True)

    def save_marketplace_credentials(
        self,
        uid: str,
        marketplace_entry: dict[str, Any],
    ) -> None:
        """Merge Trendyol (or other) credentials into the user's marketplaces array."""
        user_ref = self._users.document(uid)
        user_doc = user_ref.get()

        if not user_doc.exists:
            user_ref.set(
                {
                    "uid": uid,
                    "marketplaces": [marketplace_entry],
                    "connected_platforms": [marketplace_entry["platform"]],
                    "created_at": datetime.now().isoformat(),
                }
            )
            return

        user_data = user_doc.to_dict() or {}
        marketplaces = user_data.get("marketplaces", [])
        platform = marketplace_entry["platform"]
        marketplaces = [m for m in marketplaces if m.get("platform") != platform]
        marketplaces.append(marketplace_entry)

        connected = user_data.get("connected_platforms", [])
        if platform not in connected:
            connected.append(platform)

        user_ref.update(
            {
                "marketplaces": marketplaces,
                "connected_platforms": connected,
                "updated_at": datetime.now().isoformat(),
            }
        )

    def get_trendyol_marketplace(self, uid: str) -> dict[str, Any] | None:
        try:
            user_data = self.get(uid)
        except NotFoundError:
            return None

        for entry in user_data.get("marketplaces", []):
            if entry.get("platform") == "trendyol":
                return entry
        return None
