"""Hierarchical Dominion: a sport-agnostic planted contest.

Sixteen entities, four ranks of four, addresses

    (rank, doctrine, organisation, endowment)  each in {0, 1, 2, 3}

Most-significant digit is rank. Distance is D3 (cluster.padic_distance_matrix).
This module must not import rugby data or legacy_d2.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from sklearn.metrics import adjusted_rand_score

from .cluster import cluster_padic
from .encode import Encoding

LEVELS = ("rank", "doctrine", "organisation", "endowment")
N_RANKS = 4
N_PER_RANK = 4
N_ENTITIES = N_RANKS * N_PER_RANK
BINS = 4
DEFAULT_P = 2
DEFAULT_LINKAGE = "complete"


def plant(n_ranks: int = N_RANKS, n_per_rank: int = N_PER_RANK) -> np.ndarray:
    """Return an (N, 4) integer address matrix.

    Within each rank r, slot s = 0..3:
        rank          = r
        doctrine      = s // 2          in {0, 1}
        organisation  = s % 2           in {0, 1}
        endowment     = s               in {0, 1, 2, 3}
    So rank is the unique four-way partition; (rank, doctrine) is eight
    pairs; the finest two digits distinguish the four slots inside a rank.
    """
    rows = []
    for r in range(n_ranks):
        for s in range(n_per_rank):
            rows.append([r, s // 2, s % 2, s])
    return np.asarray(rows, dtype=int)


def entity_ids(n_ranks: int = N_RANKS, n_per_rank: int = N_PER_RANK) -> list[str]:
    return [f"E{r}{s}" for r in range(n_ranks) for s in range(n_per_rank)]


def as_encoding(
    digits: np.ndarray,
    ids: list[str] | None = None,
) -> Encoding:
    digits = np.asarray(digits, dtype=int)
    n, k = digits.shape
    ids = ids if ids is not None else [f"E{i:02d}" for i in range(n)]
    # Weights are unused by D3; kept positive for Encoding validity.
    weights = np.array([float(k - i) for i in range(k)], dtype=float)
    return Encoding(
        entity_ids=ids,
        digits=digits,
        weights=weights,
        bins=BINS,
        metric_order=list(LEVELS[:k]),
        feature_choice=["abs"] * k,
    )


def planted_ranks(digits: np.ndarray) -> np.ndarray:
    return np.asarray(digits)[:, 0]


# Nested cuts matched to planted levels. k=2 is a design lock: rank is already
# the coarsest planted digit, so "coarse rank" is r // 2, not a fifth digit.
NESTED_CUTS = (2, 4, 8)
COARSE_RANK_LOCK = "k=2 scored against r // 2 (not a planted digit)"


def nested_cut_labels(digits: np.ndarray, k: int) -> np.ndarray:
    """Labels for a nested planted cut of a 4-d address matrix.

    k=2: coarse rank ``r // 2`` (design lock).
    k=4: planted rank.
    k=8: (rank, doctrine). On the plant, doctrine is in {0, 1}.
    """
    digits = np.asarray(digits)
    rank = digits[:, 0].astype(int)
    doctrine = digits[:, 1].astype(int)
    if k == 2:
        return rank // 2
    if k == 4:
        return rank
    if k == 8:
        return rank * 2 + doctrine
    raise ValueError(f"nested cut k must be one of {NESTED_CUTS}; got {k}")


def planted_nested_labels(k: int) -> np.ndarray:
    return nested_cut_labels(plant(), k)


def first_disagreement_index(a: np.ndarray, b: np.ndarray) -> int:
    """Position of first mismatch, or K if the addresses agree."""
    for k, (x, y) in enumerate(zip(a, b)):
        if x != y:
            return k
    return len(a)


def first_disagreement_share(digits: np.ndarray) -> np.ndarray:
    """Share of unordered pairs whose first disagreement is at each depth.

    Length K+1: indices 0..K-1 are disagreement depths; index K is agreement.
    """
    digits = np.asarray(digits)
    n, k = digits.shape
    counts = np.zeros(k + 1, dtype=float)
    for i in range(n):
        for j in range(i + 1, n):
            counts[first_disagreement_index(digits[i], digits[j])] += 1
    total = counts.sum()
    if total == 0:
        return counts
    return counts / total


@dataclass
class ConstructionCheck:
    silhouette: float
    n_labels: int
    rank_ari: float
    rank_purity: float
    first_disagree_share: np.ndarray
    labels: np.ndarray


def rank_purity(labels: np.ndarray, ranks: np.ndarray) -> float:
    """Mean, over clusters, of the majority-rank fraction."""
    labels = np.asarray(labels)
    ranks = np.asarray(ranks)
    scores = []
    for lab in np.unique(labels):
        block = ranks[labels == lab]
        if len(block) == 0:
            continue
        majority = np.bincount(block).max()
        scores.append(majority / len(block))
    return float(np.mean(scores)) if scores else 0.0


def construction_check(
    digits: np.ndarray | None = None,
    *,
    p: int = DEFAULT_P,
    linkage_method: str = DEFAULT_LINKAGE,
    k: int = N_RANKS,
    ground_truth_ranks: np.ndarray | None = None,
) -> ConstructionCheck:
    """Cluster at k = n_ranks and score recovery of planted rank.

    ``ground_truth_ranks`` should be the *original* planted rank column when
    testing erosion (E4/E5). If omitted, rank is taken from ``digits[:, 0]``.
    """
    planted = plant() if digits is None else np.asarray(digits, dtype=int)
    ids = entity_ids()
    enc = as_encoding(planted, ids)
    result = cluster_padic(enc, p=p, k=k, linkage_method=linkage_method)
    ranks = (
        np.asarray(ground_truth_ranks, dtype=int)
        if ground_truth_ranks is not None
        else planted_ranks(planted)
    )
    n_lab = int(len(np.unique(result.labels)))
    ari = (
        float(adjusted_rand_score(ranks, result.labels))
        if n_lab >= 2
        else 0.0
    )
    return ConstructionCheck(
        silhouette=float(result.silhouette),
        n_labels=n_lab,
        rank_ari=ari,
        rank_purity=rank_purity(result.labels, ranks),
        first_disagree_share=first_disagreement_share(planted),
        labels=result.labels,
    )


def per_digit_match(planted: np.ndarray, observed: np.ndarray) -> np.ndarray:
    """Fraction of entities whose digit k still equals the planted value."""
    planted = np.asarray(planted)
    observed = np.asarray(observed)
    return (planted == observed).mean(axis=0)
