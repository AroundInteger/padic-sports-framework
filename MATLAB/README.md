# MATLAB scripts

Paths in these scripts assume the **repository root** is the current working directory.

## Setup

```matlab
cd('/path/to/p-adic-systems')
addpath('MATLAB')
```

## Teaching-bridge track (this directory)

| Script | Purpose |
|---|---|
| `run_framework.m` | Seven-step synthetic perfect system |
| `run_with_real_data.m` | Football and rugby example CSVs |
| `run_real_data_analysis.m` | Analyse one CSV file |
| `perfect_padic_sports_framework.m` | Full synthetic implementation |
| `cluster_feature_matrix.m` | P-adic clustering engine (prime search) |
| `build_*_bridge.m`, `load_*_csv.m`, `prepare_real_data_features.m` | Real-data pipeline |

### Quick start

```matlab
run_framework
run_with_real_data
run_real_data_analysis('rugby', 'data/examples/rugby_sample.csv')
```

Output figures are written to `figures/` at the repository root.

## Rugby audit track (copy from local)

The Sep 2025 URC audit scripts (`enhanced_padic_rugby_pipeline.m`, `perfect_padic_rugby_optimized.m`, Phase 1–3 validation suites) are **not** in this remote clone yet. Copy from your local `p-adic-systems` worktree. See `docs/MIGRATION.md`.

**Do not** conflate teaching-bridge results with the D2 0.7083 audit. See `FOUNDATION.md` §4 and ruling R12.

## Requirements

- MATLAB R2019b or later (R2020a+ recommended)
- Statistics and Machine Learning Toolbox
