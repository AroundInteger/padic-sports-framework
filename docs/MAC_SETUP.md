# Mac setup — what the cloud agent did vs what you run once

## Already done (cloud agent, September 2026)

| Step | Status |
|---|---|
| **1. Merge PR #1** | Done — monorepo structure is on `main` |
| **2. Sync local content** | **Cannot run from cloud** — your Mac files are not accessible |
| **3. Authoritative FOUNDATION.md** | Partial on GitHub — your local copy should overwrite via script |
| **4. Rename repo to `p-adic-systems`** | **Blocked** — GitHub token lacks admin rename permission |
| **5. Claude archive marker** | Script writes this when you run it locally |

## One command on your Mac

After opening Terminal:

```bash
cd ~/Documents/GitHub/p-adic-systems   # or clone first — see below
git pull origin main                   # get merged monorepo structure
bash scripts/mac_one_time_setup.sh
```

If you do not yet have the GitHub repo locally:

```bash
git clone https://github.com/AroundInteger/padic-sports-framework.git ~/Documents/GitHub/p-adic-systems-sync
CANON=~/Documents/GitHub/p-adic-systems \
WORK=~/Documents/GitHub/p-adic-systems-sync \
bash ~/Documents/GitHub/p-adic-systems-sync/scripts/mac_one_time_setup.sh
```

### Environment variables (optional)

| Variable | Default | Purpose |
|---|---|---|
| `CANON` | `~/Documents/GitHub/p-adic-systems` | Your local folder with pipeline, CSV, audit MATLAB |
| `GITHUB_URL` | `.../padic-sports-framework.git` | Remote URL (update after rename) |
| `CLAUDE_ARCHIVE` | `~/Documents/Claude/Projects/p-adic applications in sport` | Where to write R9 archive marker |

After you rename the repo on GitHub:

```bash
git remote set-url origin https://github.com/AroundInteger/p-adic-systems.git
```

## Step 4 — Rename repo (you, ~30 seconds)

The cloud agent cannot rename repositories. In a browser:

1. Open https://github.com/AroundInteger/padic-sports-framework/settings
2. **Repository name** → `p-adic-systems`
3. **Rename**
4. Update remote (command above)

## Verification

```bash
# Layout
ls FOUNDATION.md MATLAB/ pipeline/padic_pef/cluster.py data/rugby/rugby_analysis_ready.csv

# Python (after sync)
cd pipeline/padic_pef && python3 -m pytest tests/ -q

# Row count
wc -l data/rugby/rugby_analysis_ready.csv   # expect 1129 (header + 1128)
```

MATLAB (from repo root):

```matlab
cd('/Users/rowanbrown/Documents/GitHub/p-adic-systems')
addpath('MATLAB')
run_framework
```

## If the script reports missing files

Your local `p-adic-systems` folder is the source of truth for:

- `pipeline/padic_pef/` (full Python package)
- `docs/*.md`, `docs/Paper/*.tex`
- `data/rugby/rugby_analysis_ready.csv`
- Audit `.m` files and `validation_results_phase*/`

See `docs/MIGRATION.md` for the full table.
