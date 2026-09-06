# p-adic-systems

P-adic clustering of hierarchical paired systems. Rugby as the falsification platform; PEF as the feature-construction spine. Swansea University.

> **Read [`FOUNDATION.md`](FOUNDATION.md) first.** It is normative. Where it disagrees with any other document, FOUNDATION wins.

This repository consolidates the April–June 2026 off-shoot, the Python `padic_pef` pipeline, the Sep 2025 MATLAB audit tree, and the teaching-bridge scripts formerly in `padic-sports-framework`.

## Repository layout

```
p-adic-systems/
├── FOUNDATION.md              # Normative constitution (start here)
├── MATLAB/                    # .m scripts (teaching bridge + audit after sync)
├── pipeline/padic_pef/        # Canonical Python (D3, PEF, Dominion)
├── docs/                      # Methodology note, review, OSF, papers
├── data/
│   ├── rugby/                 # rugby_analysis_ready.csv (copy from local)
│   └── examples/              # Teaching-bridge sample CSVs
├── validation_results_phase*/  # Sep 2025 validation record
└── figures/                   # Generated on run (gitignored)
```

## Quick start (teaching-bridge MATLAB)

Requires MATLAB R2019b+ and Statistics and Machine Learning Toolbox.

```matlab
cd('/path/to/p-adic-systems')
addpath('MATLAB')
run_framework          % synthetic perfect system
run_with_real_data     % football + rugby examples
```

For the URC audit reproduction (D2, 1,128 rows, 16 teams), see `FOUNDATION.md` §8 and copy audit scripts from your local worktree per [`docs/MIGRATION.md`](docs/MIGRATION.md).

## Python pipeline

```bash
pip install -r pipeline/requirements.txt
python -m pytest pipeline/padic_pef/tests/ -q
```

**A1 week 2.5 (Dominion Q1, Q3, Q5, Q8):**

```bash
python scripts/run_week25_a1.py
# → pipeline/results/week25_a1_report.md
```

Q5 requires `data/rugby/rugby_analysis_ready.csv` (present locally after Mac sync).

Canonical distance is **D3** only. D2 is in `legacy_d2.py` for audit of the 0.7083 claim (ruling R12: not recovered; Python D2 = 0.5833).

## Sync status (September 2026)

| Component | In this remote clone | Action |
|---|---|---|
| `FOUNDATION.md` | Yes | — |
| Teaching-bridge MATLAB (`MATLAB/`) | Yes | — |
| Python `padic_pef` package | Skeleton only | Copy from local |
| Rugby CSV (`data/rugby/`) | Not committed | Copy from local |
| Audit MATLAB + validation results | Not present | Copy from local |
| `docs/*.md`, `docs/Paper/*.tex` | Stubs only | Copy from local |

See [`docs/MIGRATION.md`](docs/MIGRATION.md) for the full checklist.

**Mac one-time sync:** PR #1 is merged. Run `bash scripts/mac_one_time_setup.sh` on your Mac — see [`docs/MAC_SETUP.md`](docs/MAC_SETUP.md).

## Former `padic-sports-framework` repository

The standalone repo [`AroundInteger/padic-sports-framework`](https://github.com/AroundInteger/padic-sports-framework) is superseded by this monorepo. Recommended: rename this repository to `p-adic-systems` in GitHub settings and archive the old repo with a redirect.

## Academic output order

See `FOUNDATION.md` §4.4. Near-term priority: **A1** (Dominion erosion + one rugby reading), then **A2** (PEF methodology preprint).

## Licence

See local repository settings. Research code for Swansea University programme.
