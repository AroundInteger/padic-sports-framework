"""p-adic clustering: distance computation, agglomerative clustering, and
prime / k sweep.

Canonical distance is D3 (FOUNDATION.md §1.2): for addresses in
most-significant-first order,

  d = 0                 if the digit strings agree
  d = p ** (-k*)        if k* is the first position at which they disagree

Dimension order (descending I(X;Y), or the MATLAB schedule on the audit
path) does the weighting. Weights are **not** used as exponents: lex-rescaled
I(X;Y) of order 10^3 makes p**(-w_k) underflow to 0.

The MATLAB headline silhouette 0.7083 used D2 (valuation on weighted
features, with a >= 10 000 → distance 1 patch). That path lives in
legacy_d2.py and must not be mixed into this module.
"""

from __future__ import annotations

import numpy as np
from dataclasses import dataclass
from itertools import product
from scipy.cluster.hierarchy import linkage, fcluster
from scipy.spatial.distance import squareform
from sklearn.metrics import silhouette_score, davies_bouldin_score, calinski_harabasz_score

from .encode import Encoding


# ---------- distance ----------

def padic_distance_matrix(enc: Encoding, p: int) -> np.ndarray:
    """Compute the n x n p-adic distance matrix for an Encoding.

    For each pair (i, j), find the highest-weight digit where they differ;
    distance = p^(-weight). If they agree on every digit, distance = 0.
    """
    digits = enc.digits
    weights = enc.weights
    n, K = digits.shape

    # disagreement matrix per digit: shape (K, n, n), boolean
    # then for each (i, j), find argmax of weight where disagreement is true
    # Standard p-adic distance: |x - y|_p = p^(-v(x - y)) where v is the
    # valuation = position of first disagreement (most-significant first).
    # Dimension ordering (descending I(X;Y) from build_encoding) does the
    # weighting work; the per-position weights array is preserved for
    # diagnostics but not used as an exponent (which would underflow when
    # weights are large after lex rescaling).
    _ = weights  # retained on the Encoding for downstream diagnostics
    D = np.full((n, n), 1.0, dtype=float)  # default to max distance for distinct points
    found = np.zeros((n, n), dtype=bool)
    for k in range(K):
        diff = digits[:, k][:, None] != digits[:, k][None, :]
        update = diff & ~found
        # Disagreement first observed at position k -> valuation k -> distance p^(-k).
        D[update] = float(p) ** (-k)
        found |= diff

    # Pairs that agreed everywhere have distance 0.
    D[~found] = 0.0
    np.fill_diagonal(D, 0.0)
    return D


# ---------- clustering ----------

@dataclass
class ClusterResult:
    p: int
    k: int
    labels: np.ndarray
    silhouette: float
    davies_bouldin: float
    calinski_harabasz: float
    distance_matrix: np.ndarray  # cached for downstream validation
    linkage_method: str = "single"


SUPPORTED_LINKAGES = ("single", "complete", "average")


def cluster_padic(
    enc: Encoding, p: int, k: int, linkage_method: str = "single"
) -> ClusterResult:
    """Run agglomerative clustering on p-adic distance.

    Single linkage preserves the ultrametric and is the canonical choice for
    p-adic clustering, but on highly-tied distance matrices (which occur at
    high p or high k) it can chain and collapse to a single label. Complete
    and average linkage are robust alternatives; the protocol sweeps over all
    three and selects the best by silhouette.
    """
    if linkage_method not in SUPPORTED_LINKAGES:
        raise ValueError(
            f"linkage_method must be one of {SUPPORTED_LINKAGES}; "
            f"got {linkage_method!r}"
        )
    D = padic_distance_matrix(enc, p)
    if D.max() == 0.0:
        # all entities have identical encoding; degenerate
        labels = np.zeros(len(D), dtype=int)
        return ClusterResult(p=p, k=1, labels=labels, silhouette=0.0,
                             davies_bouldin=float("nan"),
                             calinski_harabasz=float("nan"),
                             linkage_method=linkage_method,
                             distance_matrix=D)

    cond = squareform(D, checks=False)
    Z = linkage(cond, method=linkage_method)
    labels = fcluster(Z, t=k, criterion="maxclust") - 1  # zero-indexed

    # Need at least 2 distinct labels for silhouette; pad metrics with NaN if not.
    n_labels = len(np.unique(labels))
    if n_labels < 2:
        return ClusterResult(p=p, k=k, labels=labels, silhouette=0.0,
                             davies_bouldin=float("nan"),
                             calinski_harabasz=float("nan"),
                             linkage_method=linkage_method,
                             distance_matrix=D)

    sil = float(silhouette_score(D, labels, metric="precomputed"))

    # DB and CH are defined on Euclidean features, so use the digit matrix as
    # the underlying continuous representation for those (consistent with the
    # baseline comparisons in the protocol).
    feats = enc.digits.astype(float) * enc.weights[None, :]
    try:
        db = float(davies_bouldin_score(feats, labels))
    except ValueError:
        db = float("nan")
    try:
        ch = float(calinski_harabasz_score(feats, labels))
    except ValueError:
        ch = float("nan")

    return ClusterResult(
        p=p, k=k, labels=labels, silhouette=sil,
        davies_bouldin=db, calinski_harabasz=ch,
        linkage_method=linkage_method, distance_matrix=D,
    )


# ---------- sweep ----------

def sweep(
    enc: Encoding,
    primes: list[int] = (2, 3, 5, 7, 11, 13),
    ks: list[int] = tuple(range(2, 16)),
    linkages: list[str] = SUPPORTED_LINKAGES,
) -> list[ClusterResult]:
    """Sweep over primes p, cluster counts k, and linkage methods; return
    all results sorted by silhouette descending. Default sweep covers
    {single, complete, average} linkage per the protocol's sensitivity plan.
    """
    out = []
    for p, k, link in product(primes, ks, linkages):
        try:
            out.append(cluster_padic(enc, p, k, linkage_method=link))
        except Exception:
            continue
    out.sort(key=lambda r: (np.isnan(r.silhouette), -r.silhouette))
    return out


def best(results: list[ClusterResult]) -> ClusterResult:
    """Return the best clustering by silhouette."""
    valid = [r for r in results if not np.isnan(r.silhouette)]
    if not valid:
        raise RuntimeError("no valid clustering results")
    return max(valid, key=lambda r: r.silhouette)
