#!/usr/bin/env bash
# ================================================================
# stage-cargo.sh — builds the student distribution file set (the
# "cargo" repo content) from a gantry checkout.
#
# Used by .github/workflows/sync-cargo.yml on every push to main,
# and can be run by hand for a manual sync or dry run.
#
# Usage: stage-cargo.sh <gantry-repo-root> <target-dir>
# ================================================================
set -euo pipefail

SRC="$1"
DEST="$2"

mkdir -p "$DEST"

# .devcontainer/ minus developer-only docs/, and minus the two
# cargo-only local hooks (never present in gantry, so --exclude here
# just protects them from --delete if DEST already has them).
rsync -a --delete \
  --exclude 'docs/' \
  --exclude 'scripts/post-create.local.sh' \
  --exclude 'scripts/post-start.local.sh' \
  "$SRC/.devcontainer/" "$DEST/.devcontainer/"

rsync -a --delete "$SRC/doc/" "$DEST/doc/"

cp "$SRC/.env.example" "$DEST/.env.example"
# README.md is NOT copied — cargo owns its own root README.md (student-
# facing, written directly for cargo) same as gantry's own README.md is
# instructor-facing. Same reasoning as the post-*.local.sh hooks: this
# path is deliberately never touched by the sync.
cp "$SRC/.gitignore" "$DEST/.gitignore"
cp "$SRC/.gitattributes" "$DEST/.gitattributes"

mkdir -p "$DEST/work"
cp "$SRC/work/README.md" "$DEST/work/README.md"

find "$DEST" -name ".DS_Store" -delete
