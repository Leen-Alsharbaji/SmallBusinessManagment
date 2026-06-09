"""
NLP Title Unification Engine.

Computes cosine similarity between sentence embeddings of normalized product
titles. Matches at or above the configured threshold (default 0.8) are treated
as the same SKU across marketplaces.

Embedding strategy:
    - Primary: scikit-learn TF-IDF vectors (lightweight, no GPU)
    - The architecture allows swapping in sentence-transformers for production
"""

from __future__ import annotations

import math
from typing import Iterable

from sklearn.feature_extraction.text import TfidfVectorizer

from app.config import get_settings
from app.services.nlp.text_utils import normalize_turkish_text


class TitleUnificationService:
    """Matches raw marketplace titles to unified catalog entries."""

    def __init__(self, threshold: float | None = None):
        settings = get_settings()
        self.threshold = threshold if threshold is not None else settings.nlp_similarity_threshold
        self._vectorizer = TfidfVectorizer(analyzer="word", ngram_range=(1, 2))

    @staticmethod
    def cosine_similarity(vec_a: list[float], vec_b: list[float]) -> float:
        """Compute cosine similarity between two dense vectors.

        Args:
            vec_a: First embedding vector.
            vec_b: Second embedding vector.

        Returns:
            float: Similarity score in [0, 1].
        """
        dot = sum(a * b for a, b in zip(vec_a, vec_b))
        norm_a = math.sqrt(sum(a * a for a in vec_a))
        norm_b = math.sqrt(sum(b * b for b in vec_b))
        if norm_a == 0 or norm_b == 0:
            return 0.0
        return dot / (norm_a * norm_b)

    def _embed_titles(self, titles: Iterable[str]) -> list[list[float]]:
        """Convert normalized titles into TF-IDF sentence embedding vectors."""
        cleaned = [normalize_turkish_text(t) for t in titles]
        matrix = self._vectorizer.fit_transform(cleaned)
        return matrix.toarray().tolist()

    def find_best_match(
        self,
        raw_title: str,
        candidate_titles: list[str],
    ) -> tuple[str | None, float]:
        """Find the best unified title match for a raw marketplace listing.

        Args:
            raw_title: Unprocessed title from Trendyol or another platform.
            candidate_titles: Known unified catalog titles to compare against.

        Returns:
            tuple: (matched_title or None, highest_similarity_score)
        """
        if not candidate_titles:
            return None, 0.0

        all_titles = [raw_title, *candidate_titles]
        embeddings = self._embed_titles(all_titles)
        query_vec = embeddings[0]

        best_title: str | None = None
        best_score = 0.0

        # Compare query embedding against each candidate embedding
        for idx, candidate in enumerate(candidate_titles, start=1):
            score = self.cosine_similarity(query_vec, embeddings[idx])
            if score > best_score:
                best_score = score
                best_title = candidate

        if best_score >= self.threshold:
            return best_title, best_score
        return None, best_score
