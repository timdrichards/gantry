# Plugin Developer Guide

This guide covers how to create, structure, and publish a Gantry plugin.
Plugins extend the dev container with new CLI commands and shell integrations
without requiring a container rebuild.

---

## Quickstart

```bash
plugin new my-plugin --description "What my plugin does" --author "Your Name"
```

This scaffolds the full directory structure, writes starter files, and makes an
initial git commit. Your current terminal picks it up automatically — run
`my-plugin help` to confirm.

---

## Directory Structure

Every plugin is a git repository cloned into `/gantry/.plugins/<name>/`.

```
my-plugin/
├── plugin.json       # Manifest — required
├── bin/              # Executables added to PATH
│   └── my-plugin     # Main command — must match plugin name
├── lib/
│   └── shell.sh      # Aliases and functions sourced at login
└── docs/
    └── README.md     # End-user documentation
```

All four top-level entries are required. The manifest is validated on install;
missing or empty `name`, `version`, or `description` fields are a hard error.

---

## plugin.json Manifest

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "A short description shown in plugin list",
  "author": "Your Name",
  "repository": "https://github.com/you/my-plugin.git",
  "dependencies": [],
  "env": {}
}
```

| Field          | Required | Notes |
|----------------|----------|-------|
| `name`         | yes      | Must match `[a-zA-Z0-9_-]+` and the `bin/` executable name |
| `version`      | yes      | Any semver-style string |
| `description`  | yes      | One line; shown in `plugin list` and `plugin docs` |
| `author`       | no       | Used by `plugin new` default; informational |
| `repository`   | no       | HTTPS URL; set automatically by `plugin publish` |
| `dependencies` | no       | Array of plugin names or `{"name": "x", "url": "..."}` objects |
| `env`          | no       | Key/value pairs exported into every shell session via the loader |

---

## Required bin Script Format

Every plugin's main command **must** follow this structure. The plugin manager
generates this template via `plugin new`; maintain it as you add subcommands.

### Structure

```bash
#!/usr/bin/env bash
# <name> — one-line description

set -euo pipefail

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "  → $*"; }
warn() { echo "  ⚠  $*" >&2; }

cmd_<subcommand>() {
  # implementation
}

cmd_help() {
  cat << 'HELPEOF'
  ...help text (see format below)...
HELPEOF
}

main() {
  local cmd="${1:-help}"
  shift || true
  case "$cmd" in
    <subcommand>)    cmd_<subcommand> "$@" ;;
    help|--help|-h)  cmd_help ;;
    *) die "Unknown command '${cmd}'. Run '<name> help' for usage." ;;
  esac
}

main "$@"
```

### Rules

- `set -euo pipefail` at the top — always.
- `die` / `info` / `warn` helpers — always include these three, verbatim.
- Each subcommand is a `cmd_<name>()` function.
- `main()` dispatches via `case` with `help` as the default.
- `help|--help|-h` all route to `cmd_help`.
- Unknown subcommands call `die` and suggest `<name> help`.

### Required Help Format

The `cmd_help` function prints to stdout via a single `cat << 'HELPEOF'` block.
Use this exact heading structure (two-space indent throughout):

```
  <name> — one-line description

  SUBCOMMANDS

    <subcommand> [options]
        What this subcommand does, in one or two sentences.

        --flag <value>   What the flag controls (default: x)

    help
        Show this help text.

  EXAMPLES

    <name> <subcommand>
    <name> <subcommand> --flag value
```

**Headings:** `SETUP`, `SUBCOMMANDS`, `OPTIONS`, `EXAMPLES` — all caps, no
colon, separated by blank lines. Use `SETUP` when environment variables or
prerequisites are required before the command works.

**Subcommand entries:** name on its own line, indented four spaces; description
indented eight spaces. Flags listed below the description, also at eight spaces,
with values aligned in a column.

**Examples section:** always present, even for simple commands. One example per
common use case.

### Example — plugin with a SETUP section

```
  my-plugin — fetch data from the Acme API

  SETUP

    Two environment variables are required:

      ACME_DOMAIN     Your Acme tenant hostname, e.g. tenant.acme.com
      ACME_API_TOKEN  API token from Acme → Settings → Access Tokens

  SUBCOMMANDS

    fetch <resource> [options]
        Download a resource from the Acme API and print it as JSON.

        --limit <n>    Maximum number of records to return (default: 100)
        --format <f>   Output format: json | csv (default: json)

    help
        Show this help text.

  EXAMPLES

    my-plugin fetch orders
    my-plugin fetch orders --limit 50
    my-plugin fetch products --format csv
```

---

## lib/shell.sh

Sourced into every shell session automatically. Keep it lightweight — this runs
on every terminal open.

```bash
# my-plugin — shell integration

alias mp='my-plugin'

my-plugin-status() {
  my-plugin status 2>/dev/null || echo "my-plugin: not configured"
}
```

- Prefix aliases and functions with the plugin name to avoid collisions.
- No `set -e` — sourcing a script with `set -e` affects the parent shell.
- No long-running operations or network calls at source time.

---

## docs/README.md

End-user documentation displayed by `plugin docs <name>`. Keep it concise:

```markdown
# my-plugin

One-paragraph description of what the plugin does.

## Installation

\`\`\`bash
plugin install https://github.com/you/my-plugin.git
\`\`\`

## Commands

| Command | Description |
|---------|-------------|
| `my-plugin fetch` | Fetch a resource from the API |
| `my-plugin help`  | Show full usage |

## Shell Aliases & Functions

| Name | Description |
|------|-------------|
| `mp` | Alias for `my-plugin` |

## Examples

\`\`\`bash
my-plugin fetch orders
my-plugin fetch orders --limit 50
\`\`\`
```

---

## Development Workflow

```bash
# 1. Scaffold
plugin new my-plugin --description "..." --author "..."

# 2. Edit the main command
$EDITOR /gantry/.plugins/my-plugin/bin/my-plugin

# 3. Edit shell integration (optional)
$EDITOR /gantry/.plugins/my-plugin/lib/shell.sh

# 4. Reload the current session to pick up changes
reload-env

# 5. Test
my-plugin help
my-plugin example

# 6. Commit changes
git -C /gantry/.plugins/my-plugin add .
git -C /gantry/.plugins/my-plugin commit -m "feat: add fetch subcommand"

# 7. Publish to GitHub when ready
plugin publish my-plugin
```

`reload-env` re-sources `.loader.sh` without opening a new terminal. Aliases and
functions defined in `lib/shell.sh` take effect immediately; PATH additions may
require a new shell.

---

## Security

- Plugin names are restricted to `[a-zA-Z0-9_-]` — this prevents path traversal.
- Non-HTTPS install URLs trigger a confirmation prompt.
- `lib/shell.sh` is sourced automatically after install. Run
  `plugin audit <name>` to print its contents before installing from an
  untrusted source.
- All plugin code runs as the `vscode` user — no root escalation is possible.
- Dependency loop detection prevents circular installs via the
  `$PLUGIN_DEP_CHAIN` environment variable.

---

## Publishing and Versioning

```bash
# Create a GitHub repo and push
plugin publish my-plugin

# Others install it with
plugin install https://github.com/you/my-plugin.git

# Pin to a specific tag for reproducible installs
plugin install https://github.com/you/my-plugin.git --pin v1.2.0
```

Tag-pinned plugins (`--pin v1.2.0`) are never touched by `plugin update --all`.
Branch-pinned plugins (`--pin main`) are updated normally. Unpinned plugins
track the default branch.

Bump `version` in `plugin.json` with each release so `plugin list` reflects the
current state.
