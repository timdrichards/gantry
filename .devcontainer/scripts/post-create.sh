#!/usr/bin/env bash
# ================================================================
# post-create.sh — runs ONCE after the devcontainer is built
# ================================================================
set -euo pipefail

echo "🔧 Running post-create setup..."

# ---- Configure git (safe directory for mounted workspace) ------
git config --global --add safe.directory /workspace

# ---- Bash history file -----------------------------------------
sudo mkdir -p /commandhistory
sudo touch /commandhistory/.bash_history
sudo chown -R "${USER}:${USER}" /commandhistory

# ---- Install workspace npm deps if package.json exists ---------
if [[ -f /workspace/package.json ]]; then
  echo "📦 Installing npm dependencies..."
  cd /workspace && npm install
fi

# ---- Prisma generate if schema exists --------------------------
if [[ -f /workspace/prisma/schema.prisma ]]; then
  echo "🗄️  Generating Prisma client..."
  cd /workspace && npx prisma generate
fi

echo "✅ post-create complete."
