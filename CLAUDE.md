# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A VS Code dev container configuration template for web development projects. There is no application code — the entire repo is infrastructure configuration. There are no build, test, or lint commands to run on the repo itself.

## Repository Layout

```
.devcontainer/
├── devcontainer.json          # VS Code spec: mounts, extensions, settings, lifecycle hooks
├── compose.yml         # Primary container + all optional sidecar services
├── Dockerfile                 # Image build for the devcontainer service
├── shell/.bashrc_devcontainer # Aliases/functions sourced in every container bash session
├── scripts/post-create.sh     # Runs once after image build
├── scripts/post-start.sh      # Runs on every container start
├── scripts/plugin-manager.sh  # Plugin management (install/remove/update/list/docs)
├── services/                  # Config files bind-mounted into specific sidecars
│   ├── caddy/Caddyfile
│   ├── mongo/init/01-init.js
│   ├── nginx/nginx.conf + conf.d/default.conf
│   ├── postgres/init/01-init.sql
│   ├── prometheus/prometheus.yml
│   └── redpanda/console-config.yml
.gitattributes                 # Enforces LF for .sh, .yml, .yaml, Dockerfile, Caddyfile
.env.example                   # Connection strings using Docker network hostnames
```

## When a Container Rebuild Is Required

| Change | Action needed |
|---|---|
| `Dockerfile` | Full rebuild (Cmd+Shift+P → "Rebuild Container") |
| `devcontainer.json` (mounts, features, remoteEnv) | Full rebuild |
| `compose.yml` | Rebuild or `dc-down && dc-up <service>` for sidecars |
| `shell/.bashrc_devcontainer` | `source /etc/bash_devcontainer` — no rebuild |
| `scripts/post-create.sh` | Rebuild (runs once, at build time) |
| `scripts/post-start.sh` | Container restart — no rebuild |
| `scripts/plugin-manager.sh` | No rebuild — called fresh as `bash ...` on every invocation |
| `services/*` config files | Restart the affected sidecar — no rebuild |

## Architecture

### Network
All containers share the `gantry` bridge network (`172.28.0.0/16`). Every service is reachable from every other service by its hostname (e.g., `postgres:5432`, `redis:6379`, `redpanda:9092`). Connection strings in `.env.example` use these hostnames, not `localhost`.

### Service Profiles
Sidecar services are gated by Compose profiles and never start automatically. Start them with the `dc-up` alias from inside the container:

```bash
dc-up redis postgres     # start specific services
dc-up --profile full     # start everything (excludes caddy — conflicts with nginx on 80/443)
```

Profile names match service names: `postgres`, `mongo`, `redis`, `mysql`, `rabbitmq`, `elastic`, `memcached`, `mailpit`, `minio`, `redpanda`, `observability`, `nginx`, `caddy`, `adminer`, `vector`, `meilisearch`, `nats`, `keycloak`.

### Docker-outside-of-Docker
The host Docker socket (`/var/run/docker.sock`) is bind-mounted into the devcontainer. All `docker` and `docker compose` commands inside the container talk to the host daemon. Sidecar containers are therefore siblings of the devcontainer, not children. This is why `dc exec <service>` can fail if the sidecar was started under a different compose project name — `dexb` works around this by using the `com.docker.compose.service` label instead.

### `${LOCAL_WORKSPACE_FOLDER}` in compose.yml
Used in volume bind mounts for service config files (e.g., `${LOCAL_WORKSPACE_FOLDER}/.devcontainer/services/postgres/init`). VS Code passes this as a host environment variable when invoking docker compose. On Windows, Docker Desktop handles path translation automatically.

## Plugin System

Plugins live in `/workspace/.plugins/` (bind-mounted, persists without rebuild, hidden from VS Code explorer).

### Key Locations
- **Registry**: `/workspace/.plugins/.registry.json` — tracks installed plugins with URL, pin, and install timestamp
- **Loader**: `/workspace/.plugins/.loader.sh` — auto-generated; sourced at every login; adds `bin/` to PATH, sources `lib/shell.sh`, exports `env` vars
- **Manager script**: `.devcontainer/scripts/plugin-manager.sh` — called fresh via `bash ...` on each invocation via the `plugin()` shell function

### Plugin Repo Structure
Each plugin is a git repo cloned into `/workspace/.plugins/<name>/`:
```
plugin-name/
├── plugin.json      # Manifest: name, version, description, author, repository, dependencies, env
├── bin/             # Executables added to PATH
├── lib/shell.sh     # Aliases/functions sourced at login
└── docs/README.md   # Documentation
```

