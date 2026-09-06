"""A1 week 2.5 experiments: Dominion Q1, Q3, Q5, Q8 (FOUNDATION.md §5.1, §8).

Run from repository root:

    python -m pipeline.padic_pef.a1_experiments

Or:

    python scripts/run_week25_a1.py
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from sklearn.metrics import adjusted_rand_score

from . import cluster
from .adapters import rugby as rugby_adapter
from .dominion import (
    NESTED_CUTS,
    as_encoding,
    construction_check,
    ConstructionCheck,
    first_disagreement_share,
    nested_cut_labels,
    plant,
    planted_ranks,
)
from .erode import STAGES, apply
from .ingest import DEFAULT_RUGBY_CSV
from .validate import baseline_clusterings, silhouette_comparison

REPO_ROOT = Path(__file__).resolve().parents[2]
RESULTS_DIR = REPO_ROOT / "pipeline" / "results"

ARI_GATE = 0.8
PI_GRID = np.round(np.linspace(0.0, 1.0, 11), 2)
SEEDS = tuple(range(5))
GATES = (0.7, 0.8, 0.9)
PRIMES = (2, 3, 5, 7, 11, 13)
DEFAULT_P = 2
DEFAULT_LINKAGE = "complete"
E4_PI_GRID = np.round(np.linspace(0.0, 0.5, 11), 2)


@dataclass
class Q1Row:
    stage: str
    linkage: str
    seed: int
    min_rank_ari: float
    worst_pi: float
    pass_gate: bool


@dataclass
class Q3Row:
    stage: str
    pi: float
    k: int
    rank_ari: float
    nested_ari: float
    silhouette: float
    pass_gate: bool


@dataclass
class Q5Row:
    perm: tuple[int, ...]
    description: str
    performance_at_rank: bool
    silhouette: float
    rank_ari: float
    rank_first_share: float
    nearest_curve_stage: str
    nearest_curve_pi: float
    curve_distance: float
    near_e0: bool


@dataclass
class Q8Row:
    k: int
    partitions_match: bool
    silhouettes: dict[int, float]
    labels_by_p: dict[int, list[int]]


def _ground_truth_ranks() -> np.ndarray:
    return planted_ranks(plant())


def _construction(
    digits: np.ndarray,
    *,
    p: int = DEFAULT_P,
    linkage: str = DEFAULT_LINKAGE,
    k: int = 4,
    ground_truth: np.ndarray | None = None,
) -> ConstructionCheck:
    return construction_check(
        digits,
        p=p,
        linkage_method=linkage,
        k=k,
        ground_truth_ranks=ground_truth,
    )


def _first_failure_pi(
    digits: np.ndarray,
    stage: str,
    *,
    seeds: tuple[int, ...] = SEEDS,
    gate: float = ARI_GATE,
    pi_grid: np.ndarray = PI_GRID,
    linkage: str = DEFAULT_LINKAGE,
    p: int = DEFAULT_P,
) -> dict[str, Any]:
    """First π at which rank ARI drops below gate (per seed)."""
    base = plant()
    truth = _ground_truth_ranks()
    rows = []
    for seed in seeds:
        first_pi = None
        for pi in pi_grid:
            rng = np.random.default_rng(seed)
            if pi == 0.0 and stage == "E0":
                eroded = base
            else:
                eroded = apply(base, stage, float(pi), rng)
            chk = _construction(
                eroded, p=p, linkage=linkage, k=4, ground_truth=truth
            )
            if chk.rank_ari < gate:
                first_pi = float(pi)
                break
        rows.append({"seed": seed, "first_failure_pi": first_pi})
    pis = [r["first_failure_pi"] for r in rows if r["first_failure_pi"] is not None]
    return {
        "stage": stage,
        "linkage": linkage,
        "gate": gate,
        "seeds": rows,
        "first_pi_min": min(pis) if pis else None,
        "first_pi_max": max(pis) if pis else None,
        "never_fails": len(pis) == 0,
    }


def run_q1(
    *,
    pi_grid: np.ndarray = PI_GRID,
    seeds: tuple[int, ...] = SEEDS,
    gate: float = ARI_GATE,
    p: int = DEFAULT_P,
) -> pd.DataFrame:
    """Q1: E1–E3 rank ARI ≥ gate for all π and all linkages."""
    base = plant()
    truth = _ground_truth_ranks()
    rows: list[Q1Row] = []
    for stage in ("E1", "E2", "E3"):
        for linkage in cluster.SUPPORTED_LINKAGES:
            for seed in seeds:
                min_ari = 1.0
                worst_pi = 0.0
                for pi in pi_grid:
                    rng_pi = np.random.default_rng(seed)
                    eroded = apply(base, stage, float(pi), rng_pi)
                    chk = _construction(
                        eroded, p=p, linkage=linkage, k=4, ground_truth=truth
                    )
                    if chk.rank_ari < min_ari:
                        min_ari = chk.rank_ari
                        worst_pi = float(pi)
                rows.append(
                    Q1Row(
                        stage=stage,
                        linkage=linkage,
                        seed=seed,
                        min_rank_ari=float(min_ari),
                        worst_pi=worst_pi,
                        pass_gate=min_ari >= gate,
                    )
                )
    df = pd.DataFrame([asdict(r) for r in rows])
    return df


def run_q2_robustness(
    *,
    seeds: tuple[int, ...] = SEEDS,
    gates: tuple[float, ...] = GATES,
) -> pd.DataFrame:
    """Q2 extension: E4/E5 first-failure π across gates and seeds."""
    records = []
    for stage in ("E4", "E5"):
        for gate in gates:
            for linkage in cluster.SUPPORTED_LINKAGES:
                info = _first_failure_pi(
                    plant(), stage, seeds=seeds, gate=gate, linkage=linkage
                )
                records.append(info)
    return pd.DataFrame(records)


def _nested_recovery(
    digits: np.ndarray,
    k: int,
    *,
    ground_truth_digits: np.ndarray | None = None,
    p: int = DEFAULT_P,
    linkage: str = DEFAULT_LINKAGE,
) -> tuple[float, float, float]:
    """ARI vs planted nested cut at k (from ground truth), silhouette."""
    truth = plant() if ground_truth_digits is None else ground_truth_digits
    enc = as_encoding(digits)
    result = cluster.cluster_padic(enc, p=p, k=k, linkage_method=linkage)
    true_nested = nested_cut_labels(truth, k)
    nested_ari = float(adjusted_rand_score(true_nested, result.labels))
    truth_ranks = planted_ranks(truth)
    rank_ari = (
        float(adjusted_rand_score(truth_ranks, result.labels)) if k == 4 else float("nan")
    )
    return nested_ari, rank_ari, float(result.silhouette)


def run_q3(
    *,
    pi_grid_e4: np.ndarray = E4_PI_GRID,
    seeds: tuple[int, ...] = (0,),
    gate: float = ARI_GATE,
    p: int = DEFAULT_P,
    linkage: str = DEFAULT_LINKAGE,
) -> pd.DataFrame:
    """Q3: nested cuts k∈{2,4,8} on E0; E4 destroys coarsest-first."""
    rows: list[Q3Row] = []
    base = plant()
    truth = base

    for k in NESTED_CUTS:
        nested_ari, _, sil = _nested_recovery(
            base, k, ground_truth_digits=truth, p=p, linkage=linkage
        )
        rows.append(
            Q3Row(
                stage="E0",
                pi=0.0,
                k=k,
                rank_ari=float("nan"),
                nested_ari=nested_ari,
                silhouette=sil,
                pass_gate=nested_ari >= gate,
            )
        )

    for pi in pi_grid_e4:
        if pi == 0.0:
            continue
        eroded = apply(base, "E4", float(pi), np.random.default_rng(seeds[0]))
        for k in NESTED_CUTS:
            nested_ari, _, sil = _nested_recovery(
                eroded, k, ground_truth_digits=truth, p=p, linkage=linkage
            )
            rows.append(
                Q3Row(
                    stage="E4",
                    pi=float(pi),
                    k=k,
                    rank_ari=float("nan"),
                    nested_ari=nested_ari,
                    silhouette=sil,
                    pass_gate=nested_ari >= gate,
                )
            )

    return pd.DataFrame([asdict(r) for r in rows])


def q3_coarsest_first_summary(q3_df: pd.DataFrame, gate: float = ARI_GATE) -> dict[str, Any]:
    """First π where each nested k fails under E4."""
    e4 = q3_df[(q3_df["stage"] == "E4") & (~q3_df["pass_gate"])]
    first_fail: dict[int, float | None] = {}
    for k in NESTED_CUTS:
        sub = e4[e4["k"] == k].sort_values("pi")
        first_fail[k] = float(sub["pi"].iloc[0]) if len(sub) else None
    order_ok = None
    if all(first_fail[k] is not None for k in NESTED_CUTS):
        order_ok = first_fail[2] <= first_fail[4] <= first_fail[8]
    return {"first_failure_pi_by_k": first_fail, "coarsest_first": order_ok}


def build_erosion_curve(
    *,
    pi_grid: np.ndarray = PI_GRID,
    seed: int = 0,
    p: int = DEFAULT_P,
    linkage: str = DEFAULT_LINKAGE,
) -> pd.DataFrame:
    """Toy erosion curve in (silhouette, rank-first disagreement share) space."""
    base = plant()
    rows = []
    for stage in STAGES:
        for pi in pi_grid:
            if stage == "E0" and pi > 0:
                continue
            rng = np.random.default_rng(seed)
            eroded = apply(base, stage, float(pi), rng) if stage != "E0" or pi == 0 else base
            truth = _ground_truth_ranks()
            chk = _construction(
                eroded, p=p, linkage=linkage, k=4, ground_truth=truth
            )
            share = chk.first_disagree_share
            rows.append(
                {
                    "stage": stage,
                    "pi": float(pi),
                    "silhouette": chk.silhouette,
                    "rank_ari": chk.rank_ari,
                    "rank_first_share": float(share[0]),
                }
            )
    return pd.DataFrame(rows)


def _nearest_curve_point(
    curve: pd.DataFrame, silhouette: float, rank_first_share: float
) -> tuple[str, float, float]:
    d = np.sqrt(
        (curve["silhouette"] - silhouette) ** 2
        + (curve["rank_first_share"] - rank_first_share) ** 2
    )
    idx = int(d.idxmin())
    row = curve.loc[idx]
    return str(row["stage"]), float(row["pi"]), float(d.min())


def run_q5(
    csv_path: Path | str | None = None,
    *,
    curve: pd.DataFrame | None = None,
    p: int = DEFAULT_P,
    linkage: str = DEFAULT_LINKAGE,
    near_e0_threshold: float = 0.15,
) -> pd.DataFrame:
    """Q5: 24 URC digit permutations vs erosion curve."""
    csv_path = Path(csv_path or DEFAULT_RUGBY_CSV)
    if not csv_path.is_file():
        raise FileNotFoundError(
            f"Rugby CSV not found at {csv_path}. Q5 requires data/rugby/rugby_analysis_ready.csv"
        )

    if curve is None:
        curve = build_erosion_curve()

    e0 = curve[(curve["stage"] == "E0") & (curve["pi"] == 0.0)].iloc[0]
    e0_point = (float(e0["silhouette"]), float(e0["rank_first_share"]))

    rows: list[Q5Row] = []
    for perm in rugby_adapter.slot_permutations():
        enc = rugby_adapter.to_encoding(csv_path, perm=perm)
        digits = enc.digits
        chk = construction_check(digits, p=p, linkage_method=linkage, k=4)
        share = first_disagreement_share(digits)
        perf_rank = rugby_adapter.performance_occupies_rank(perm)
        stage, pi, dist = _nearest_curve_point(
            curve, chk.silhouette, float(share[0])
        )
        near_e0 = bool(
            np.sqrt(
                (chk.silhouette - e0_point[0]) ** 2
                + (float(share[0]) - e0_point[1]) ** 2
            )
            <= near_e0_threshold
        )
        rows.append(
            Q5Row(
                perm=perm,
                description=rugby_adapter.describe_perm(perm),
                performance_at_rank=perf_rank,
                silhouette=chk.silhouette,
                rank_ari=chk.rank_ari,
                rank_first_share=float(share[0]),
                nearest_curve_stage=stage,
                nearest_curve_pi=pi,
                curve_distance=dist,
                near_e0=near_e0,
            )
        )

    return pd.DataFrame([asdict(r) for r in rows])


def q5_verdict(q5_df: pd.DataFrame) -> dict[str, Any]:
    """Test: near-E0 only when performance occupies rank?"""
    perf = q5_df[q5_df["performance_at_rank"]]
    non = q5_df[~q5_df["performance_at_rank"]]
    return {
        "performance_at_rank_near_e0_rate": float(perf["near_e0"].mean()) if len(perf) else None,
        "other_perms_near_e0_rate": float(non["near_e0"].mean()) if len(non) else None,
        "only_perf_near_e0": bool(
            perf["near_e0"].all() and not non["near_e0"].any()
        ) if len(perf) and len(non) else None,
        "declared_perm_near_e0": bool(
            q5_df[q5_df["perm"].apply(lambda t: t == rugby_adapter.DECLARED_PERM)][
                "near_e0"
            ].iloc[0]
        ),
    }


def run_q8(
    *,
    primes: tuple[int, ...] = PRIMES,
    ks: tuple[int, ...] = NESTED_CUTS,
    linkage: str = DEFAULT_LINKAGE,
) -> tuple[pd.DataFrame, dict[str, Any]]:
    """Q8: nested partition invariant in p; silhouette varies."""
    base = plant()
    enc = as_encoding(base)
    rows: list[dict[str, Any]] = []
    labels_by_k_p: dict[int, dict[int, np.ndarray]] = {k: {} for k in ks}
    silhouettes: dict[int, dict[int, float]] = {k: {} for k in ks}

    for p in primes:
        for k in ks:
            res = cluster.cluster_padic(enc, p=p, k=k, linkage_method=linkage)
            labels_by_k_p[k][p] = res.labels.copy()
            silhouettes[k][p] = res.silhouette
            rows.append({"p": p, "k": k, "silhouette": res.silhouette})

    partition_rows = []
    for k in ks:
        ref_p = primes[0]
        ref_labels = labels_by_k_p[k][ref_p]
        match_all = True
        for p in primes[1:]:
            ari = float(adjusted_rand_score(ref_labels, labels_by_k_p[k][p]))
            same = ari >= 1.0 - 1e-12
            match_all = match_all and same
        sil_vals = list(silhouettes[k].values())
        partition_rows.append(
            {
                "k": k,
                "partitions_match_all_primes": match_all,
                "silhouette_min": min(sil_vals),
                "silhouette_max": max(sil_vals),
                "silhouette_spread": max(sil_vals) - min(sil_vals),
            }
        )

    summary = {
        "partitions_invariant": all(r["partitions_match_all_primes"] for r in partition_rows),
        "silhouette_varies": any(r["silhouette_spread"] > 1e-6 for r in partition_rows),
    }
    return pd.DataFrame(rows), {"by_k": partition_rows, **summary}


def run_q7_adapter_parity(
    csv_path: Path | str | None = None,
    perm: tuple[int, ...] = rugby_adapter.DECLARED_PERM,
) -> pd.DataFrame | None:
    """Q7 re-check on declared 4-d reading (partial, bundled with week 2.5)."""
    csv_path = Path(csv_path or DEFAULT_RUGBY_CSV)
    if not csv_path.is_file():
        return None
    enc = rugby_adapter.to_encoding(csv_path, perm=perm)
    result = cluster.cluster_padic(enc, p=DEFAULT_P, k=4, linkage_method=DEFAULT_LINKAGE)
    feats = enc.digits.astype(float)
    return validate.silhouette_comparison(result, feats)


def summarise_q1(q1_df: pd.DataFrame, gate: float = ARI_GATE) -> dict[str, Any]:
    agg = (
        q1_df.groupby(["stage", "linkage"])["pass_gate"]
        .agg(["all", "min"])
        .reset_index()
    )
    failures = q1_df[~q1_df["pass_gate"]]
    return {
        "all_pass": bool(q1_df["pass_gate"].all()),
        "failures": len(failures),
        "by_stage_linkage": agg.to_dict(orient="records"),
        "min_rank_ari_overall": float(q1_df["min_rank_ari"].min()),
    }


def render_report(
    q1_df: pd.DataFrame,
    q3_df: pd.DataFrame,
    q8_detail: dict[str, Any],
    q8_sil: pd.DataFrame,
    q5_df: pd.DataFrame | None = None,
    q5_verdict_dict: dict[str, Any] | None = None,
    q3_cf: dict[str, Any] | None = None,
    q2_df: pd.DataFrame | None = None,
    q7_df: pd.DataFrame | None = None,
) -> str:
    q1s = summarise_q1(q1_df)
    lines = [
        "# A1 week 2.5 report (Dominion Q1, Q3, Q5, Q8)",
        "",
        "Generated by `pipeline/padic_pef/a1_experiments.py`. See FOUNDATION.md §5.1 and §8.",
        "",
        "## Q1 — finer digits (E1–E3) × linkage",
        "",
        f"- **Overall pass** (rank ARI ≥ {ARI_GATE} for all π, seeds, linkages): "
        f"**{'YES' if q1s['all_pass'] else 'NO'}**",
        f"- Minimum rank ARI observed: **{q1s['min_rank_ari_overall']:.4f}**",
        f"- Failure rows: **{q1s['failures']}**",
        "",
        "### Summary by stage × linkage",
        "",
        pd.DataFrame(q1s["by_stage_linkage"]).to_markdown(index=False),
        "",
    ]

    if q2_df is not None and len(q2_df):
        lines.extend(["## Q2 — E4/E5 first-failure π (robustness)", ""])
        sub = q2_df[
            (q2_df["linkage"] == DEFAULT_LINKAGE) & (q2_df["gate"] == ARI_GATE)
        ]
        for _, row in sub.iterrows():
            lines.append(
                f"- **{row['stage']}**: first failure π in "
                f"[{row.get('first_pi_min')}, {row.get('first_pi_max')}] "
                f"(never fails: {row.get('never_fails')})"
            )
        lines.append("")

    lines.extend(
        [
            "## Q3 — nested cuts k ∈ {2, 4, 8}",
            "",
            "### E0 recovery",
            "",
        ]
    )
    e0 = q3_df[q3_df["stage"] == "E0"]
    lines.append(e0.to_markdown(index=False))
    lines.append("")
    if q3_cf:
        lines.extend(
            [
                "### E4 coarsest-first failure",
                "",
                f"- First failure π by k: `{q3_cf['first_failure_pi_by_k']}`",
                f"- Coarsest-first order (k=2 before k=4 before k=8): **{q3_cf['coarsest_first']}**",
                "",
            ]
        )

    lines.extend(
        [
            "## Q8 — prime invariance of partition vs silhouette",
            "",
            f"- **Partitions match across primes {PRIMES}:** "
            f"**{q8_detail.get('partitions_invariant')}**",
            f"- **Silhouette varies with p:** **{q8_detail.get('silhouette_varies')}**",
            "",
            pd.DataFrame(q8_detail["by_k"]).to_markdown(index=False),
            "",
            "### Silhouette by p and k",
            "",
            q8_sil.pivot(index="p", columns="k", values="silhouette").round(4).to_markdown(),
            "",
        ]
    )

    if q5_df is not None and len(q5_df):
        lines.extend(["## Q5 — URC adapter permutations (n=24)", ""])
        show = q5_df[
            [
                "description",
                "performance_at_rank",
                "silhouette",
                "rank_ari",
                "rank_first_share",
                "nearest_curve_stage",
                "nearest_curve_pi",
                "near_e0",
            ]
        ].sort_values("silhouette", ascending=False)
        lines.append(show.to_markdown(index=False))
        lines.append("")
        if q5_verdict_dict:
            lines.extend(
                [
                    "### Q5 verdict",
                    "",
                    f"- Performance-at-rank near-E0 rate: {q5_verdict_dict.get('performance_at_rank_near_e0_rate')}",
                    f"- Other permutations near-E0 rate: {q5_verdict_dict.get('other_perms_near_e0_rate')}",
                    f"- **Only performance-at-rank maps near E0:** {q5_verdict_dict.get('only_perf_near_e0')}",
                    "",
                ]
            )

    if q7_df is not None:
        lines.extend(["## Q7 — declared adapter parity (4-d)", "", q7_df.to_markdown(index=False), ""])

    return "\n".join(lines)


def run_all(
    csv_path: Path | str | None = None,
    *,
    write: bool = True,
) -> dict[str, Any]:
    """Execute week 2.5 suite and optionally write report artefacts."""
    q1_df = run_q1()
    q2_df = run_q2_robustness()
    q3_df = run_q3()
    q3_cf = q3_coarsest_first_summary(q3_df)
    q8_sil, q8_detail = run_q8()
    curve = build_erosion_curve()

    q5_df = None
    q5v = None
    q7_df = None
    csv_path = Path(csv_path or DEFAULT_RUGBY_CSV)
    if csv_path.is_file():
        q5_df = run_q5(csv_path, curve=curve)
        q5v = q5_verdict(q5_df)
        q7_df = run_q7_adapter_parity(csv_path)

    report = render_report(
        q1_df, q3_df, q8_detail, q8_sil, q5_df, q5v, q3_cf, q2_df, q7_df
    )

    out: dict[str, Any] = {
        "q1_summary": summarise_q1(q1_df),
        "q3_coarsest_first": q3_cf,
        "q8": q8_detail,
        "q5_verdict": q5v,
    }

    if write:
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        (RESULTS_DIR / "week25_a1_report.md").write_text(report, encoding="utf-8")
        curve.to_csv(RESULTS_DIR / "erosion_curve_points.csv", index=False)
        q1_df.to_csv(RESULTS_DIR / "week25_q1.csv", index=False)
        q3_df.to_csv(RESULTS_DIR / "week25_q3.csv", index=False)
        q8_sil.to_csv(RESULTS_DIR / "week25_q8.csv", index=False)
        if q5_df is not None:
            q5_df.to_csv(RESULTS_DIR / "week25_q5.csv", index=False)
        with open(RESULTS_DIR / "week25_a1_summary.json", "w", encoding="utf-8") as f:
            json.dump(out, f, indent=2, default=str)
        print(f"Wrote report to {RESULTS_DIR / 'week25_a1_report.md'}")

    return {
        "report": report,
        "q1": q1_df,
        "q2": q2_df,
        "q3": q3_df,
        "q5": q5_df,
        "q8": q8_detail,
        "summary": out,
    }


def main() -> None:
    results = run_all()
    print(results["report"][:2000])
    print("\n... (full report in pipeline/results/week25_a1_report.md)")


if __name__ == "__main__":
    main()
