"""Rugby data loading tests."""

import pandas as pd

from pipeline.padic_pef.ingest import (
    REQUIRED_RUGBY_COLUMNS,
    load_rugby_from_mat,
    load_rugby_matches,
    resolve_rugby_data_path,
)


def test_load_rugby_from_mat():
    path = resolve_rugby_data_path()
    df = load_rugby_from_mat(path) if str(path).endswith(".mat") else load_rugby_matches(path)
    assert len(df) == 1128
    assert df["team"].nunique() == 16
    for col in REQUIRED_RUGBY_COLUMNS:
        assert col in df.columns


def test_encode_from_mat():
    from pipeline.padic_pef.legacy_d2 import encode_matlab_7d

    enc = encode_matlab_7d()
    assert enc.digits.shape == (16, 7)
