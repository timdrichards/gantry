#!/usr/bin/env bash
# ================================================================
# post-start.sh — runs every time the container starts.
# ================================================================
set -uo pipefail

# Let vscode (in the docker group) use the host Docker socket.
if [ -S /var/run/docker.sock ]; then
  sudo chown root:docker /var/run/docker.sock 2>/dev/null || true
fi

if [[ -z "$(git config --global user.name 2>/dev/null)" || -z "$(git config --global user.email 2>/dev/null)" ]]; then
  echo "⚠️  Set your git name and email once:"
  echo '     git config --global user.name  "Your Name"'
  echo '     git config --global user.email "you@example.com"'
fi

# Template update check, at most every 6 hours, in the background so
# it never delays start-up.
(
  marker="${HOME}/.cache/gantry-upstream-check"
  mkdir -p "${HOME}/.cache"
  now=$(date +%s); last=$(cat "$marker" 2>/dev/null || echo 0)
  if (( now - last > 21600 )) && git -C /gantry remote get-url upstream &>/dev/null; then
    echo "$now" > "$marker"
    if git -C /gantry fetch upstream main --quiet 2>/dev/null; then
      behind=$(git -C /gantry rev-list --count HEAD..upstream/main 2>/dev/null || echo 0)
      if (( behind > 0 )); then
        echo "📦 ${behind} update(s) available from the course template. Run 'cargo-update'."
      fi
    fi
  fi
) &
