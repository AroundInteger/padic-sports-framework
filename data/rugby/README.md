# Rugby data — falsification platform

**Canonical file:** `rugby_analysis_ready.csv` (not committed here — copy from local worktree).

## Expected contents (per FOUNDATION.md §2.1)

- 16 URC teams
- 1,128 team-match rows (564 fixtures, each match twice)
- Seasons 21/22, 22/23, 23/24, 24/25

## Unit of analysis

Clustering is on **16 teams** (team-level feature means), not 1,128 match rows. See ruling R3.

## Example CSVs

Teaching-bridge examples with a simpler schema live in `data/examples/rugby_sample.csv`. Do not substitute them for `rugby_analysis_ready.csv` in audit reproductions.
