#!/usr/bin/env bash
# One-time setup: sync local p-adic-systems content into the GitHub monorepo.
# Run on your Mac after PR #1 is merged:
#   bash scripts/mac_one_time_setup.sh
#
# Safe to re-run: rsync and git only add missing/changed files.

set -euo pipefail

GITHUB_URL="${GITHUB_URL:-https://github.com/AroundInteger/padic-sports-framework.git}"
# After you rename the repo in GitHub settings, override:
#   GITHUB_URL=https://github.com/AroundInteger/p-adic-systems.git bash scripts/mac_one_time_setup.sh

CANON="${CANON:-$HOME/Documents/GitHub/p-adic-systems}"
WORK="${WORK:-$HOME/Documents/GitHub/p-adic-systems-sync}"
CLAUDE_ARCHIVE="${CLAUDE_ARCHIVE:-$HOME/Documents/Claude/Projects/p-adic applications in sport}"

echo "=== p-adic-systems Mac one-time setup ==="
echo "Canonical folder: $CANON"
echo "GitHub remote:      $GITHUB_URL"
echo

# --- 1. Clone or update GitHub monorepo ---
if [[ -d "$CANON/.git" ]]; then
  echo "[1/6] Using existing git repo at $CANON"
  cd "$CANON"
  git remote set-url origin "$GITHUB_URL" 2>/dev/null || git remote add origin "$GITHUB_URL"
  git fetch origin
  git checkout main 2>/dev/null || git checkout -B main
  git merge origin/main --no-edit || {
    echo "Merge conflicts — resolve manually, then: git add -A && git commit"
    exit 1
  }
  REPO="$CANON"
else
  echo "[1/6] Cloning GitHub monorepo to $WORK"
  rm -rf "$WORK"
  git clone "$GITHUB_URL" "$WORK"
  cd "$WORK"
  REPO="$WORK"
  if [[ -d "$CANON" && "$CANON" != "$WORK" ]]; then
    echo "      Local $CANON exists without git — will rsync content into $WORK"
  fi
fi

# --- 2. Rsync content from non-git local folder if needed ---
if [[ -d "$CANON" && "$CANON" != "$REPO" ]]; then
  echo "[2/6] Copying content from $CANON into $REPO"
  rsync -av --ignore-existing "$CANON/pipeline/" "$REPO/pipeline/" 2>/dev/null || true
  rsync -av "$CANON/pipeline/padic_pef/" "$REPO/pipeline/padic_pef/" 2>/dev/null || true
  rsync -av "$CANON/docs/" "$REPO/docs/" 2>/dev/null || true
  rsync -av "$CANON/data/rugby/" "$REPO/data/rugby/" 2>/dev/null || true
  for phase in validation_results_phase1 validation_results_phase2 validation_results_phase3 validation_results_phase3_corrected; do
    [[ -d "$CANON/$phase" ]] && rsync -av "$CANON/$phase/" "$REPO/$phase/" 2>/dev/null || true
  done
  # Audit MATLAB at repo root → MATLAB/
  mkdir -p "$REPO/MATLAB"
  for f in enhanced_padic_rugby_pipeline.m perfect_padic_rugby_optimized.m \
           rugby_padic_functions.m phase_1_validation_suite.m \
           phase_2_validation_suite.m phase_3_validation_suite.m \
           phase_3_corrected_validation_suite.m; do
    [[ -f "$CANON/$f" ]] && cp -n "$CANON/$f" "$REPO/MATLAB/" 2>/dev/null || true
    [[ -f "$CANON/MATLAB/$f" ]] && cp -n "$CANON/MATLAB/$f" "$REPO/MATLAB/" 2>/dev/null || true
  done
else
  echo "[2/6] Single repo at $REPO — moving any root-level audit .m into MATLAB/"
  cd "$REPO"
  mkdir -p MATLAB
  for f in enhanced_padic_rugby_pipeline.m perfect_padic_rugby_optimized.m rugby_padic_functions.m; do
    [[ -f "$f" ]] && git mv "$f" MATLAB/ 2>/dev/null || mv "$f" MATLAB/ 2>/dev/null || true
  done
fi

cd "$REPO"

# --- 3. FOUNDATION.md: local wins if present ---
if [[ -f "$CANON/FOUNDATION.md" && "$CANON/FOUNDATION.md" != "$REPO/FOUNDATION.md" ]]; then
  echo "[3/6] Installing authoritative FOUNDATION.md from $CANON"
  cp "$CANON/FOUNDATION.md" "$REPO/FOUNDATION.md"
else
  echo "[3/6] Keeping repo FOUNDATION.md (no separate local copy found)"
fi

# --- 4. Verify key paths ---
echo "[4/6] Verifying layout"
missing=0
for path in FOUNDATION.md MATLAB/run_framework.m pipeline/padic_pef docs/MIGRATION.md; do
  if [[ ! -e "$path" ]]; then
    echo "  MISSING: $path"
    missing=$((missing + 1))
  fi
done
if [[ -f data/rugby/rugby_analysis_ready.csv ]]; then
  lines=$(wc -l < data/rugby/rugby_analysis_ready.csv | tr -d ' ')
  echo "  data/rugby/rugby_analysis_ready.csv: $lines lines"
else
  echo "  WARN: data/rugby/rugby_analysis_ready.csv not found — copy manually"
fi
if [[ -f pipeline/padic_pef/cluster.py ]]; then
  echo "  pipeline/padic_pef/cluster.py: present"
else
  echo "  WARN: Python pipeline not synced — copy pipeline/padic_pef/ from local"
  missing=$((missing + 1))
fi

# --- 5. Commit and push ---
echo "[5/6] Git commit and push"
git add -A
if git diff --cached --quiet; then
  echo "  Nothing new to commit."
else
  git commit -m "Sync local p-adic-systems content into monorepo (Mac setup script)."
fi
git push -u origin main

# --- 6. Claude archive marker (R9) ---
echo "[6/6] Claude off-shoot archive marker"
if [[ -d "$CLAUDE_ARCHIVE" ]]; then
  cat > "$CLAUDE_ARCHIVE/ARCHIVE_DO_NOT_EDIT.txt" << EOF
Archive as of $(date +%Y-%m-%d).
Canonical repo: $REPO
GitHub: $GITHUB_URL
Do not edit this folder in parallel with the canonical repo (FOUNDATION.md ruling R9).
EOF
  echo "  Wrote $CLAUDE_ARCHIVE/ARCHIVE_DO_NOT_EDIT.txt"
else
  echo "  Claude archive folder not found — skip or set CLAUDE_ARCHIVE=..."
  cp docs/ARCHIVE_DO_NOT_EDIT.txt /tmp/ARCHIVE_DO_NOT_EDIT.txt 2>/dev/null || true
  echo "  Template at docs/ARCHIVE_DO_NOT_EDIT.txt — copy manually if needed"
fi

echo
echo "=== Done ==="
echo "Repo: $REPO"
echo
echo "Manual step remaining (GitHub UI — token cannot rename repos):"
echo "  Settings → rename padic-sports-framework → p-adic-systems"
echo "  Then: git remote set-url origin https://github.com/AroundInteger/p-adic-systems.git"
echo
echo "Verify Python:  cd pipeline/padic_pef && python3 -m pytest tests/ -q"
echo "Verify MATLAB:  cd('$REPO'); addpath('MATLAB'); run_framework"

if [[ "$missing" -gt 0 ]]; then
  echo
  echo "WARNING: $missing critical path(s) missing — see docs/MIGRATION.md"
  exit 1
fi
