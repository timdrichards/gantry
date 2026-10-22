#!/usr/bin/env bash
# ================================================================
# post-create.sh — runs once, the first time the container starts.
# Kept small on purpose: everything slow is already in the image.
# ================================================================
set -euo pipefail

git config --global --add safe.directory /gantry
git config --global init.defaultBranch main

# HTTPS git through gh when signed in (local Docker; Codespaces has
# its own credential helper already).
if [[ -z "${CODESPACES:-}" ]] && command -v gh &>/dev/null; then
  gh auth setup-git 2>/dev/null || true
fi

# 'upstream' points at the course template so cargo-update works.
if ! git -C /gantry remote get-url upstream &>/dev/null; then
  git -C /gantry remote add upstream https://github.com/timdrichards/cargo.git 2>/dev/null || true
fi

if [[ ! -f /gantry/.bashrc.user ]]; then
  cat > /gantry/.bashrc.user << 'BASHRC'
# Your own aliases and variables go here (this file is not committed).
# Run `reload-env` in an open terminal to apply changes.
BASHRC
fi

echo "✅ Setup complete."
