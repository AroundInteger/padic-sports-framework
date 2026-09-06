#!/usr/bin/env bash
# One-time setup: sync local p-adic-systems content into the GitHub monorepo.
#
# Works even when ~/Documents/GitHub/p-adic-systems is NOT yet a git repo.
#
#   bash scripts/mac_one_time_setup.sh
#
# Or download script only (no git yet):
#   curl -fsSL https://raw.githubusercontent.com/AroundInteger/padic-sports-framework/main/scripts/mac_one_time_setup.sh -o /tmp/mac_one_time_setup.sh
#   bash /tmp/mac_one_time_setup.sh

set -euo pipefail

GITHUB_URL="${GITHUB_URL:-https://github.com/AroundInteger/padic-sports-framework.git}"
CANON="${CANON:-$HOME/Documents/GitHub/p-adic-systems}"
CLAUDE_ARCHIVE="${CLAUDE_ARCHIVE:-$HOME/Documents/Claude/Projects/p-adic applications in sport}"

echo "=== p-adic-systems Mac one-time setup ==="
echo "Target folder:  $CANON"
echo "GitHub remote:  $GITHUB_URL"
echo

merge_local_into_repo() {
  local src="$1"
  local dst="$2"
  echo "      Merging local content from $src"
  mkdir -p "$dst/pipeline/padic_pef" "$dst/docs" "$dst/docs/Paper" "$dst/data/rugby" "$dst/MATLAB"
  rsync -av "$src/pipeline/padic_pef/" "$dst/pipeline/padic_pef/" 2>/dev/null || true
  rsync -av "$src/docs/" "$dst/docs/" 2>/dev/null || true
  rsync -av "$src/data/rugby/" "$dst/data/rugby/" 2>/dev/null || true
  for phase in validation_results_phase1 validation_results_phase2 \
               validation_results_phase3 validation_results_phase3_corrected; do
    [[ -d "$src/$phase" ]] && rsync -av "$src/$phase/" "$dst/$phase/" 2>/dev/null || true
  done
  for f in enhanced_padic_rugby_pipeline.m perfect_padic_rugby_optimized.m \
           rugby_padic_functions.m phase_1_validation_suite.m \
           phase_2_validation_suite.m phase_3_validation_suite.m \
           phase_3_corrected_validation_suite.m; do
    [[ -f "$src/$f" ]] && cp -n "$src/$f" "$dst/MATLAB/" 2>/dev/null || true
    [[ -f "$src/MATLAB/$f" ]] && cp -n "$src/MATLAB/$f" "$dst/MATLAB/" 2>/dev/null || true
  done
  if [[ -f "$src/FOUNDATION.md" ]]; then
    cp "$src/FOUNDATION.md" "$dst/FOUNDATION.md"
    echo "      Installed FOUNDATION.md from local copy"
  fi
}

# --- 1. Ensure CANON is a git clone of GitHub ---
if [[ -d "$CANON/.git" ]]; then
  echo "[1/6] Updating existing git repo at $CANON"
  cd "$CANON"
  git remote set-url origin "$GITHUB_URL" 2>/dev/null || git remote add origin "$GITHUB_URL"
  git fetch origin
  git checkout main 2>/dev/null || git checkout -B main
  git merge origin/main --no-edit || {
    echo "Merge conflicts — resolve, then: git add -A && git commit"
    exit 1
  }
  REPO="$CANON"
else
  echo "[1/6] No git repo at $CANON — bootstrapping from GitHub"
  PARENT="$(dirname "$CANON")"
  BASE="$(basename "$CANON")"
  CLONE_TMP="$PARENT/${BASE}.git-bootstrap-$$"
  LOCAL_BACKUP=""

  if [[ -d "$CANON" ]] && [[ -n "$(ls -A "$CANON" 2>/dev/null | grep -v '^\.DS_Store$' || true)" ]]; then
    LOCAL_BACKUP="$PARENT/${BASE}-local-backup-$$"
    echo "      Saving your local files to $LOCAL_BACKUP"
    mv "$CANON" "$LOCAL_BACKUP"
  fi

  git clone "$GITHUB_URL" "$CLONE_TMP"
  mv "$CLONE_TMP" "$CANON"
  REPO="$CANON"
  cd "$REPO"

  if [[ -n "$LOCAL_BACKUP" ]]; then
    echo "[2/6] Merging local backup into git clone"
    merge_local_into_repo "$LOCAL_BACKUP" "$REPO"
    echo "      Local backup kept at: $LOCAL_BACKUP"
    echo "      (Delete manually once you have verified everything works.)"
  else
    echo "[2/6] Fresh clone — no local files to merge"
  fi
