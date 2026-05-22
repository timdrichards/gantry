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

echo "🌐 Network 'webdev' containers:"
docker network inspect webdev \
  --format '{{range .Containers}}     • {{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}' \
  2>/dev/null || echo "   (none yet — start services with dc-up <service>)"
