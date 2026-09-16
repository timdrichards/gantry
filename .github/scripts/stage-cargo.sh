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
cp "$SRC/README.md" "$DEST/README.md"
cp "$SRC/.gitignore" "$DEST/.gitignore"
cp "$SRC/.gitattributes" "$DEST/.gitattributes"

mkdir -p "$DEST/work"
cp "$SRC/work/README.md" "$DEST/work/README.md"

find "$DEST" -name ".DS_Store" -delete
