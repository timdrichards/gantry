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

# ---- Configure gh as Git credential helper (HTTPS remotes) ----
# This means `git push` over HTTPS works automatically once gh is authed.
if command -v gh &>/dev/null; then
  gh auth setup-git 2>/dev/null || true
fi

# ---- Create user bashrc if it doesn't exist --------------------
if [[ ! -f /workspace/.bashrc.user ]]; then
  cat > /workspace/.bashrc.user << 'BASHRC'
# ================================================================
# User Shell Customization — /workspace/.bashrc.user
# ================================================================
# Add your own aliases, environment variables, and functions here.
#
#   • Run `reload-env` in any open terminal to apply changes.
#   • New terminals will load this file automatically.
#   • This file is gitignored by default. Remove the .gitignore
#     entry if you want to commit your customizations.
# ================================================================

# Examples (uncomment to use):
# alias ll='ls -lAh --color=auto'
# export MY_API_KEY=...
# my-func() { echo "hello"; }
BASHRC
fi

# ---- Initialize plugin directory and registry ------------------
if [[ ! -d /workspace/.plugins ]]; then
  mkdir -p /workspace/.plugins
  echo '{"plugins":{}}' > /workspace/.plugins/.registry.json
  echo "🔌 Plugin directory created at /workspace/.plugins"
fi
if [[ ! -f /workspace/.plugins/.registry.json ]]; then
  echo '{"plugins":{}}' > /workspace/.plugins/.registry.json
fi
if [[ ! -f /workspace/.plugins/plugins-README.md ]]; then
  cat > /workspace/.plugins/plugins-README.md << 'EOF'
# Dev Container Plugins

Plugins extend the dev container with custom commands, scripts, and tools.
Each plugin is a git repository cloned into this directory.

## Directory Structure

```
.plugins/
├── .registry.json      # Plugin registry (managed automatically)
├── .loader.sh          # Auto-generated shell loader (do not edit)
├── plugins-README.md   # This file
└── <plugin-name>/      # Each installed plugin
    ├── plugin.json     # Manifest: name, version, description, dependencies
    ├── bin/            # Executables added to PATH
    ├── lib/
    │   └── shell.sh    # Shell aliases/functions sourced at login
    └── docs/
        └── README.md   # Plugin documentation
```

## Managing Plugins

```bash
plugin install <git-url>                # Install a plugin
plugin install <git-url> --pin v1.0.0  # Pin to a specific tag or branch
plugin list                             # List installed plugins
plugin remove <name>                    # Uninstall a plugin
plugin update --all                     # Update all plugins
plugin docs [name]                      # View plugin documentation
plugin audit <name>                     # Inspect lib/shell.sh before sourcing
plugin check-updates                    # Check for available updates
plugin help                             # Full usage guide
```

## Plugin Manifest (plugin.json)

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What this plugin does",
  "author": "Your Name",
  "repository": "https://github.com/you/my-plugin",
  "dependencies": [],
  "env": {}
}
```
EOF
fi

echo "✅ post-create complete."
