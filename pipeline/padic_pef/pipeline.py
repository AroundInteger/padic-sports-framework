"""Pipeline orchestration: end-to-end run from a config.

Once data loaders in `ingest.py` are filled in, calling `run(config)` executes:
    1. ingest -> tidy DataFrame
    2. PEF estimation per metric, both pairing schemes
    3. encoding (quadrant-aware abs/rel choice + I(X;Y) weights)
    4. p-adic clustering with prime / k sweep
    5. baseline comparison
    6. external outcome validation
    7. output: results/ directory with PEF tables, cluster labels, plots
"""

from __future__ import annotations

import json
import os
from dataclasses import asdict
import numpy as np
import pandas as pd

from . import ingest, pef, encode, cluster, validate


def aggregate_to_entity_level(df: pd.DataFrame, metrics: list[str]) -> pd.DataFrame:
    """Average each metric over periods to produce one row per entity.
    Relative features are recomputed against group means after aggregation.
    """
    keys = ["entity_id", "group_id"]
    agg = df.groupby(keys)[metrics].mean().reset_index()
    agg = ingest.add_relative_features(agg, metrics, group_col="group_id")
    if "outcome_binary" in df.columns:
        outcome = df.groupby("entity_id")["outcome_binary"].max().reset_index()
        agg = agg.merge(outcome, on="entity_id", how="left")
    return agg


def run_synthetic(seed: int = 0):
    """Run the full pipeline on synthetic data — useful for verifying the
    scaffold end-to-end.
    """
    df = ingest.synthetic_hierarchical_dataset(seed=seed)
    metrics = [c for c in df.columns if c.startswith("m") and not c.endswith("_rel")]
    entity_df = aggregate_to_entity_level(df, metrics)

    # PEF (route the outcome through so I(X;Y) is computed against the actual
    # binary outcome rather than the closed-form delta, which is degenerate
    # for within-group pairings).
    pef_table = pef.estimate_pef_table(
        entity_df, metrics, group_col="group_id", entity_col="entity_id",
        outcome_col="outcome_binary" if "outcome_binary" in entity_df.columns else None,
    )

    # Encoding
    enc = encode.build_encoding(
        entity_df, pef_table, metrics=metrics, entity_col="entity_id", bins=4
    )

    # Cluster sweep
    sweep = cluster.sweep(enc, primes=(2, 3, 5, 7), ks=tuple(range(2, 8)))
    best = cluster.best(sweep)

    # Baselines + outcome validation
    feats = enc.digits.astype(float) * enc.weights[None, :]
    sil_table = validate.silhouette_comparison(best, feats)

    if "outcome_binary" in entity_df.columns:
        outcome = entity_df["outcome_binary"].to_numpy()
        outcome_val = validate.cluster_predicts_binary(best.labels, outcome)
    else:
        outcome_val = None

    return {
        "pef_table": pef_table,
        "encoding": enc,
        "best_cluster": best,
        "silhouette_comparison": sil_table,
        "outcome_validation": outcome_val,
    }


def run(config_path: str) -> dict:
    """Run the pipeline against a YAML config. (Stub: dispatches to ingest
    based on `pilot` field.)"""
    import yaml
    with open(config_path) as f:
        config = yaml.safe_load(f)

    pilot = config.get("pilot", "synthetic")
    if pilot == "synthetic":
        return run_synthetic(seed=config.get("seed", 0))
    elif pilot == "nhs_sof":
        df = ingest.load_nhs_sof(config)
    elif pilot == "wimd":
        df = ingest.load_wimd(config)
    else:
        raise ValueError(f"unknown pilot: {pilot}")

    metrics = config["metrics"]
    entity_df = aggregate_to_entity_level(df, metrics)
    pef_table = pef.estimate_pef_table(
        entity_df, metrics, group_col="group_id", entity_col="entity_id",
        outcome_col=config.get("outcome_col"),
    )
    enc = encode.build_encoding(
        entity_df, pef_table, metrics=metrics, entity_col="entity_id",
        bins=config.get("bins", 4),
    )
    sweep = cluster.sweep(
        enc,
        primes=tuple(config.get("primes", [2, 3, 5, 7, 11, 13])),
        ks=tuple(config.get("ks", list(range(2, 16)))),
    )
    best = cluster.best(sweep)
    feats = enc.digits.astype(float) * enc.weights[None, :]
    sil_table = validate.silhouette_comparison(best, feats)
    return {
        "pef_table": pef_table,
        "encoding": enc,
        "best_cluster": best,
        "silhouette_comparison": sil_table,
        "all_clusterings": sweep,
    }


if __name__ == "__main__":
    # Smoke test on synthetic data
    out = run_synthetic(seed=42)
    print("PEF table shape:", out["pef_table"].shape)
    print("Best cluster: p =", out["best_cluster"].p, "k =", out["best_cluster"].k,
          "silhouette =", round(out["best_cluster"].silhouette, 4))
    print("Silhouette comparison:\n", out["silhouette_comparison"].to_string(index=False))
    if out["outcome_validation"] is not None:
        ov = out["outcome_validation"]
        print(f"Outcome AUC: {ov.score:.3f} (delta vs null: {ov.delta:+.3f})")
