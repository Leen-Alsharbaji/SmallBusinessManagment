"""Sync and NLP title-unification API schemas."""

from pydantic import BaseModel, Field


class TitleMatchRequest(BaseModel):
    """Request to match a raw marketplace title against unified catalog."""

    raw_title: str
    candidate_titles: list[str] = Field(default_factory=list)


class TitleMatchResult(BaseModel):
    """Best match above the cosine similarity threshold, if any."""

    matched: bool
    best_title: str | None = None
    similarity: float = 0.0
    threshold: float = 0.8


class SyncRawProductRequest(BaseModel):
    """Ingest a raw marketplace listing for NLP unification."""

    platform: str
    raw_title: str
    external_id: str
    price: float | None = None
    stock: int | None = None
