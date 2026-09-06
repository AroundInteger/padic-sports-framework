"""MATLAB-faithful 7-d rugby encoding and D2 distance (FOUNDATION ruling R6).

This module is the audit path for silhouette 0.7083. It does **not** implement
PEF, D3, or information-content weights. Those live in encode.py / cluster.py
and must not be mixed into this file.

Source of truth: ``enhanced_padic_rugby_pipeline.m`` (and the identical
feature construction in ``phase_1_validation_suite_CORRECTED.m``).

D2: for each pair, take componentwise |f_i - f_j|; if a component difference
is >= 10 000, that component's distance is 1 (performance-tier patch);
otherwise distance is p^{-v_p(round(|diff|))}. Pair distance is the max
across components (ultrametric). Linkage is complete. Silhouette is the mean
Rousseeuw score on the precomputed D2 matrix.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.cluster.hierarchy import fcluster, linkage
from scipy.spatial.distance import squareform
from sklearn.metrics import silhouette_score

from .ingest import DEFAULT_RUGBY_CSV, load_rugby_matches

DIMENSION_NAMES = (
    "Performance_Tier",
    "Attacking_Style",
    "Breakdown_Mastery",
    "Territory_Control",
    "Penetration_Ability",
    "Discipline",
    "Set_Piece_Platform",
)

# Exponential schedule from enhanced_padic_rugby_pipeline.m
WEIGHTS = np.array([10_000, 100, 50, 25, 12, 6, 3], dtype=float)

TIER_LABELS = ("Developing", "Competitive", "Strong", "Elite")
ATTACK_LABELS = ("Back-dominant", "Balanced back", "Balanced forward", "Forward-dominant")
BREAKDOWN_LABELS = ("Struggling", "Competitive", "Strong", "Dominant")
TERRITORY_LABELS = ("Minimal kicking", "Low kicking", "Moderate kicking", "High kicking")
PENETRATION_LABELS = ("Poor", "Average", "Good", "Elite")
DISCIPLINE_LABELS = ("Undisciplined", "Average", "Disciplined", "Very disciplined")
SET_PIECE_LABELS = ("Weak", "Average", "Good", "Strong")


def _matlab_mean(values: np.ndarray) -> float:
    """MATLAB ``mean`` on a double vector: NaNs are *not* skipped."""
    return float(np.mean(np.asarray(values, dtype=float)))


def _digit_from_thresholds(value: float, cuts: tuple[float, float, float], *, higher_is_better: bool) -> int:
    """Map a scalar to a MATLAB digit in {1, 2, 3, 4}.

    ``cuts`` are the three thresholds in the same order as the MATLAB
    if/elseif chain. NaN fails every comparison and lands on digit 1,
    matching MATLAB (NaN > x is false).
    """
    if higher_is_better:
        hi, mid, lo = cuts
        if value > hi:
            return 4
        if value > mid:
            return 3
        if value > lo:
            return 2
        return 1
    # Discipline: lower penalties are better; MATLAB uses < not >
    lo, mid, hi = cuts
    if value < lo:
        return 4
    if value < mid:
        return 3
    if value < hi:
        return 2
    return 1


def encode_team(matches: pd.DataFrame) -> tuple[np.ndarray, dict[str, float]]:
    """Encode one team's match table to the 7-d weighted MATLAB vector.

    Returns (weighted_features, raw_scalars used for the binning).
    """
    points = _matlab_mean(matches["final_points_relative"].to_numpy())
    carries = _matlab_mean(matches["abs_carries"].to_numpy())
    passes = _matlab_mean(matches["abs_passes"].to_numpy())
    carry_pass_ratio = carries / (passes + 1.0)
    turnover_diff = _matlab_mean(
        matches["rel_turnovers_won"].to_numpy() - matches["rel_turnovers_conceded"].to_numpy()
    )
    kicks = _matlab_mean(matches["abs_kicks_from_hand"].to_numpy())
    clean_breaks = _matlab_mean(matches["rel_clean_breaks"].to_numpy())
    penalties = _matlab_mean(matches["rel_penalties_conceded"].to_numpy())
    set_piece = _matlab_mean(matches["abs_scrums_won"].to_numpy()) + _matlab_mean(
        matches["abs_lineout_throws_won"].to_numpy()
    )

    digits = np.array(
        [
            _digit_from_thresholds(points, (10.0, 2.0, -5.0), higher_is_better=True),
            _digit_from_thresholds(carry_pass_ratio, (0.8, 0.6, 0.4), higher_is_better=True),
            _digit_from_thresholds(turnover_diff, (2.0, 0.0, -2.0), higher_is_better=True),
            _digit_from_thresholds(kicks, (20.0, 15.0, 10.0), higher_is_better=True),
            _digit_from_thresholds(clean_breaks, (2.0, 0.0, -1.0), higher_is_better=True),
            _digit_from_thresholds(penalties, (-2.0, 0.0, 2.0), higher_is_better=False),
            _digit_from_thresholds(set_piece, (25.0, 20.0, 15.0), higher_is_better=True),
        ],
        dtype=int,
    )
    raw = {
        "final_points_relative": points,
        "carry_pass_ratio": carry_pass_ratio,
        "turnover_differential": turnover_diff,
        "abs_kicks_from_hand": kicks,
        "rel_clean_breaks": clean_breaks,
        "rel_penalties_conceded": penalties,
        "set_piece_total": set_piece,
    }
    return digits.astype(float) * WEIGHTS, raw


@dataclass
class MatlabRugbyEncoding:
    """Team-level MATLAB encoding of the rugby panel."""

    teams: list[str]
    digits: np.ndarray  # (N, 7) in {1, 2, 3, 4}
    features: np.ndarray  # (N, 7) digits * WEIGHTS
    raw: pd.DataFrame
    n_matches: int
    n_seasons: int
    seasons: list[str]
    csv_path: Path
    weights: np.ndarray = field(default_factory=lambda: WEIGHTS.copy())
    dimension_names: tuple[str, ...] = DIMENSION_NAMES

    def as_frame(self) -> pd.DataFrame:
        cols = {name: self.features[:, i] for i, name in enumerate(self.dimension_names)}
        digit_cols = {f"digit_{name}": self.digits[:, i] for i, name in enumerate(self.dimension_names)}
        return pd.DataFrame({"team": self.teams, **cols, **digit_cols})


def encode_matlab_7d(
    csv_path: str | Path | None = None,
    *,
    team_order: str = "matlab_unique",
) -> MatlabRugbyEncoding:
    """Build the 16 x 7 MATLAB feature matrix.

    ``team_order``:
      - ``matlab_unique``: alphabetical, matching MATLAB ``unique(team)``
      - ``first_appearance``: order of first row in the CSV
    """
    path = Path(csv_path) if csv_path is not None else DEFAULT_RUGBY_CSV
    matches = load_rugby_matches(path)
    if team_order == "matlab_unique":
        teams = sorted(matches["team"].unique().tolist())
    elif team_order == "first_appearance":
        teams = matches["team"].drop_duplicates().tolist()
    else:
        raise ValueError(f"unknown team_order: {team_order!r}")

    features = np.zeros((len(teams), 7), dtype=float)
    digits = np.zeros((len(teams), 7), dtype=int)
    raw_rows = []
    for i, team in enumerate(teams):
        block = matches.loc[matches["team"] == team]
        weighted, raw = encode_team(block)
        features[i] = weighted
        digits[i] = np.rint(weighted / WEIGHTS).astype(int)
        raw_rows.append({"team": team, **raw, "n_matches": int(len(block))})

    seasons = sorted(matches["season"].astype(str).unique().tolist())
    return MatlabRugbyEncoding(
        teams=teams,
        digits=digits,
        features=features,
        raw=pd.DataFrame(raw_rows),
        n_matches=len(matches),
        n_seasons=len(seasons),
        seasons=seasons,
        csv_path=path,
    )


def padic_valuation_d2(n: float, p: int) -> float:
    """Component distance under D2.

    Difference >= 10 000 → distance 1 (valuation 0). Zero → 0.
    Otherwise p^{-v_p(round(|n|))}.
    """
    if n == 0:
        return 0.0
    n_abs = abs(n)
    if n_abs >= 10_000:
        return 1.0
    n_val = int(abs(round(n_abs)))
    if n_val == 0:
        return 0.0
    valuation = 0
    while n_val % p == 0 and n_val > 0:
        n_val //= p
        valuation += 1
    return float(p) ** (-valuation)


def distance_matrix_d2(features: np.ndarray, p: int) -> np.ndarray:
    """n x n D2 matrix. Symmetric, zero diagonal."""
    n = features.shape[0]
    D = np.zeros((n, n), dtype=float)
    for i in range(n):
        for j in range(i + 1, n):
            diff = np.abs(features[i] - features[j])
            component = [padic_valuation_d2(d, p) for d in diff]
            d = max(component) if component else 0.0
            D[i, j] = d
            D[j, i] = d
    return D


@dataclass
class D2ClusterResult:
    p: int
    k: int
    labels: np.ndarray  # 1-indexed, MATLAB-style
    silhouette: float
    distance_matrix: np.ndarray
    linkage_method: str = "complete"
    n_labels: int = 0


def cluster_d2(
    features: np.ndarray,
    p: int,
    k: int,
    *,
    linkage_method: str = "complete",
) -> D2ClusterResult:
    """Complete-linkage maxclust cut on D2, matching the MATLAB headline run."""
    D = distance_matrix_d2(features, p)
    if D.max() == 0.0:
        labels = np.ones(len(D), dtype=int)
        return D2ClusterResult(
            p=p, k=1, labels=labels, silhouette=0.0, distance_matrix=D, n_labels=1
        )

    condensed = squareform(D, checks=False)
    Z = linkage(condensed, method=linkage_method)
    labels = fcluster(Z, t=k, criterion="maxclust")
    n_labels = int(len(np.unique(labels)))
    if n_labels < 2:
        sil = 0.0
    else:
        sil = float(silhouette_score(D, labels, metric="precomputed"))
    return D2ClusterResult(
        p=p,
        k=k,
        labels=labels,
        silhouette=sil,
        distance_matrix=D,
        linkage_method=linkage_method,
        n_labels=n_labels,
    )


def sweep_d2(
    features: np.ndarray,
    *,
    primes: tuple[int, ...] = (2, 3, 5, 7),
    ks: tuple[int, ...] = (2, 3, 4, 5, 6),
    linkage_method: str = "complete",
) -> list[D2ClusterResult]:
    """Prime / k sweep as in ``enhanced_padic_rugby_pipeline.m`` (k = 2..6)."""
    out: list[D2ClusterResult] = []
    n = features.shape[0]
    for p in primes:
        for k in ks:
            if k >= n:
                continue
            out.append(cluster_d2(features, p, k, linkage_method=linkage_method))
    out.sort(key=lambda r: r.silhouette, reverse=True)
    return out


def best_d2(results: list[D2ClusterResult]) -> D2ClusterResult:
    if not results:
        raise RuntimeError("no D2 clustering results")
    return max(results, key=lambda r: r.silhouette)


def ablation_features(features: np.ndarray, mode: str) -> np.ndarray:
    """Reproduce the Phase 2 ablation constructions.

    ``only_performance`` / ``no_performance`` follow ``phase_2_ablation.m``:
    held-out columns are replaced by the column-wise median, not dropped,
    so the weight schedule and D2 special case still apply.
    """
    F = np.array(features, dtype=float, copy=True)
    if mode == "full":
        return F
    if mode == "no_performance":
        F[:, 0] = np.median(F[:, 0])
        return F
    if mode == "only_performance":
        for j in range(1, 7):
            F[:, j] = np.median(F[:, j])
        return F
    if mode == "only_tactical":
        # digits 2-4 (1-based) kept; 1 and 5-7 median-filled
        for j in (0, 4, 5, 6):
            F[:, j] = np.median(F[:, j])
        return F
    if mode == "only_physical":
        for j in range(0, 4):
            F[:, j] = np.median(F[:, j])
        return F
    if mode == "no_weights":
        digits = np.rint(F / WEIGHTS)
        return digits
    if mode.startswith("drop_"):
        idx = {
            "drop_attack": 1,
            "drop_breakdown": 2,
            "drop_territory": 3,
            "drop_penetration": 4,
            "drop_discipline": 5,
            "drop_set_piece": 6,
        }[mode]
        F[:, idx] = np.median(F[:, idx])
        return F
    raise ValueError(f"unknown ablation mode: {mode!r}")


def cluster_labels_by_team(enc: MatlabRugbyEncoding, result: D2ClusterResult) -> dict[int, list[str]]:
    groups: dict[int, list[str]] = {}
    for team, lab in zip(enc.teams, result.labels):
        groups.setdefault(int(lab), []).append(team)
    return dict(sorted(groups.items()))
