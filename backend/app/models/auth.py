"""Authentication and marketplace credential schemas."""

from pydantic import BaseModel


class TrendyolCredentials(BaseModel):
    """Trendyol seller credentials submitted by the Flutter client."""

    uid: str
    seller_id: str
    api_password: str


class TrendyolConnectionStatus(BaseModel):
    """Non-sensitive connection status for the profile screen."""

    connected: bool
    connected_at: str | None = None
    status: str | None = None
