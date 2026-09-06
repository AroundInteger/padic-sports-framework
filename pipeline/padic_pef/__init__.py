"""padic_pef — PEF + p-adic clustering pipeline.

Implements the analytical recipe from the methodology note:
PEF estimation -> quadrant assignment -> abs/rel decision -> p-adic encoding
-> p-adic clustering -> validation.
"""

from . import ingest, pef, encode, cluster, validate, pipeline, legacy_d2, dominion, erode

__version__ = "0.1.0"
__all__ = [
    "ingest",
    "pef",
    "encode",
    "cluster",
    "validate",
    "pipeline",
    "legacy_d2",
    "dominion",
    "erode",
]
