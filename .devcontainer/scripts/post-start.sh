#!/usr/bin/env bash
# ================================================================
# post-start.sh — runs every time the devcontainer starts
# ================================================================
set -euo pipefail

echo "🚀 Dev container started."

# Verify Docker socket is accessible
if docker info &>/dev/null; then
  echo "🐳 Docker socket: OK"
  echo "   Active containers:"
  docker ps --format "     • {{.Names}} ({{.Status}})" 2>/dev/null || true
else
  echo "⚠️  Docker socket not yet available — DinD may still be initialising."
fi

echo "🌐 Network 'gantry' containers:"
docker network inspect gantry \
  --format '{{range .Containers}}     • {{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}' \
  2>/dev/null || echo "   (none yet — start services with dc-up <service>)"

# SSH key permissions — Docker bind-mounts can inherit loose host permissions
# which cause SSH to reject the keys. Normalise them on every start.
if [ -d "${HOME}/.ssh" ]; then
  chmod 700 "${HOME}/.ssh" 2>/dev/null || true
  find "${HOME}/.ssh" -maxdepth 1 -type f ! -name "*.pub" \
    -exec chmod 600 {} \; 2>/dev/null || true
  find "${HOME}/.ssh" -maxdepth 1 -name "*.pub" \
    -exec chmod 644 {} \; 2>/dev/null || true
fi

# Git identity check — runs on every start so users are reminded after a rebuild
_GIT_NAME=$(git config --global user.name 2>/dev/null || true)
_GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)
if [[ -z "$_GIT_NAME" || -z "$_GIT_EMAIL" ]]; then
  echo "⚠️  Git identity not configured. Run:"
  echo '     git config --global user.name  "Your Name"'
  echo '     git config --global user.email "you@example.com"'
else
  echo "🔑 Git identity: ${_GIT_NAME} <${_GIT_EMAIL}>"
fi
unset _GIT_NAME _GIT_EMAIL

# GitHub CLI auth status
if gh auth status &>/dev/null; then
  GH_USER=$(gh api user --jq .login 2>/dev/null || echo "unknown")
  echo "🐙 GitHub CLI: authenticated as ${GH_USER}"
else
  echo "⚠️  GitHub CLI: not authenticated"
  echo "   Mac/Linux — run 'gh auth login' on the host then rebuild the container"
  echo "   Windows   — set GH_TOKEN in host environment variables then rebuild"
  echo "   Or        — run 'gh auth login' directly in this terminal"
fi

# ---- Plugin loader + auto-update --------------------------------
if [[ -f /gantry/.plugins/.registry.json ]]; then
  # Regenerate loader synchronously so commands are available the moment
  # the first terminal opens, regardless of any background activity.
  bash /gantry/.devcontainer/scripts/plugin-manager.sh generate-loader 2>/dev/null || true

  plugin_count=$(jq '.plugins | length' /gantry/.plugins/.registry.json 2>/dev/null || echo 0)
  if [[ "$plugin_count" -gt 0 ]]; then
    echo "🔌 Auto-updating ${plugin_count} plugin(s) in background..."
    bash /gantry/.devcontainer/scripts/plugin-manager.sh update --all --quiet &
  fi
fi