### Plugin Commands
- `plugin install <git-url> [--pin <ref>]` — clone, validate, confirm shell.sh, install
- `plugin remove <name>` — remove directory and deregister
- `plugin update [name|--all]` — git pull; tag-pinned plugins are skipped (immutable)
- `plugin list` — tabular view: name, version, git hash, pin, description
- `plugin docs [name]` — view `docs/README.md` with bat/less; without name lists summaries
- `plugin check-updates` — fetch and compare HEAD vs origin for each plugin
- `plugin audit <name>` — print `lib/shell.sh` contents for review before sourcing
- `plugin help` — full usage guide

### Security Model
- Non-HTTPS URLs prompt a warning and require confirmation
- Manifest validation enforces required fields (`name`, `version`, `description`)
- Plugin names restricted to `[a-zA-Z0-9_-]` — prevents path traversal
- `plugin audit <name>` lets users inspect `lib/shell.sh` before it is ever sourced
- All plugin code runs as `vscode` user — no root escalation
- Dependency loop detection via `$PLUGIN_DEP_CHAIN` environment variable

### Auto-Update
`post-start.sh` runs `plugin update --all --quiet` in the background on every container start. Tag-pinned plugins are always skipped. Network failures are silently ignored.

## Key Shell Functions

**`dexb <service>`** — exec a shell into any running service container by service name, regardless of which compose project started it. Uses `docker ps --filter "label=com.docker.compose.service=<service>"`. Silently probes for `bash`, falls back to `sh`, errors if neither exists.

**`rpk [args...]`** — runs the Redpanda `rpk` CLI inside the redpanda container. Example: `rpk topic list`.

**`dc`** — wraps `docker compose` with the correct compose file path and project name. Project name is derived from `basename` of `LOCAL_WORKSPACE_FOLDER` after normalizing Windows backslashes with `tr "\\\\" "/"`.

## Cross-Platform Constraints

These invariants must be preserved when editing configuration:

- **Mounts use `${localEnv:HOME}` only** — never `${localEnv:HOME}${localEnv:USERPROFILE}`. Git for Windows sets both variables; concatenating them produces an invalid doubled path.
- **Line endings** — `.gitattributes` enforces LF for all shell scripts, YAML, Dockerfile, and Caddyfile. Never change this. A CRLF bash script fails immediately with `$'\r': command not found`.
- **Elasticsearch on Linux/WSL2** requires `sudo sysctl -w vm.max_map_count=262144` on the host before starting the `elastic` profile. macOS users are unaffected (Docker Desktop sets this automatically).

## Dockerfile Build Steps

1. Base apt packages (includes `default-mysql-client`, `postgresql-client`, `redis-tools`)
2. Node.js via NodeSource (version controlled by `ARG NODE_VERSION=22`)
3. Global npm packages (TypeScript, Vite, Prisma, Vitest, etc.)
4. Docker CLI + Compose plugin
5. GitHub CLI (`gh`) via official apt repo
6. Additional CLIs: k6, mongosh (Ubuntu `noble` repo), grpcurl, websocat, xh
7. Shell config (`shell/.bashrc_devcontainer` → `/etc/bash_devcontainer`)
8. User setup (`vscode` added to docker group, passwordless sudo)
9. `WORKDIR /workspace`, `USER vscode`

## gh CLI and git Authentication

- **Mac/Linux**: `~/.config/gh` is bind-mounted from the host. If `gh auth login` has been run on the host, auth is available automatically inside the container.
- **Windows**: Set `GH_TOKEN` as a host environment variable; it is forwarded via `remoteEnv` in `devcontainer.json`.
- **HTTPS git push**: `post-create.sh` runs `gh auth setup-git`, which registers `gh` as the Git credential helper for `https://github.com` URLs.
- **SSH git push**: `~/.ssh` is bind-mounted from the host. `post-start.sh` runs `chmod 600/644` on the mounted keys every start to normalize permissions that Docker may inherit loosely from Windows hosts.

## Service Config Files

Files under `services/` are bind-mounted read-only into their respective containers. Editing them takes effect on the next container restart (no rebuild needed). Init scripts (`postgres/init/`, `mongo/init/`) only run when the named volume is first created — to re-run them, remove the volume: `docker volume rm <project>_devcontainer-postgres-data`.
