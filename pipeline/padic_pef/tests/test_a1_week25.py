"""Week 2.5 A1 experiment tests."""

import numpy as np
import pytest

from pipeline.padic_pef.a1_experiments import (
    build_erosion_curve,
    run_q1,
    run_q3,
    run_q8,
    summarise_q1,
)
from pipeline.padic_pef.dominion import construction_check, plant


def test_q0_construction_check():
    chk = construction_check(plant(), p=2, linkage_method="complete", k=4)
    assert chk.rank_ari >= 0.99
    assert chk.n_labels == 4


def test_q1_all_linkages_pass():
    df = run_q1(seeds=(0, 1), pi_grid=np.array([0.0, 0.2, 0.5, 1.0]))
    summary = summarise_q1(df)
    assert summary["all_pass"], summary


def test_q3_e0_nested_recovery():
    df = run_q3(pi_grid_e4=np.array([0.1, 0.2]), seeds=(0,))
    e0 = df[df["stage"] == "E0"]
    # k=2 uses coarse rank r//2 (design lock); maxclust=2 may not recover it (ARI=0).
    assert e0[e0["k"] == 4]["nested_ari"].iloc[0] >= 0.8
    assert e0[e0["k"] == 8]["nested_ari"].iloc[0] >= 0.8


def test_q8_partition_invariance():
    _, detail = run_q8(primes=(2, 3, 5, 7))
    assert detail["partitions_invariant"]
    assert detail["silhouette_varies"]


def test_erosion_curve_has_e0():
    curve = build_erosion_curve(seed=0)
    assert ((curve["stage"] == "E0") & (curve["pi"] == 0.0)).any()
