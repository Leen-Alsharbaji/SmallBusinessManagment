"""
Sync service — coordinates raw product ingestion and NLP title unification.
"""

from datetime import datetime

from app.db.firestore_client import FirestoreCollections, init_firebase
from app.config import get_settings
from app.models.sync import SyncRawProductRequest, TitleMatchRequest, TitleMatchResult
from app.services.nlp.title_unification_service import TitleUnificationService
from app.services.product_service import ProductService


class SyncService:
    """Orchestrates marketplace sync and title matching workflows."""

    def __init__(
        self,
        product_service: ProductService | None = None,
        nlp_service: TitleUnificationService | None = None,
    ):
        settings = get_settings()
        db = init_firebase(settings)
        self._raw_products = FirestoreCollections(db, settings).raw_products
        self._products = product_service or ProductService()
        self._nlp = nlp_service or TitleUnificationService()

    def match_title(self, request: TitleMatchRequest) -> TitleMatchResult:
        """Run NLP title unification against provided or catalog candidates."""
        candidates = request.candidate_titles or self._products.list_titles()
        matched_title, score = self._nlp.find_best_match(request.raw_title, candidates)

        return TitleMatchResult(
            matched=matched_title is not None,
            best_title=matched_title,
            similarity=round(score, 4),
            threshold=self._nlp.threshold,
        )

    def ingest_raw_product(self, payload: SyncRawProductRequest) -> dict:
        """Store a raw listing and attempt automatic title unification."""
        match = self.match_title(
            TitleMatchRequest(raw_title=payload.raw_title, candidate_titles=[])
        )

        doc = {
            **payload.model_dump(),
            "matched": match.matched,
            "matchedTitle": match.best_title,
            "similarity": match.similarity,
            "ingestedAt": datetime.utcnow(),
        }
        ref = self._raw_products.document()
        ref.set(doc)

        return {
            "id": ref.id,
            "match": match.model_dump(),
            "stored": True,
        }
