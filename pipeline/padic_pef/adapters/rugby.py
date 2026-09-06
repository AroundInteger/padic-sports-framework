"""URC rugby adapter: one empirical reading of Dominion's four slots.

The declared map (identity on the four source digits) is

    rank          ← performance-tier digit
    doctrine      ← attacking-style digit
    organisation  ← breakdown digit
    endowment     ← set-piece digit

This is a declared reading of URC, not a claim that rank *is* points-difference.
Q5 asks the 24 permutations of those four digits onto the four slots.
"""

from __future__ import annotations

from itertools import permutations
from pathlib import Path

import numpy as np

from ..dominion import LEVELS, as_encoding
from ..encode import Encoding
from ..legacy_d2 import encode_matlab_7d


# MATLAB 7-d columns in source order (not slot order).
SOURCE_NAMES = ("performance", "attack", "breakdown", "set_piece")
SOURCE_MATLAB_COLS = (0, 1, 2, 6)
# perm[slot] = source index. Identity is the declared reading.
DECLARED_PERM = (0, 1, 2, 3)


def source_digit_matrix(
    csv_path: str | Path | None = None,
) -> tuple[list[str], np.ndarray]:
    """Return (team names, 16 × 4 digits) in source order, not yet mapped."""
    enc = encode_matlab_7d(csv_path)
    four = enc.digits[:, list(SOURCE_MATLAB_COLS)] - 1
    if four.min() < 0 or four.max() > 3:
        raise ValueError(
            f"adapter digits out of range: min={four.min()} max={four.max()}"
        )
    return enc.teams, four.astype(int)


def slot_permutations() -> list[tuple[int, int, int, int]]:
    """All 24 assignments of the four source digits onto Dominion slots."""
    return [tuple(p) for p in permutations(range(4))]


def map_digits(source: np.ndarray, perm: tuple[int, ...]) -> np.ndarray:
    """``perm[slot]`` is the source index placed in that Dominion slot."""
    return np.asarray(source)[:, list(perm)]


def describe_perm(perm: tuple[int, ...]) -> str:
    return "; ".join(
        f"{LEVELS[slot]}←{SOURCE_NAMES[perm[slot]]}" for slot in range(4)
    )


def performance_occupies_rank(perm: tuple[int, ...]) -> bool:
    return SOURCE_NAMES[perm[0]] == "performance"


def constant_source_slots(source: np.ndarray, perm: tuple[int, ...]) -> list[int]:
    """Slot indices whose mapped digit is constant across entities."""
    mapped = map_digits(source, perm)
    return [j for j in range(mapped.shape[1]) if int(np.unique(mapped[:, j]).size) == 1]


def to_dominion_digits(
    csv_path: str | Path | None = None,
    perm: tuple[int, ...] = DECLARED_PERM,
) -> tuple[list[str], np.ndarray]:
    """Return (team names, 16 × 4 digits in {0,1,2,3}) under ``perm``."""
    teams, source = source_digit_matrix(csv_path)
    return teams, map_digits(source, perm)


def to_encoding(
    csv_path: str | Path | None = None,
    perm: tuple[int, ...] = DECLARED_PERM,
) -> Encoding:
    teams, digits = to_dominion_digits(csv_path, perm=perm)
    enc = as_encoding(digits, teams)
    enc.metric_order = list(LEVELS)
    enc.feature_choice = ["rel", "abs", "rel", "abs"]
    return enc


def endowment_is_constant(digits: np.ndarray) -> bool:
    return int(np.unique(digits[:, 3]).size) == 1
