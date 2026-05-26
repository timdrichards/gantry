# Dev Container — Architecture & Developer Guide

This document describes how the dev container is structured, how its pieces fit together, and how to extend it.

---

## Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Architecture](#architecture)
   - [The devcontainer service](#the-devcontainer-service)
   - [Sidecar services](#sidecar-services)
   - [The webdev network](#the-webdev-network)
   - [Docker socket passthrough](#docker-socket-passthrough)
4. [Configuration Files](#configuration-files)
   - [devcontainer.json](#devcontainerjson)
   - [docker-compose.yml](#docker-composeyml)
   - [Dockerfile](#dockerfile)
   - [shell/.bashrc_devcontainer](#shellbashrc_devcontainer)
5. [Lifecycle Scripts](#lifecycle-scripts)
6. [Service Reference](#service-reference)
7. [Shell Aliases & Functions](#shell-aliases--functions)
8. [VS Code Extensions & Settings](#vs-code-extensions--settings)
9. [Port Forwarding](#port-forwarding)
10. [Extending the Dev Container](#extending-the-dev-container)
    - [Adding a new sidecar service](#adding-a-new-sidecar-service)
    - [Adding a VS Code extension](#adding-a-vs-code-extension)
    - [Adding a global npm package](#adding-a-global-npm-package)
    - [Adding a system tool](#adding-a-system-tool)
    - [Adding shell aliases](#adding-shell-aliases)
    - [Customising service init scripts](#customising-service-init-scripts)
    - [Customising Prometheus scraping](#customising-prometheus-scraping)
    - [Customising Nginx](#customising-nginx)

---

## Overview

This dev container provides a fully self-contained web development environment for the course. A single `docker-compose.yml` defines the primary coding container (the VS Code workspace) alongside a suite of optional sidecar services — databases, message queues, a reverse proxy, and observability tooling.

Everything runs inside a shared Docker bridge network (`webdev`) so every container is reachable from every other container by its service name as a hostname (e.g. `postgres`, `redis`, `mongo`).

---

## Directory Structure

```
.devcontainer/
├── devcontainer.json          # VS Code dev container specification
├── docker-compose.yml         # All services (devcontainer + sidecars)
├── Dockerfile                 # Image build for the devcontainer service
├── README.md                  # This file
│
├── shell/
│   └── .bashrc_devcontainer   # Shell aliases, functions, and prompt
│
├── scripts/
│   ├── post-create.sh         # Runs once after the image is built
│   └── post-start.sh          # Runs every time the container starts
│
└── services/                  # Per-service config mounted into sidecars
    ├── caddy/
    │   └── Caddyfile          # Caddy reverse-proxy config
    ├── mongo/
    │   └── init/01-init.js    # MongoDB init script (indexes, collections)
    ├── nginx/
    │   ├── nginx.conf         # Nginx base config
    │   └── conf.d/
    │       └── default.conf   # Default reverse-proxy server block
    ├── postgres/
    │   └── init/01-init.sql   # PostgreSQL init script (extensions, schema)
    └── prometheus/
        └── prometheus.yml     # Prometheus scrape configuration
```

---

## Architecture

### The devcontainer service

VS Code opens the `devcontainer` service as its workspace. This container is built from the local `Dockerfile` (based on `mcr.microsoft.com/devcontainers/base:ubuntu-24.04`) and provides:

- Node.js LTS (v22) via NodeSource
- A full set of global npm packages (TypeScript, Vite, Prisma, Vitest, etc.)
- Docker CLI + Compose plugin (for Docker-outside-of-Docker)
- Network/debugging CLIs: `curl`, `jq`, `httpie`, `nmap`, `tcpdump`, `grpcurl`, `websocat`, `xh`, `k6`
- Database CLI clients: `psql`, `redis-cli`, `mongosh`, `mysql`
- Shell tooling: `ripgrep`, `fzf`, `bat`, `fd`, `htop`

The workspace source (the parent directory `..`) is bind-mounted to `/workspace` inside the container.

### Sidecar services

All other services (postgres, redis, mongo, etc.) are standard upstream images. They are not built — Docker pulls them directly. They are **optional** and activated through Compose profiles. No sidecar is started unless explicitly requested.

Each sidecar:
- Joins the `webdev` network with one or more hostname aliases
- Uses a named volume for persistent data
- Exposes its standard port to the host machine
- Has a `restart: unless-stopped` policy

### The webdev network

All services share the `webdev` bridge network (`172.28.0.0/16`). Containers resolve each other by service name:

```
devcontainer → postgres:5432   (also aliased as "db")
devcontainer → redis:6379      (also aliased as "cache")
devcontainer → mongo:27017     (also aliased as "mongodb")
devcontainer → mysql:3306
devcontainer → rabbitmq:5672   (also aliased as "mq")
devcontainer → elasticsearch:9200 (also aliased as "elastic")
devcontainer → nginx:80
devcontainer → prometheus:9090
devcontainer → grafana:3030
```

The `.env` file in the workspace root contains connection strings using these hostnames.

### Docker socket passthrough

The Docker socket from the host (`/var/run/docker.sock`) is bind-mounted into the devcontainer. This is "Docker-outside-of-Docker" (DooD): the `docker` and `docker compose` commands inside the container talk to the host Docker daemon, not a nested one. This means:

- The sidecar containers are siblings of the devcontainer, not children.
- Container names and network membership are managed by the host daemon.
- The `dc` alias (see below) must specify the compose file path explicitly because the working directory inside the container differs from where Docker resolves file paths.

This is also why `dc exec <service>` can fail if a service was started under a different compose project name — the `dexb` function works around this by searching for containers using the `com.docker.compose.service` label instead.

---

## Configuration Files

### devcontainer.json

The VS Code specification file. Key fields:

| Field | Value | Purpose |
|---|---|---|
| `dockerComposeFile` | `docker-compose.yml` | Compose file to use |
| `service` | `devcontainer` | Which service VS Code attaches to |
| `workspaceFolder` | `/workspace` | Path inside the container |
| `postCreateCommand` | `scripts/post-create.sh` | Runs once after build |
| `postStartCommand` | `scripts/post-start.sh` | Runs on every start |
| `remoteUser` | `vscode` | Non-root user inside the container |
| `containerEnv` | `LOCAL_WORKSPACE_FOLDER` | Passes the host workspace path in; used by `docker-compose.yml` to resolve volume mounts |

The `features` block enables the Docker-outside-of-Docker feature, which installs the Docker CLI and adds the `vscode` user to the `docker` group.

### docker-compose.yml

Defines all services. Services are grouped by Compose **profile**:

| Profile | Services included |
|---|---|
| `postgres` | postgres |
| `mongo` | mongo |
| `redis` | redis |
| `mysql` | mysql |
| `rabbitmq` | rabbitmq |
| `elastic` | elasticsearch |
| `nginx` | nginx |
| `observability` | prometheus, grafana |
| `full` | all of the above |

The `devcontainer` service has no profile, so it is always started by VS Code.

Start services with the `dc-up` alias inside the container:

```bash
dc-up redis postgres       # start specific services
dc-up --profile full       # start everything
```

### Dockerfile

Multi-stage build (single stage in practice). Steps:

1. **Base packages** — system tools, network utilities, database CLI clients, Python
2. **Node.js** — installed via NodeSource apt repo at the version set by `ARG NODE_VERSION` (default: 22)
3. **Global npm packages** — TypeScript, Vite, ESLint, Prettier, Prisma, Vitest, etc.
4. **Docker CLI** — installed from the official Docker apt repo (CLI only, no daemon)
5. **Additional CLI tools** — k6, mongosh, grpcurl, websocat, xh (all downloaded from GitHub releases, arch-aware)
6. **Shell config** — copies `shell/.bashrc_devcontainer` to `/etc/bash_devcontainer` and sources it from `/etc/bash.bashrc`
7. **User setup** — adds `vscode` to the `docker` group for socket access; grants passwordless sudo

To upgrade Node.js, change `ARG NODE_VERSION` in the Dockerfile and rebuild the container.

### shell/.bashrc_devcontainer

Sourced by every bash session inside the devcontainer (via `/etc/bash.bashrc`). Contains:

- Custom PS1 prompt showing git branch and Node version
- Persistent bash history configuration (writes to the `devcontainer-bashhistory` named volume)
- All shell aliases and functions (see [Shell Aliases & Functions](#shell-aliases--functions) below)

---

## Lifecycle Scripts

### post-create.sh

Runs **once** after the container image is first built. It:

1. Marks `/workspace` as a safe git directory
2. Creates and chowns the `/commandhistory` directory for persistent bash history
3. Runs `npm install` if a `package.json` exists in the workspace root
4. Runs `npx prisma generate` if a Prisma schema exists

### post-start.sh

Runs **every time** the container starts (including after a VS Code window reload). It:

1. Verifies the Docker socket is accessible
2. Prints all currently running containers
3. Prints all containers on the `webdev` network with their IP addresses

---

## Service Reference

| Service | Image | Profile | Default port | Credentials | Init script |
|---|---|---|---|---|---|
| postgres | `postgres:16-alpine` | `postgres` | 5432 | `dev` / `devpassword` / `devdb` | `services/postgres/init/01-init.sql` |
| mongo | `mongo:7` | `mongo` | 27017 | `dev` / `devpassword` / `devdb` | `services/mongo/init/01-init.js` |
| redis | `redis:7-alpine` | `redis` | 6379 | none | — |
| mysql | `mysql:8.3` | `mysql` | 3306 | `dev` / `devpassword` / `devdb` | — |
| rabbitmq | `rabbitmq:3-management-alpine` | `rabbitmq` | 5672 / 15672 | `dev` / `devpassword` | — |
| elasticsearch | `elasticsearch:8.13.0` | `elastic` | 9200 | `elastic` / `devpassword` | — |
| caddy | `caddy:alpine` | `caddy` | 80 / 443 / 2019 | — | `services/caddy/Caddyfile` |
| nginx | `nginx:alpine` | `nginx` | 80 / 443 | — | — |
| prometheus | `prom/prometheus:latest` | `observability` | 9090 | — | `services/prometheus/prometheus.yml` |
| grafana | `grafana/grafana:latest` | `observability` | 3030 | `admin` / `admin` | — |

> **Note:** Caddy and Nginx both bind ports 80 and 443. Do not start both profiles simultaneously.

Data volumes are named and persist across container restarts: `postgres-data`, `mongo-data`, `redis-data`, `mysql-data`, `rabbitmq-data`, `elasticsearch-data`.

---

## Shell Aliases & Functions

Defined in `shell/.bashrc_devcontainer`.

### Docker / Compose

| Alias / Function | Expands to |
|---|---|
| `d` | `docker` |
| `dc` | `docker compose -f /workspace/.devcontainer/docker-compose.yml --project-name <project>_devcontainer` |
| `dps` | `docker ps` with a readable table format |
| `dlog <name>` | `docker logs -f <name>` |
| `dex <name> <cmd>` | `docker exec -it <name> <cmd>` |
| `dnet` | `docker network ls` |
| `dvol` | `docker volume ls` |
| `dprune` | `docker system prune -f` |
| `dc-up [services...]` | `dc up -d [services...]` |
| `dc-down [args...]` | `dc down [args...]` |
| `dc-logs [services...]` | `dc logs -f [services...]` |
| `dexb <service>` | Exec bash (or sh) into a running service container by service name, regardless of compose project |

`dexb` works by filtering `docker ps` on the `com.docker.compose.service` label, so it finds the container even if it was started under a different project name than the current `dc` alias expects. It silently checks for `bash` first, falls back to `sh`, and errors if neither is found.

### Database quick-connect

| Alias | Connects to |
|---|---|
| `psql-dev` | PostgreSQL at `postgres:5432` as `dev` |
| `redis-dev` | Redis CLI at `redis:6379` |
| `mongo-dev` | MongoDB at `mongo:27017` as `dev` |
| `mysql-dev` | MySQL at `mysql:3306` as `dev` |

### HTTP helpers

| Alias / Function | Purpose |
|---|---|
| `GET`, `POST`, `PUT`, `DELETE`, `HEAD` | curl with method and JSON content-type pre-set |
| `jcurl <url> [curl-args...]` | curl piped through `jq` for pretty-printed JSON |
| `wstest <url>` | Quick WebSocket connection via `websocat` |

### Node / npm

`ni`, `nr`, `ns`, `nt`, `nrd` (npm), `pni`, `pnr` (pnpm).

### Network diagnostics

`myip`, `ports`, `listening`, `netwatch`.

### Git

`gs`, `ga`, `gc`, `gp`, `gl`, `gd`.

---

## VS Code Extensions & Settings

Extensions are declared in `devcontainer.json` under `customizations.vscode.extensions`. They are installed automatically when the container builds. Categories:

- TypeScript / JavaScript language services
- Frontend / CSS (Tailwind, PostCSS, styled-components)
- HTML / templating (HTMX, Emmet, matching tags)
- Node.js / backend (DotENV, Prisma, PM2)
- Database clients (PostgreSQL, MongoDB, MySQL, SQLite, Redis)
- HTTP / API testing (REST Client, Thunder Client, OpenAPI, GraphQL)
- Docker and containers
- Git (GitLens, Git Graph, GitHub PRs)
- Testing (Vitest, Jest, Test Explorer, Coverage Gutters)
- Code quality (Error Lens, SonarLint, spell checker, TODO Tree)
- Data formats (YAML, TOML, CSV, JSON)
- Shell (Bash IDE, ShellCheck, shell-format)
- Productivity (Material Icons, Indent Rainbow, Live Share, Better Comments)

Key editor settings applied globally inside the container:

- `formatOnSave: true` with Prettier as the default formatter for JS/TS/CSS/HTML/JSON/Markdown
- ESLint runs on type with `source.fixAll.eslint` on save
- 2-space indentation, 100-column ruler
- `files.trimTrailingWhitespace` and `files.insertFinalNewline` enabled

---

## Port Forwarding

`devcontainer.json` declares the following ports as forwarded to the host:

| Port | Service |
|---|---|
| 3000 | App default (notify on open) |
| 3001 | App alternate |
| 4000 | GraphQL / API |
| 5000 | Flask / misc |
| 5173 | Vite dev server (notify on open) |
| 8080 | General HTTP |
| 8443 | General HTTPS |
| 9090 | Prometheus |
| 3306 | MySQL |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 27017 | MongoDB |
| 9200 | Elasticsearch |
| 4369 | Erlang (RabbitMQ) |

Add more ports to `forwardPorts` in `devcontainer.json` as needed. `portsAttributes` controls the label and `onAutoForward` behaviour (`notify`, `silent`, `openBrowser`).

---

## Extending the Dev Container

After any structural change (Dockerfile, docker-compose.yml, devcontainer.json) you must rebuild the container: **Cmd/Ctrl+Shift+P → "Dev Containers: Rebuild Container"**.

Changes to `shell/.bashrc_devcontainer` or the lifecycle scripts take effect on the next container start without a full rebuild — or immediately with `source /etc/bash_devcontainer` in an open terminal.

### Adding a new sidecar service

1. Add the service block to `docker-compose.yml`. Give it a profile name, a named volume (if it needs persistence), and network aliases.
2. Add the named volume under the top-level `volumes:` key.
3. Add the connection URL to `.env.example` (and your local `.env`).
4. Add the host port to `forwardPorts` in `devcontainer.json` if you want VS Code to forward it.
5. Add a quick-connect alias to `shell/.bashrc_devcontainer` if the service has a CLI client.
6. Update the welcome banner at the bottom of `.bashrc_devcontainer` to list the new service name.

Example — adding Memcached:

```yaml
# docker-compose.yml
  memcached:
    image: memcached:alpine
    profiles: [ memcached, full ]
    restart: unless-stopped
    ports:
      - "11211:11211"
    networks:
      webdev:
        aliases:
          - memcached
```

No named volume is needed (Memcached is in-memory only).

### Adding a VS Code extension

Add the extension ID to the `extensions` array in `devcontainer.json` and rebuild.

```jsonc
"your-publisher.your-extension-id"
```

Find the ID on the VS Code Marketplace or by right-clicking an installed extension and choosing "Copy Extension ID".

### Adding a global npm package

Add the package name to the `npm install -g` block in the `Dockerfile` (step 3) and rebuild.

```dockerfile
RUN npm install -g \
    ...
    your-new-package
```

### Adding a system tool

Add the `apt-get install` line to step 1 of the `Dockerfile`. For tools not in apt, follow the pattern used by k6/grpcurl/websocat: detect architecture, resolve the latest release tag from the GitHub API, download and install to `/usr/local/bin`.

### Adding shell aliases

Add aliases or functions to `shell/.bashrc_devcontainer`. Group them with the existing category comments. You can test changes immediately with:

```bash
source /etc/bash_devcontainer
```

No rebuild is required.

### Customising service init scripts

Init scripts run **once**, when the service's named volume is first created (i.e. on a fresh start with no existing data).

- **PostgreSQL** — edit `services/postgres/init/01-init.sql`. Add `CREATE TABLE`, `CREATE EXTENSION`, or seed `INSERT` statements. Files are executed in alphabetical order, so add `02-seed.sql` etc. for subsequent steps.
- **MongoDB** — edit `services/mongo/init/01-init.js`. The `db` variable is already set to `devdb`. Add collections, indexes, or seed documents.

To re-run an init script after data already exists, remove the named volume:

```bash
docker volume rm <project>_devcontainer-postgres-data
dc-up postgres
```

### Customising Prometheus scraping

Edit `services/prometheus/prometheus.yml`. Add a new `scrape_configs` entry pointing at your app's `/metrics` endpoint. The `devcontainer` hostname resolves inside the `webdev` network:

```yaml
- job_name: "node-app"
  static_configs:
    - targets: ["devcontainer:9091"]
```

Prometheus picks up config changes on a hot reload (`curl -X POST http://localhost:9090/-/reload`) or a container restart.

### Customising Caddy

`services/caddy/Caddyfile` is the single config file mounted into the Caddy container. The default config proxies all traffic on ports 80 and 443 to `devcontainer:3000` using Caddy's internal CA for automatic local HTTPS.

Key sections of the default Caddyfile:

| Section | Purpose |
|---|---|
| `admin 0.0.0.0:2019` | Enables the Caddy admin API, reachable at `http://localhost:2019` from the host |
| `local_certs` | Issues certificates via Caddy's internal CA instead of Let's Encrypt (no ACME challenge needed) |
| `:80, :443 { reverse_proxy devcontainer:3000 }` | Default catch-all site proxied to the app |

**Reload config without restarting:**

```bash
curl -s http://localhost:2019/load \
  -H "Content-Type: text/caddyfile" \
  --data-binary @.devcontainer/services/caddy/Caddyfile
```

Or exec in and reload:

```bash
dexb caddy
caddy reload --config /etc/caddy/Caddyfile
```

**Add a named virtual host** (e.g. `api.localhost` → port 4000):

```caddyfile
api.localhost {
  reverse_proxy devcontainer:4000
}
```

**Trust the local CA on your host machine** so browsers stop showing certificate warnings:

```bash
dexb caddy
caddy trust
```

Then export the root CA from the container and add it to your host's trust store:

```bash
docker cp <caddy-container-name>:/data/caddy/pki/authorities/local/root.crt ~/caddy-root.crt
# macOS:
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/caddy-root.crt
```

> **Caddy vs Nginx:** Caddy is simpler to configure for HTTPS and virtual hosts. Nginx offers more control over low-level HTTP behaviour. They cannot run simultaneously because both bind ports 80 and 443.

### Customising Nginx

- `services/nginx/nginx.conf` — global Nginx config (worker processes, logging format, upstream definitions).
- `services/nginx/conf.d/default.conf` — the default server block. By default it proxies all traffic to `devcontainer:3000` with WebSocket upgrade support.

To proxy multiple apps, add additional `server` blocks in `conf.d/` as separate `.conf` files (Nginx includes the entire `conf.d/` directory). Reload Nginx after changes:

```bash
dexb nginx
nginx -s reload
```
