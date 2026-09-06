"""PEF estimation: per-metric (kappa, rho, eta, I(X;Y)) and quadrant assignment.

Implements the formulae from the PEF paper and the methodology note:

  eta = (1 + kappa) / (1 + kappa - 2 * sqrt(kappa) * rho)
  I(X; Y) = 1 - H(Phi(delta / (2 sigma_A sqrt((1 + kappa) / eta))))

with H(p) = -p log2(p) - (1-p) log2(1-p) the binary entropy function and
Phi the standard normal CDF.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
from dataclasses import dataclass
from scipy.stats import norm


# ---------- core formulae ----------

def variance_ratio(x_a: np.ndarray, x_b: np.ndarray, *, ddof: int = 1) -> float:
    """Sample variance ratio kappa = Var(B) / Var(A)."""
    var_a = np.var(x_a, ddof=ddof)
    var_b = np.var(x_b, ddof=ddof)
    if var_a <= 0:
        raise ValueError("Var(A) must be positive")
    return float(var_b / var_a)


def correlation(x_a: np.ndarray, x_b: np.ndarray) -> float:
    """Pearson correlation rho between paired measurements."""
    if len(x_a) != len(x_b):
        raise ValueError("paired arrays must have equal length")
    if len(x_a) < 2:
        return 0.0
    return float(np.corrcoef(x_a, x_b)[0, 1])


def eta(kappa: float, rho: float) -> float:
    """Paired Efficiency Factor.

    eta = (1 + kappa) / (1 + kappa - 2 sqrt(kappa) rho)

    eta > 1: pairing reduces variance (rel preferred on efficiency grounds)
    eta = 1: Fisher baseline
    eta < 1: pairing increases variance (rel may still help via I(X;Y))
    """
    if kappa <= 0:
        raise ValueError("kappa must be positive")
    denom = 1.0 + kappa - 2.0 * np.sqrt(kappa) * rho
    if denom <= 0:
        # only possible if rho >= (1 + kappa) / (2 sqrt kappa); pathological
        return float("inf")
    return float((1.0 + kappa) / denom)


def binary_entropy(p: float) -> float:
    """Binary entropy H(p) = -p log2 p - (1-p) log2 (1-p), with H(0)=H(1)=0."""
    if p <= 0.0 or p >= 1.0:
        return 0.0
    return float(-p * np.log2(p) - (1.0 - p) * np.log2(1.0 - p))


def mutual_information_gaussian(
    delta: float, sigma_a: float, kappa: float, eta_value: float
) -> float:
    """I(X; Y) under PEF's bivariate-normal Gaussian-discriminant model.

    I(X; Y) = 1 - H( Phi( delta / (2 sigma_A sqrt((1 + kappa) / eta)) ) )

    where Y is a balanced binary outcome and Phi is the standard normal CDF.
    Returned in bits.
    """
    if sigma_a <= 0:
        raise ValueError("sigma_a must be positive")
    if eta_value <= 0:
        return 0.0
    snr = delta / (2.0 * sigma_a * np.sqrt((1.0 + kappa) / eta_value))
    p = float(norm.cdf(snr))
    return 1.0 - binary_entropy(p)


# ---------- summary record ----------

@dataclass
class PEFRecord:
    """Per-metric PEF result."""
    metric: str
    pairing: str           # e.g. "within_region" or "across_region"
    n_pairs: int
    sigma_a: float
    sigma_b: float
    kappa: float
    rho: float
    delta: float
    eta: float
    mutual_information: float
    quadrant: str          # "Q1", "Q2", "Q3", or "Q4"

    def to_dict(self) -> dict:
        return self.__dict__.copy()


def quadrant_of(kappa: float, rho: float) -> str:
    """Place (kappa, rho) in PEF quadrant.

    Q1: kappa > 1, rho > 0  (high eta, high I)
    Q2: kappa < 1, rho > 0  (high eta, moderate I)
    Q3: kappa < 1, rho < 0  (low eta, low I)
    Q4: kappa > 1, rho < 0  (low eta, variable I — efficiency-power tension)
    """
    if rho > 0:
        return "Q1" if kappa > 1.0 else "Q2"
    return "Q4" if kappa > 1.0 else "Q3"


# ---------- pairing schemes ----------

def make_pairs_within_group(
    df: pd.DataFrame,
    metric: str,
    group_col: str,
    entity_col: str,
) -> tuple[np.ndarray, np.ndarray]:
    """Generate paired arrays (A, B) by pairing each entity with the mean of
    its group on the same metric.

    For NHS-SOF: group_col = "region", entity_col = "trust" -> within-region pair.
    For WIMD: group_col = "local_authority", entity_col = "lsoa" -> within-LA pair.

    Returns:
        x_a: per-entity metric values
        x_b: corresponding group-mean metric values (excluding the entity itself)
    """
    if any(c not in df.columns for c in [metric, group_col, entity_col]):
        raise KeyError(f"missing columns; need {[metric, group_col, entity_col]}")

    x_a, x_b = [], []
    for _, sub in df.groupby(group_col, sort=False):
        if len(sub) < 2:
            continue
        values = sub[metric].to_numpy()
        for i in range(len(sub)):
            others = np.delete(values, i)
            x_a.append(values[i])
            x_b.append(float(np.mean(others)))
    return np.asarray(x_a), np.asarray(x_b)


def make_pairs_across_group(
    df: pd.DataFrame,
    metric: str,
    group_col: str,
    *,
    rng: np.random.Generator | None = None,
    n_samples: int | None = None,
) -> tuple[np.ndarray, np.ndarray]:
    """Generate paired arrays by sampling pairs of entities from *different*
    groups. Used as the across-region / across-LA pairing scheme.
    """
    rng = rng or np.random.default_rng(seed=0)
    n_samples = n_samples or len(df)
    groups = df[group_col].to_numpy()
    values = df[metric].to_numpy()
    n = len(df)
    x_a, x_b = [], []
    attempts = 0
    while len(x_a) < n_samples and attempts < 50 * n_samples:
        i, j = rng.integers(0, n, size=2)
        attempts += 1
        if i == j or groups[i] == groups[j]:
            continue
        x_a.append(values[i])
        x_b.append(values[j])
    return np.asarray(x_a), np.asarray(x_b)


# ---------- top-level estimator ----------

def estimate_pef(
    x_a: np.ndarray,
    x_b: np.ndarray,
    *,
    metric: str = "metric",
    pairing: str = "pairing",
    binary_outcome: np.ndarray | None = None,
) -> PEFRecord:
    """Estimate the full PEF record for a paired array.

    If `binary_outcome` is provided (one Y per pair), I(X;Y) is computed using
    the realised class-conditional means (more robust than the closed form when
    bivariate normality is questionable). Otherwise the PEF closed-form
    Gaussian-discriminant approximation is used with delta = mean(A) - mean(B).
    """
    x_a = np.asarray(x_a, dtype=float)
    x_b = np.asarray(x_b, dtype=float)
    mask = np.isfinite(x_a) & np.isfinite(x_b)
    x_a, x_b = x_a[mask], x_b[mask]
    if len(x_a) < 3:
        raise ValueError("need at least 3 valid pairs to estimate PEF")

    sigma_a = float(np.std(x_a, ddof=1))
    sigma_b = float(np.std(x_b, ddof=1))
    kappa = (sigma_b * sigma_b) / (sigma_a * sigma_a) if sigma_a > 0 else float("nan")
    rho = correlation(x_a, x_b)
    delta = float(np.mean(x_a) - np.mean(x_b))
    eta_v = eta(kappa, rho)

    if binary_outcome is not None:
        binary_outcome = np.asarray(binary_outcome)[mask]
        mi = _mi_empirical_gaussian(x_a - x_b, binary_outcome)
    else:
        mi = mutual_information_gaussian(delta, sigma_a, kappa, eta_v)

    return PEFRecord(
        metric=metric,
        pairing=pairing,
        n_pairs=len(x_a),
        sigma_a=sigma_a,
        sigma_b=sigma_b,
        kappa=kappa,
        rho=rho,
        delta=delta,
        eta=eta_v,
        mutual_information=mi,
        quadrant=quadrant_of(kappa, rho),
    )


def _mi_empirical_gaussian(x: np.ndarray, y: np.ndarray) -> float:
    """Empirical I(X;Y) for binary Y via the Gaussian-discriminant approximation
    with realised class means and pooled variance.
    """
    y = np.asarray(y).astype(int)
    if len(np.unique(y)) != 2:
        return 0.0
    x0 = x[y == 0]
    x1 = x[y == 1]
    if len(x0) < 2 or len(x1) < 2:
        return 0.0
    mu_diff = float(np.mean(x1) - np.mean(x0))
    var_pooled = float(np.var(x, ddof=1))
    if var_pooled <= 0:
        return 0.0
    snr = mu_diff / (2.0 * np.sqrt(var_pooled))
    p = float(norm.cdf(snr))
    return 1.0 - binary_entropy(p)


# ---------- batch over metrics ----------

def estimate_pef_table(
    df: pd.DataFrame,
    metrics: list[str],
    *,
    group_col: str,
    entity_col: str,
    outcome_col: str | None = None,
) -> pd.DataFrame:
    """Compute PEFRecords for every metric under both within-group and
    across-group pairing schemes; return as a tidy DataFrame.

    If ``outcome_col`` is provided, mutual information is computed empirically
    against the binary outcome rather than via the closed-form delta-based
    approximation, which is degenerate for within-group pairings where the
    symmetric construction forces delta ~ 0.
    """
    rows = []
    for metric in metrics:
        a, b = make_pairs_within_group(df, metric, group_col, entity_col)
        rec = estimate_pef(a, b, metric=metric, pairing=f"within_{group_col}").to_dict()
        if outcome_col and outcome_col in df.columns:
            rec["mutual_information"] = _mi_against_outcome(df, metric, outcome_col)
        rows.append(rec)
        a, b = make_pairs_across_group(df, metric, group_col)
        rec = estimate_pef(a, b, metric=metric, pairing=f"across_{group_col}").to_dict()
        if outcome_col and outcome_col in df.columns:
            rec["mutual_information"] = _mi_against_outcome(df, metric, outcome_col)
        rows.append(rec)
    return pd.DataFrame(rows)


def _mi_against_outcome(df: pd.DataFrame, metric: str, outcome_col: str) -> float:
    """Empirical I(X; Y) of a metric against a binary outcome label, via the
    Gaussian-discriminant approximation with realised class means.

    This is the right quantity for digit weighting in the encoding: how much
    does the metric tell us about the outcome we are trying to recover?
    """
    x = df[metric].to_numpy()
    y = df[outcome_col].to_numpy()
    mask = np.isfinite(x) & np.isfinite(y)
    return _mi_empirical_gaussian(x[mask], y[mask])
