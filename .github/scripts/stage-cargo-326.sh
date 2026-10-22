#!/usr/bin/env bash
# ================================================================
# stage-cargo-326.sh — builds the 326 student repo's file set from
# variants/326/ in a gantry checkout.
#
# Used by .github/workflows/sync-cargo-326.yml; can be run by hand
# for a dry run into an empty folder.
#
# Usage: stage-cargo-326.sh <gantry-repo-root> <target-dir>
# ================================================================
set -euo pipefail

SRC="$1"
DEST="$2"
V="$SRC/variants/326"

mkdir -p "$DEST"

# The student .devcontainer is exactly variants/326/devcontainer/.
# --delete clears out anything left from the full gantry template.
rsync -a --delete "$V/devcontainer/" "$DEST/.devcontainer/"

rsync -a --delete "$SRC/doc/" "$DEST/doc/"

# Root files. README.md is never copied: the target repo owns it.
cp "$V/root/.env.example" "$DEST/.env.example"
cp "$V/root/.gitignore" "$DEST/.gitignore"
cp "$V/root/.gitattributes" "$DEST/.gitattributes"
mkdir -p "$DEST/work"
cp "$V/root/work/README.md" "$DEST/work/README.md"

find "$DEST" -name ".DS_Store" -delete
