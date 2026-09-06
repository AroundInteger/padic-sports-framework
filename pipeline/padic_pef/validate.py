"""Validation: baseline comparisons (Ward / k-means / GMM), bootstrap Jaccard
stability, and external-outcome prediction.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
from dataclasses import dataclass
from sklearn.cluster import KMeans, AgglomerativeClustering
from sklearn.mixture import GaussianMixture
from sklearn.metrics import silhouette_score, adjusted_rand_score, roc_auc_score, r2_score
from sklearn.model_selection import StratifiedKFold, KFold
from sklearn.linear_model import LogisticRegression, LinearRegression
from sklearn.preprocessing import OneHotEncoder

from .cluster import ClusterResult


# ---------- baselines ----------

def baseline_clusterings(features: np.ndarray, k: int) -> dict[str, np.ndarray]:
    """Run Ward, k-means, and GMM clusterings on the same Euclidean features.

    Returns a dict {method_name: labels}.
    """
    out = {}
    out["ward"] = AgglomerativeClustering(n_clusters=k, linkage="ward").fit_predict(features)
    out["kmeans"] = KMeans(n_clusters=k, n_init=10, random_state=0).fit_predict(features)
    out["gmm"] = GaussianMixture(n_components=k, random_state=0).fit_predict(features)
    return out


def silhouette_comparison(
    padic_result: ClusterResult,
    features: np.ndarray,
) -> pd.DataFrame:
    """Compute silhouette for the p-adic clustering and the three baselines
    at the same k.
    """
    k = len(np.unique(padic_result.labels))
    rows = [{
        "method": "padic",
        "p": padic_result.p,
        "k": k,
        "silhouette": padic_result.silhouette,
    }]
    baselines = baseline_clusterings(features, k)
    for name, labels in baselines.items():
        try:
            sil = float(silhouette_score(features, labels))
        except ValueError:
            sil = float("nan")
        rows.append({"method": name, "p": np.nan, "k": k, "silhouette": sil})
    return pd.DataFrame(rows)


# ---------- bootstrap stability ----------

def bootstrap_jaccard(
    cluster_fn,
    n_entities: int,
    *,
    n_resamples: int = 100,
    rng: np.random.Generator | None = None,
) -> float:
    """Estimate cluster stability via bootstrap-resampled Jaccard.

    `cluster_fn` is a callable cluster_fn(idx) -> labels, where idx is the
    bootstrap sample of entity indices. Returns the mean adjusted Rand index
    between consecutive resamples (proxy for Jaccard cluster stability).
    """
    rng = rng or np.random.default_rng(seed=0)
    prev_labels = None
    aris = []
    for _ in range(n_resamples):
        idx = rng.choice(n_entities, size=n_entities, replace=True)
        try:
            labels = cluster_fn(idx)
        except Exception:
            continue
        if prev_labels is not None and len(labels) == len(prev_labels):
            aris.append(adjusted_rand_score(prev_labels, labels))
        prev_labels = labels
    return float(np.mean(aris)) if aris else float("nan")


# ---------- outcome validation ----------

@dataclass
class OutcomeValidation:
    method: str            # "padic" or baseline name
    metric: str            # "auc" or "r2"
    score: float
    null_score: float      # null model (e.g. region-only) score
    delta: float


def cluster_predicts_binary(
    labels: np.ndarray,
    y: np.ndarray,
    *,
    null_features: np.ndarray | None = None,
    n_splits: int = 5,
    random_state: int = 0,
) -> OutcomeValidation:
    """5-fold CV: does cluster membership (one-hot) predict binary y better
    than a null model (null_features only)?

    Reports AUC and the AUC delta vs. null.
    """
    y = np.asarray(y).astype(int)
    enc = OneHotEncoder(sparse_output=False, handle_unknown="ignore")
    X_clusters = enc.fit_transform(labels.reshape(-1, 1))
    if null_features is not None:
        X_full = np.hstack([X_clusters, null_features])
    else:
        X_full = X_clusters

    skf = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=random_state)
    full_aucs = []
    null_aucs = []
    for tr, te in skf.split(X_full, y):
        m_full = LogisticRegression(max_iter=1000).fit(X_full[tr], y[tr])
        full_aucs.append(roc_auc_score(y[te], m_full.predict_proba(X_full[te])[:, 1]))
        if null_features is not None:
            m_null = LogisticRegression(max_iter=1000).fit(null_features[tr], y[tr])
            null_aucs.append(roc_auc_score(y[te], m_null.predict_proba(null_features[te])[:, 1]))
        else:
            null_aucs.append(0.5)
    full = float(np.mean(full_aucs))
    null = float(np.mean(null_aucs))
    return OutcomeValidation(
        method="padic", metric="auc", score=full, null_score=null, delta=full - null,
    )


def cluster_predicts_continuous(
    labels: np.ndarray,
    y: np.ndarray,
    *,
    null_features: np.ndarray | None = None,
    n_splits: int = 5,
    random_state: int = 0,
) -> OutcomeValidation:
    """5-fold CV: does cluster membership predict continuous y (e.g. emergency
    admission rate) better than a null model?

    Reports R² and the R² delta vs. null.
    """
    y = np.asarray(y).astype(float)
    enc = OneHotEncoder(sparse_output=False, handle_unknown="ignore")
    X_clusters = enc.fit_transform(labels.reshape(-1, 1))
    if null_features is not None:
        X_full = np.hstack([X_clusters, null_features])
    else:
        X_full = X_clusters

    kf = KFold(n_splits=n_splits, shuffle=True, random_state=random_state)
    full_r2s, null_r2s = [], []
    for tr, te in kf.split(X_full):
        m_full = LinearRegression().fit(X_full[tr], y[tr])
        full_r2s.append(r2_score(y[te], m_full.predict(X_full[te])))
        if null_features is not None:
            m_null = LinearRegression().fit(null_features[tr], y[tr])
            null_r2s.append(r2_score(y[te], m_null.predict(null_features[te])))
        else:
            null_r2s.append(0.0)
    full = float(np.mean(full_r2s))
    null = float(np.mean(null_r2s))
    return OutcomeValidation(
        method="padic", metric="r2", score=full, null_score=null, delta=full - null,
    )
