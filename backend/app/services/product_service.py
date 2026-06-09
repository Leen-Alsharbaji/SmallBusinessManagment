"""
Product business logic — validation and orchestration above the repository.
"""

from app.models.product import ProductCreate, ProductUpdate
from app.repositories.product_repository import ProductRepository


class ProductService:
    """Coordinates product CRUD without exposing Firestore details."""

    def __init__(self, repository: ProductRepository | None = None):
        self._repo = repository or ProductRepository()

    def list_products(self) -> list[dict]:
        return self._repo.list_all()

    def get_product(self, product_id: str) -> dict:
        return self._repo.get_by_id(product_id)

    def create_product(self, payload: ProductCreate) -> dict:
        return self._repo.create(payload.model_dump())

    def update_product(self, product_id: str, payload: ProductUpdate) -> dict:
        updates = payload.model_dump(exclude_unset=True)
        self._repo.update(product_id, updates)
        return self._repo.get_by_id(product_id)

    def delete_product(self, product_id: str) -> None:
        self._repo.delete(product_id)

    def list_titles(self) -> list[str]:
        """Return catalog titles for NLP candidate matching."""
        return [p.get("name", "") for p in self.list_products() if p.get("name")]
