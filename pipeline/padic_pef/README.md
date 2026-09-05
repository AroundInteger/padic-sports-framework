# padic_pef — canonical Python implementation

**Status:** skeleton in this remote clone. Full package copied from the local `p-adic-systems` worktree on 25 August 2026 per `FOUNDATION.md`.

## Expected layout (after sync)

```
pipeline/padic_pef/
├── pef.py              # PEF estimator
├── cluster.py          # D3 canonical distance
├── legacy_d2.py        # D2 audit of 0.7083 claim
├── dominion.py         # Hierarchical Dominion toy
├── erode.py            # Erosion curve (A1)
├── ingest.py           # Rugby / NHS-SOF / WIMD loaders
├── adapters/
│   └── rugby.py        # URC adapter
└── tests/
```

## Distance convention

Only **D3** is licensed going forward (`d = p^{-k*}` at first digit disagreement). D2 lives in `legacy_d2.py` for audit only.

See `FOUNDATION.md` §1.2 and ruling R6.

## Sync

Copy the full directory from your local repository. See `docs/MIGRATION.md`.
