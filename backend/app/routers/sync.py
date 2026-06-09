"""
Sync routers — NLP title unification and raw product ingestion.

Prefix: /sync
"""

from fastapi import APIRouter, Depends

from app.dependencies import get_sync_service
from app.models.sync import SyncRawProductRequest, TitleMatchRequest, TitleMatchResult
from app.services.sync_service import SyncService

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/match-title", response_model=TitleMatchResult)
async def match_title(
    request: TitleMatchRequest,
    service: SyncService = Depends(get_sync_service),
):
    """Match a raw marketplace title against the unified catalog via NLP."""
    return service.match_title(request)


@router.post("/raw-products")
async def ingest_raw_product(
    payload: SyncRawProductRequest,
    service: SyncService = Depends(get_sync_service),
):
    """Ingest a raw marketplace listing and attempt automatic unification."""
    return service.ingest_raw_product(payload)
