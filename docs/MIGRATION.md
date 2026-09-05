# Migration: consolidating into p-adic-systems

This repository is the canonical home for the p-adic clustering programme. **`FOUNDATION.md` at the repository root is normative** — it governs all other documents.

## What this merge did (September 2026)

- Added `FOUNDATION.md` as the single source of truth.
- Moved teaching-bridge MATLAB scripts from the old `padic-sports-framework` root into `MATLAB/`.
- Created directory skeletons for `pipeline/padic_pef/`, `docs/`, `data/rugby/`, and validation result folders.
- Superseded the standalone `padic-sports-framework` repository (see root `README.md`).

## What you must still copy from your local worktree

The April–June 2026 off-shoot and the 25 August 2026 Python port live on your machine at:

`/Users/rowanbrown/Documents/GitHub/p-adic-systems/`

Copy these into this repository **before editing in parallel** (ruling R9):

| Source (local) | Destination (this repo) |
|---|---|
| `pipeline/padic_pef/` (full package) | `pipeline/padic_pef/` |
| `docs/methodology_note_PEF_padic_bridge.md` | `docs/` |
| `docs/p-adic_review_and_extensions.md` | `docs/` |
| `docs/OSF_preregistration.md` | `docs/` |
| `docs/offshoot_PROGRESS_LOG.md` | `docs/` |
| `docs/Paper/*.tex` | `docs/Paper/` |
| `data/rugby/rugby_analysis_ready.csv` | `data/rugby/` |
| `validation_results_phase*/` | `validation_results_phase*/` |
| Audit MATLAB: `enhanced_padic_rugby_pipeline.m`, `perfect_padic_rugby_optimized.m`, `rugby_padic_functions.m`, etc. | `MATLAB/` |

The Claude folder (`/Users/rowanbrown/Documents/Claude/Projects/p-adic applications in sport/`) is an **archive only** — do not edit it in parallel with this repository.

## Two MATLAB tracks (do not conflate)

| Track | Files | Purpose |
|---|---|---|
| **Teaching bridge** | `perfect_padic_sports_framework.m`, `run_framework.m`, football/rugby CSV loaders | Synthetic perfect system → football/rugby CSV examples. Uses D1-style distance in the monolith. |
| **Rugby audit** | `enhanced_padic_rugby_pipeline.m`, etc. (copy from local) | Sep 2025 URC runs, D2, 0.7083 claim, Phase 1–3 validation. Governed by `FOUNDATION.md` §4.2. |

Do not cite teaching-bridge silhouette numbers as rugby audit results.

## GitHub repository name

Recommended: rename `AroundInteger/padic-sports-framework` → `AroundInteger/p-adic-systems` in GitHub settings, or create `p-adic-systems` and archive the old repo with a redirect README.

## Week-one checklist for a new RA

See `FOUNDATION.md` §8. Start with §0 path conventions and §9 rulings R12 and R3 before running any script.
