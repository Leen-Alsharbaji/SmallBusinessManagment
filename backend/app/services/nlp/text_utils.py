"""
Text normalization utilities for the NLP Title Unification Engine.

These pure functions have no I/O side effects and are shared by the sync
service when preparing marketplace titles for embedding comparison.
"""

import re
import unicodedata


def normalize_turkish_text(text: str) -> str:
    """Normalize product titles for consistent embedding comparison.

    Steps:
        1. Unicode NFKD decomposition (handles Turkish special chars consistently)
        2. Lowercasing
        3. Punctuation and symbol stripping
        4. Whitespace collapse

    Args:
        text: Raw marketplace or catalog product title.

    Returns:
        str: Cleaned, lowercase title suitable for embedding input.
    """
    if not text:
        return ""

    # Normalize unicode (e.g. dotted İ / ı variants)
    normalized = unicodedata.normalize("NFKD", text)
    normalized = normalized.encode("ascii", "ignore").decode("ascii")

    normalized = normalized.lower()

    # Strip punctuation while preserving alphanumeric and spaces
    normalized = re.sub(r"[^\w\s]", " ", normalized, flags=re.UNICODE)

    # Collapse repeated whitespace
    normalized = re.sub(r"\s+", " ", normalized).strip()
    return normalized
