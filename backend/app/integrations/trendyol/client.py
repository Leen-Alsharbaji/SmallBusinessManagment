"""
Trendyol API client targeting the Postman Mock Service.

All outbound marketplace calls route through the mock base URL configured in
app.config.Settings.trendyol_mock_base_url — never live Trendyol production.

Request headers mirror Trendyol Public API requirements:
    - Authorization: Basic base64(sellerId:apiKey)
    - User-Agent: {sellerId} - {integrationName}
"""

from __future__ import annotations

import base64
import json
from typing import Any
from urllib import error, request

from app.config import get_settings
from app.exceptions import ExternalServiceError
from app.integrations.trendyol.models import TrendyolOrder, TrendyolProduct


class TrendyolMockClient:
    """HTTP client for Trendyol endpoints exposed via Postman Mock Server."""

    def __init__(
        self,
        seller_id: str,
        api_password: str,
        base_url: str | None = None,
        user_agent_suffix: str | None = None,
    ):
        settings = get_settings()
        self.seller_id = seller_id
        self.api_password = api_password
        self.base_url = (base_url or settings.trendyol_mock_base_url).rstrip("/")
        self.user_agent = (
            f"{seller_id} - {user_agent_suffix or settings.trendyol_api_user_agent}"
        )

    def _build_headers(self) -> dict[str, str]:
        """Build Trendyol-compatible authorization headers for mock requests."""
        token = base64.b64encode(
            f"{self.seller_id}:{self.api_password}".encode()
        ).decode()
        return {
            "Authorization": f"Basic {token}",
            "User-Agent": self.user_agent,
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    def _request(self, method: str, path: str, body: dict | None = None) -> Any:
        """Execute an HTTP call against the Postman Mock endpoint.

        Args:
            method: HTTP verb (GET, PUT, POST, ...).
            path: API path appended to mock base URL.
            body: Optional JSON request body.

        Returns:
            Parsed JSON response body.

        Raises:
            ExternalServiceError: When the mock service is unreachable or returns 5xx.
        """
        url = f"{self.base_url}{path}"
        data = json.dumps(body).encode() if body is not None else None
        req = request.Request(url, data=data, headers=self._build_headers(), method=method)

        try:
            with request.urlopen(req, timeout=30) as resp:
                raw = resp.read().decode()
                return json.loads(raw) if raw else {}
        except error.HTTPError as exc:
            if exc.code >= 500:
                raise ExternalServiceError(
                    f"Trendyol mock service error ({exc.code})"
                ) from exc
            raise ExternalServiceError(
                f"Trendyol mock request failed ({exc.code}): {exc.reason}"
            ) from exc
        except error.URLError as exc:
            raise ExternalServiceError(
                "Trendyol Postman Mock service is offline or unreachable"
            ) from exc

    def get_products(self, page: int = 0, size: int = 50) -> list[TrendyolProduct]:
        """Fetch seller products from the mock Trendyol products endpoint."""
        path = f"/integration/product/sellers/{self.seller_id}/products?page={page}&size={size}"
        payload = self._request("GET", path)

        content = payload.get("content", payload if isinstance(payload, list) else [])
        return [TrendyolProduct.model_validate(item) for item in content]

    def get_orders(self, status: str = "Created") -> list[TrendyolOrder]:
        """Fetch orders from the mock Trendyol orders endpoint."""
        path = f"/integration/order/sellers/{self.seller_id}/orders?status={status}"
        payload = self._request("GET", path)
        content = payload.get("content", payload if isinstance(payload, list) else [])
        return [TrendyolOrder.model_validate(item) for item in content]

    def update_stock(self, barcode: str, quantity: int) -> dict[str, Any]:
        """Push stock update to mock Trendyol inventory endpoint."""
        path = f"/integration/inventory/sellers/{self.seller_id}/products/price-and-inventory"
        body = {"items": [{"barcode": barcode, "quantity": quantity}]}
        return self._request("POST", path, body)