fi

cd "$REPO"

# --- 2. If git repo but extra local source specified ---
if [[ -n "${LOCAL_SRC:-}" && -d "$LOCAL_SRC" && "$LOCAL_SRC" != "$REPO" ]]; then
  echo "[2/6] Merging LOCAL_SRC=$LOCAL_SRC"
  merge_local_into_repo "$LOCAL_SRC" "$REPO"
elif [[ -d "$REPO/.git" && "$REPO" == "$CANON" && -z "${LOCAL_BACKUP:-}" ]]; then
  echo "[2/6] Moving any audit .m files at repo root into MATLAB/"
  mkdir -p MATLAB
  for f in enhanced_padic_rugby_pipeline.m perfect_padic_rugby_optimized.m rugby_padic_functions.m; do
    [[ -f "$f" ]] && git mv "$f" MATLAB/ 2>/dev/null || mv "$f" MATLAB/ 2>/dev/null || true
  done
fi

# --- 3. Verify layout ---
echo "[3/6] Verifying layout"
missing=0
for path in FOUNDATION.md MATLAB/run_framework.m docs/MIGRATION.md scripts/mac_one_time_setup.sh; do
  if [[ ! -e "$path" ]]; then
    echo "  MISSING: $path"
    missing=$((missing + 1))
  fi
done
if [[ -f data/rugby/rugby_analysis_ready.csv ]]; then
  lines=$(wc -l < data/rugby/rugby_analysis_ready.csv | tr -d ' ')
  echo "  data/rugby/rugby_analysis_ready.csv: $lines lines"
else
  echo "  WARN: data/rugby/rugby_analysis_ready.csv not found"
fi
if [[ -f pipeline/padic_pef/cluster.py ]]; then
  echo "  pipeline/padic_pef/cluster.py: present"
else
  echo "  WARN: Python pipeline not present — should have merged from local backup"
  missing=$((missing + 1))
fi

# --- 4. Commit and push ---
echo "[4/6] Git commit and push"
git add -A
if git diff --cached --quiet; then
  echo "  Nothing new to commit."
else
  git commit -m "Sync local p-adic-systems content into monorepo (Mac setup script)."
fi
git push -u origin main

# --- 5. Claude archive marker (R9) ---
echo "[5/6] Claude off-shoot archive marker"
if [[ -d "$CLAUDE_ARCHIVE" ]]; then
  cat > "$CLAUDE_ARCHIVE/ARCHIVE_DO_NOT_EDIT.txt" << EOF
Archive as of $(date +%Y-%m-%d).
Canonical repo: $REPO
GitHub: $GITHUB_URL
Do not edit this folder in parallel with the canonical repo (FOUNDATION.md ruling R9).
EOF
  echo "  Wrote $CLAUDE_ARCHIVE/ARCHIVE_DO_NOT_EDIT.txt"
else
  echo "  Claude folder not found — template at docs/ARCHIVE_DO_NOT_EDIT.txt"
fi

echo "[6/6] Done"
echo
echo "Repo ready at: $REPO"
echo
echo "Optional — rename on GitHub (Settings): padic-sports-framework → p-adic-systems"
echo "  git remote set-url origin https://github.com/AroundInteger/p-adic-systems.git"
echo
echo "Verify:"
echo "  cd '$REPO' && cd pipeline/padic_pef && python3 -m pytest tests/ -q"
echo "  MATLAB: cd('$REPO'); addpath('MATLAB'); run_framework"

if [[ "$missing" -gt 0 ]]; then
  echo
  echo "WARNING: $missing item(s) missing — check local backup folder for pipeline/docs/data"
  exit 1
fi
