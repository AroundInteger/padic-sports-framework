"""p-adic encoding: quadrant-aware abs/rel choice and information-content
weighted base-p digit encoding.

Given a table of per-metric PEF records and a feature matrix, this module
produces a dictionary {entity_id: digit_string} where each digit is in
{0, ..., bins - 1} and dimensions are ordered by descending I(X;Y).
"""

from __future__ import annotations

import numpy as np
import pandas as pd
from dataclasses import dataclass


# ---------- abs / rel decision rule ----------

def feature_decision(
    quadrant: str,
    mi_rel: float | None = None,
    mi_abs: float | None = None,
) -> str:
    """Per-metric abs/rel choice from PEF quadrant.

    Q1, Q2 -> 'rel'
    Q3     -> 'abs'
    Q4     -> 'rel' if I(X;Y)_rel > I(X;Y)_abs else 'abs'
    """
    if quadrant in ("Q1", "Q2"):
        return "rel"
    if quadrant == "Q3":
        return "abs"
    # Q4
    if mi_rel is not None and mi_abs is not None:
        return "rel" if mi_rel > mi_abs else "abs"
    return "rel"  # default in absence of info, conservative


# ---------- categorisation ----------

def quantile_bin(values: np.ndarray, bins: int) -> np.ndarray:
    """Equal-frequency bin a 1D array into {0, ..., bins-1}.

    Uses pandas qcut with duplicate-edge handling for ties.
    """
    if bins < 2:
        raise ValueError("bins must be >= 2")
    s = pd.Series(values)
    digits, _ = pd.qcut(s, q=bins, labels=False, retbins=True, duplicates="drop")
    # qcut may return fewer bins than requested if duplicates collapse; rebin
    # safely by ranking when that happens.
    if digits.nunique() < bins:
        ranks = s.rank(method="average").to_numpy()
        digits = np.floor((ranks - 1) / len(values) * bins).astype(int)
        digits = np.clip(digits, 0, bins - 1)
    return np.asarray(digits.fillna(0).astype(int)) if hasattr(digits, "fillna") else np.asarray(digits, dtype=int)


# ---------- weight schedule ----------

def lex_rescale(weights: np.ndarray, max_digit: int) -> np.ndarray:
    """Rescale weights so that w_k > sum_{j>k} w_j * max_digit, ensuring
    lexicographic dominance of higher-significance dimensions.

    Weights are assumed to come in *significance order* (most significant first).
    """
    weights = np.asarray(weights, dtype=float)
    if (weights <= 0).any():
        raise ValueError("weights must be positive")
    K = len(weights)
    out = np.empty(K, dtype=float)
    out[K - 1] = weights[K - 1]
    for k in range(K - 2, -1, -1):
        floor = (out[k + 1:].sum() * max_digit) * 1.0001  # tiny margin
        out[k] = max(weights[k], floor)
    # Normalise so the smallest is 1
    out = out / out[-1]
    return out


# ---------- main encoding ----------

@dataclass
class Encoding:
    entity_ids: list
    digits: np.ndarray         # shape (n_entities, K), values in {0, ..., bins-1}
    weights: np.ndarray        # shape (K,), one per digit
    bins: int
    metric_order: list[str]    # ordered descending by I(X; Y)
    feature_choice: list[str]  # 'abs' or 'rel' per metric, in metric_order


def build_encoding(
    df: pd.DataFrame,
    pef_table: pd.DataFrame,
    *,
    metrics: list[str],
    entity_col: str,
    bins: int = 4,
    rescale: bool = True,
) -> Encoding:
    """Build the p-adic encoding for the given pilot.

    Args:
        df: entity-level DataFrame with one row per entity, columns per metric.
            For relative features, must include corresponding `_rel` columns;
            for absolute features, the metric column itself is used.
        pef_table: output of pef.estimate_pef_table — used to derive the
            quadrant, abs/rel choice, and I(X;Y) per metric.
        metrics: list of metric names to encode.
        entity_col: name of the entity identifier column in df.
        bins: number of bins per dimension (typically a power of 2).
        rescale: apply lexicographic rescaling to the weights.

    Returns:
        Encoding object containing the full digit matrix, weights, and metadata.
    """
    # Use the within-group pairing record per metric to derive quadrant + I(X;Y).
    within_records = pef_table[pef_table["pairing"].str.startswith("within_")].set_index("metric")
    if not set(metrics).issubset(within_records.index):
        missing = set(metrics) - set(within_records.index)
        raise KeyError(f"PEF records missing for metrics: {missing}")

    # Order metrics by descending I(X;Y).
    ordered = (
        within_records.loc[metrics]
        .sort_values("mutual_information", ascending=False)
        .index.tolist()
    )

    # Per-metric abs/rel choice and resulting feature column.
    feature_choice = []
    digit_cols = []
    for metric in ordered:
        q = within_records.loc[metric, "quadrant"]
        choice = feature_decision(q)
        feature_choice.append(choice)
        if choice == "rel":
            col = f"{metric}_rel"
            if col not in df.columns:
                raise KeyError(f"relative feature column missing: {col}")
            digit_cols.append(col)
        else:
            digit_cols.append(metric)

    # Categorise each chosen feature.
    n = len(df)
    K = len(ordered)
    digits = np.zeros((n, K), dtype=int)
    for k, col in enumerate(digit_cols):
        digits[:, k] = quantile_bin(df[col].to_numpy(), bins=bins)

    # Weights = I(X;Y), ordered by metric_order.
    raw_weights = within_records.loc[ordered, "mutual_information"].to_numpy().astype(float)
    raw_weights = np.where(raw_weights <= 0, 1e-6, raw_weights)
    weights = lex_rescale(raw_weights, max_digit=bins - 1) if rescale else raw_weights

    return Encoding(
        entity_ids=df[entity_col].tolist(),
        digits=digits,
        weights=weights,
        bins=bins,
        metric_order=ordered,
        feature_choice=feature_choice,
    )


# ---------- helper: project encoding to a base-p integer ----------

def encoding_to_integer(enc: Encoding, p: int) -> np.ndarray:
    """Convert digit matrix to a single integer per entity, using the
    given prime p as the base. Useful for diagnostics and quick equality checks.
    """
    n, K = enc.digits.shape
    out = np.zeros(n, dtype=np.int64)
    for k in range(K):
        out = out * p + enc.digits[:, k]
    return out
