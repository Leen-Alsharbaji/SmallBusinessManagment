"""
Manual order processing with atomic Firestore transactions.

A single transaction:
    1. Reads current stock for the product
    2. Validates sufficient quantity
    3. Decrements totalStock
    4. Writes the order document
    5. Writes an immutable stock_transactions audit record
"""

from datetime import datetime

from google.cloud import firestore

from app.db.firestore_client import get_db
from app.exceptions import InsufficientStockError, NotFoundError
from app.models.order import ManualOrderCreate, OrderResponse
from app.repositories.order_repository import OrderRepository, StockTransactionRepository
from app.repositories.product_repository import ProductRepository


class OrderService:
    """Processes manual WhatsApp/Instagram orders atomically."""

    def __init__(
        self,
        product_repo: ProductRepository | None = None,
        order_repo: OrderRepository | None = None,
        tx_repo: StockTransactionRepository | None = None,
    ):
        self._products = product_repo or ProductRepository()
        self._orders = order_repo or OrderRepository()
        self._transactions = tx_repo or StockTransactionRepository()
        self._db = get_db()

    def create_manual_order(self, payload: ManualOrderCreate) -> OrderResponse:
        """Atomically decrement stock and persist order + transaction records.

        Args:
            payload: Validated manual order request from the router layer.

        Returns:
            OrderResponse: Created order with transaction audit ID.

        Raises:
            NotFoundError: Product does not exist.
            InsufficientStockError: Requested quantity exceeds available stock.
        """
        order_id: str | None = None
        tx_id: str | None = None

        @firestore.transactional
        def _run(transaction):
            nonlocal order_id, tx_id

            # Step 1: Read product snapshot inside the transaction
            snapshot = self._products.get_snapshot_in_transaction(
                transaction, payload.productId
            )
            product_data = snapshot.to_dict() or {}
            current_stock = int(product_data.get("totalStock", 0))

            # Step 2: Guard — reject if insufficient stock
            if payload.quantity > current_stock:
                raise InsufficientStockError(
                    f"Insufficient stock: requested {payload.quantity}, "
                    f"available {current_stock}"
                )

            new_stock = current_stock - payload.quantity

            # Step 3: Decrement stock atomically
            product_ref = self._products.collection.document(payload.productId)
            transaction.update(
                product_ref,
                {
                    "totalStock": new_stock,
                    "updatedAt": datetime.utcnow(),
                },
            )

            # Step 4: Write order record
            order_ref = self._orders._orders.document()
            order_data = {
                "productId": payload.productId,
                "unifiedProductId": payload.productId,
                "productName": payload.productName,
                "quantity": payload.quantity,
                "salesPrice": payload.salesPrice,
                "currency": payload.currency,
                "platform": payload.platform,
                "notes": payload.notes,
                "saleDate": payload.saleDate,
                "createdAt": datetime.utcnow(),
            }
            transaction.set(order_ref, order_data)
            order_id = order_ref.id

            # Step 5: Write stock transaction audit trail
            tx_ref = self._transactions._col.document()
            tx_data = {
                "type": "manual_sale",
                "productId": payload.productId,
                "productName": payload.productName,
                "quantityDelta": -payload.quantity,
                "oldStock": current_stock,
                "newStock": new_stock,
                "orderId": order_id,
                "platform": payload.platform,
                "notes": payload.notes,
                "createdAt": datetime.utcnow(),
            }
            transaction.set(tx_ref, tx_data)
            tx_id = tx_ref.id

            return order_data

        transaction = self._db.transaction()
        order_data = _run(transaction)

        return OrderResponse(
            id=order_id or "",
            productId=payload.productId,
            productName=payload.productName,
            quantity=payload.quantity,
            salesPrice=payload.salesPrice,
            currency=payload.currency,
            platform=payload.platform,
            notes=payload.notes,
            saleDate=payload.saleDate,
            createdAt=order_data["createdAt"],
            transactionId=tx_id,
        )

    def list_orders(self) -> list[dict]:
        return self._orders.list_all()
