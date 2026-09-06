"""Erosion operators on Hierarchical Dominion addresses.

Sport-agnostic: operates only on integer digit matrices. Intensities π in
[0, 1]. π = 0 is a no-op for every operator.
"""

from __future__ import annotations

import numpy as np

from .dominion import LEVELS

# Column index of each named level.
LEVEL_INDEX = {name: i for i, name in enumerate(LEVELS)}


def flip_digit(
    digits: np.ndarray,
    level: str,
    pi: float,
    rng: np.random.Generator,
    bins: int = 4,
) -> np.ndarray:
    """Independently recode ``level`` to a *different* digit with probability π."""
    if not 0.0 <= pi <= 1.0:
        raise ValueError("pi must be in [0, 1]")
    out = np.array(digits, dtype=int, copy=True)
    if pi == 0.0:
        return out
    col = LEVEL_INDEX[level]
    n = out.shape[0]
    hit = rng.random(n) < pi
    for i in np.where(hit)[0]:
        choices = [d for d in range(bins) if d != int(out[i, col])]
        out[i, col] = int(rng.choice(choices))
    return out


def jitter_and_round(
    digits: np.ndarray,
    pi: float,
    rng: np.random.Generator,
    bins: int = 4,
) -> np.ndarray:
    """Measurement noise: add N(0, π) to every digit and clip back to {0, …, bins-1}.

    π = 0 recovers the input. This is E5 (continuous / noise erosion) without
    quantile relabelling, which would permute labels even at zero noise when
    a digit is unbalanced.
    """
    if not 0.0 <= pi <= 1.0:
        raise ValueError("pi must be in [0, 1]")
    out = np.array(digits, dtype=float, copy=True)
    if pi > 0.0:
        out = out + rng.normal(0.0, pi, size=out.shape)
    return np.clip(np.rint(out), 0, bins - 1).astype(int)


def apply(
    digits: np.ndarray,
    stage: str,
    pi: float,
    rng: np.random.Generator,
    bins: int = 4,
) -> np.ndarray:
    """Dispatch one erosion stage.

    Stages: E0 identity; E1 endowment; E2 organisation; E3 doctrine;
    E4 rank; E5 jitter-and-round.
    """
    digits = np.asarray(digits, dtype=int)
    if stage == "E0":
        return np.array(digits, copy=True)
    if stage == "E1":
        return flip_digit(digits, "endowment", pi, rng, bins=bins)
    if stage == "E2":
        return flip_digit(digits, "organisation", pi, rng, bins=bins)
    if stage == "E3":
        return flip_digit(digits, "doctrine", pi, rng, bins=bins)
    if stage == "E4":
        return flip_digit(digits, "rank", pi, rng, bins=bins)
    if stage == "E5":
        return jitter_and_round(digits, pi, rng, bins=bins)
    raise ValueError(f"unknown erosion stage: {stage!r}")


STAGES = ("E0", "E1", "E2", "E3", "E4", "E5")
STAGE_LEVEL = {
    "E0": None,
    "E1": "endowment",
    "E2": "organisation",
    "E3": "doctrine",
    "E4": "rank",
    "E5": "jitter",
}
