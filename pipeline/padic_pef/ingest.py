"""Data ingestion for rugby (implemented) and the two health pilots (stubs).

Rugby is the falsification platform: ``load_rugby_matches`` reads the 1 128-row
CSV in this repository. The MATLAB 7-d encoding of those matches lives in
``legacy_d2.encode_matlab_7d`` and must be used before any PEF re-encoding.

NHS-SOF and WIMD loaders remain stubs until the rugby parity gate in
FOUNDATION.md §2.3 passes.

Each health loader, once filled in, returns a tidy DataFrame with one row per
entity-period and columns:
    - entity_id        e.g. ods_code (NHS) or lsoa_code (WIMD)
    - group_id         e.g. region (NHS) or local_authority (WIMD)
    - period           year (NHS) or year of WIMD release (WIMD; constant 2019)
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

# Repo root is two levels above this file: pipeline/padic_pef/ingest.py
DEFAULT_RUGBY_CSV = (
    Path(__file__).resolve().parents[2] / "data" / "rugby" / "rugby_analysis_ready.csv"
)

REQUIRED_RUGBY_COLUMNS = (
    "season",
    "team",
    "final_points_relative",
    "abs_carries",
    "abs_passes",
    "rel_turnovers_won",
    "rel_turnovers_conceded",
    "abs_kicks_from_hand",
    "rel_clean_breaks",
    "rel_penalties_conceded",
    "abs_scrums_won",
    "abs_lineout_throws_won",
    "outcome_binary",
)


def load_rugby_matches(csv_path: str | Path | None = None) -> pd.DataFrame:
    """Load the URC team-match panel.

    Returns 1 128 rows (564 fixtures × 2 team perspectives), 16 teams,
    seasons 21/22–24/25. This is the match-level table; clustering is on
    the 16 team-level encodings from ``legacy_d2.encode_matlab_7d``.
    """
    path = Path(csv_path) if csv_path is not None else DEFAULT_RUGBY_CSV
    if not path.is_file():
        raise FileNotFoundError(
            f"Rugby CSV not found at {path}. Expected data/rugby/rugby_analysis_ready.csv "
            "at the repository root."
        )
    df = pd.read_csv(path)
    missing = [c for c in REQUIRED_RUGBY_COLUMNS if c not in df.columns]
    if missing:
        raise KeyError(f"rugby CSV missing columns: {missing}")
    return df


def add_relative_features(
    df: pd.DataFrame,
    metrics: list[str],
    group_col: str,
) -> pd.DataFrame:
    """Add `<metric>_rel` columns: each entity's metric value minus its
    group mean (within the same period if 'period' is in the DataFrame).
    """
    out = df.copy()
    keys = [group_col]
    if "period" in df.columns:
        keys.append("period")
    for metric in metrics:
        if metric not in df.columns:
            continue
        means = df.groupby(keys)[metric].transform("mean")
        out[f"{metric}_rel"] = df[metric] - means
    return out


def load_nhs_sof(config: dict) -> pd.DataFrame:
    """Load NHS System Oversight Framework data into a tidy DataFrame.

    Expected config keys:
        path: location of the raw SOF CSV / Parquet
        metrics: list of metric column names to retain
        period_col: e.g. 'fiscal_year'

    TODO: implement once data is acquired in weeks 1-2.
    """
    raise NotImplementedError(
        "NHS-SOF loader is a stub; fill in once data acquisition completes "
        "in week 1-2 of the protocol. Expected output: tidy DataFrame with "
        "columns [entity_id=ods_code, group_id=region, period, ...metrics]."
    )


def load_wimd(config: dict) -> pd.DataFrame:
    """Load Welsh Index of Multiple Deprivation data into a tidy DataFrame.

    Expected config keys:
        path: location of the raw StatsWales CSV
        domains: typically the seven WIMD domains
        geography_lookup: ONS LSOA -> LA -> health board mapping

    TODO: implement once data is acquired in weeks 1-2.
    """
    raise NotImplementedError(
        "WIMD loader is a stub; fill in once data acquisition completes "
        "in week 1-2 of the protocol. Expected output: tidy DataFrame with "
        "columns [entity_id=lsoa_code, group_id=local_authority, period, ...domains]."
    )


# ---------- synthetic data generator (for testing the pipeline end-to-end) ----------

def synthetic_hierarchical_dataset(
    n_entities: int = 150,
    n_groups: int = 15,
    n_metrics: int = 7,
    n_periods: int = 5,
    seed: int = 0,
) -> pd.DataFrame:
    """Generate synthetic hierarchical data with the structure expected by the
    pipeline. Used for testing in absence of real NHS-SOF / WIMD data.

    Each entity is assigned to a group; each metric is generated as
        x = group_effect + entity_effect + period_effect + noise
    so that within-group correlations are positive and across-group correlations
    are near zero — mimicking the predicted Q1/Q2 vs Q3/Q4 quadrant drift.
    """
    rng = np.random.default_rng(seed)
    group_ids = np.repeat(np.arange(n_groups), int(np.ceil(n_entities / n_groups)))[:n_entities]
    rng.shuffle(group_ids)
    rows = []
    # Stronger group separation so the encoding is non-degenerate at bins=4
    group_means = rng.normal(0, 2.5, size=(n_groups, n_metrics))
    entity_means = rng.normal(0, 0.3, size=(n_entities, n_metrics))
    for i in range(n_entities):
        for t in range(n_periods):
            x = group_means[group_ids[i]] + entity_means[i] + rng.normal(0, 0.25, size=n_metrics)
            row = {"entity_id": f"E{i:04d}", "group_id": f"G{group_ids[i]:02d}", "period": 2020 + t}
            for k in range(n_metrics):
                row[f"m{k+1}"] = float(x[k])
            rows.append(row)
    df = pd.DataFrame(rows)
    metrics = [f"m{k+1}" for k in range(n_metrics)]
    df = add_relative_features(df, metrics, group_col="group_id")
    # Synthetic outcome: high if entity_id is in low-numbered group
    df["outcome_binary"] = (df["group_id"].str[1:].astype(int) < n_groups // 2).astype(int)
    return df
