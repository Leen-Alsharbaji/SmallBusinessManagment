"""
Stock adjustment service with immutable audit trail.
"""

from app.models.product import StockAdjustmentRequest
from app.repositories.order_repository import StockTransactionRepository
from app.repositories.product_repository import ProductRepository


class StockService:
    """Applies stock adjustments and records audit transactions."""

    def __init__(
        self,
        product_repo: ProductRepository | None = None,
        tx_repo: StockTransactionRepository | None = None,
    ):
        self._products = product_repo or ProductRepository()
        self._transactions = tx_repo or StockTransactionRepository()

    def adjust_stock(self, adjustment: StockAdjustmentRequest) -> dict:
        """Persist new stock level and write an audit transaction record."""
        self._products.update(
            adjustment.productId,
            {"totalStock": adjustment.newStock},
        )

        tx_id = self._transactions._col.document().id  # pre-generate id
        self._transactions._col.document(tx_id).set(
            {
                "type": "adjustment",
                "productId": adjustment.productId,
                "productName": adjustment.productName,
                "adjustmentType": adjustment.adjustmentType,
                "quantity": adjustment.quantity,
                "oldStock": adjustment.oldStock,
                "newStock": adjustment.newStock,
                "reason": adjustment.reason,
                "notes": adjustment.notes,
                "adjustmentDate": adjustment.adjustmentDate,
                "createdAt": adjustment.adjustmentDate,
            }
        )

        return {"message": "Stock adjusted successfully", "transactionId": tx_id}
