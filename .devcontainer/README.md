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
    ├── prometheus/
    │   └── prometheus.yml     # Prometheus scrape configuration
    └── redpanda/
        └── console-config.yml # Redpanda Console broker/registry config
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

**Dockerfile build steps summary:**

| Step | Purpose |
|---|---|
| 1 | Base system packages (apt) |
| 2 | Node.js via NodeSource |
| 3 | Global npm packages |
| 4 | Docker CLI + Compose plugin |
| 5 | GitHub CLI (`gh`) |
| 6 | Additional CLI tools (k6, mongosh, grpcurl, websocat, xh) |
| 7 | Shell ergonomics (copy `.bashrc_devcontainer`) |
| 8 | User setup (docker group, passwordless sudo) |
| 9 | Working directory + user switch |

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
4. Checks `gh auth status` and prints the authenticated user, or a platform-specific warning if not authenticated

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
| memcached | `memcached:alpine` | `memcached` | 11211 | none | — |
| mailpit | `axllent/mailpit` | `mailpit` | 1025 (SMTP) / 8025 (UI) | none | — |
| minio | `minio/minio` | `minio` | 9000 (API) / 9001 (console) | `dev` / `devpassword` | — |
| redpanda | `redpandadata/redpanda` | `redpanda` | 9092 / 8081 / 8082 / 9644 | none | — |
| redpanda-console | `redpandadata/console` | `redpanda` | 9080 | none | `services/redpanda/console-config.yml` |
| jaeger | `jaegertracing/all-in-one` | `observability` | 16686 (UI) / 4317 / 4318 | none | — |
| adminer | `adminer` | `adminer` | 8888 | none | — |
| caddy | `caddy:alpine` | `caddy` | 80 / 443 / 2019 | — | `services/caddy/Caddyfile` |
| nginx | `nginx:alpine` | `nginx` | 80 / 443 | — | — |
| prometheus | `prom/prometheus:latest` | `observability` | 9090 | — | `services/prometheus/prometheus.yml` |
| grafana | `grafana/grafana:latest` | `observability` | 3030 | `admin` / `admin` | — |

> **Note:** Caddy and Nginx both bind ports 80 and 443. Do not start both profiles simultaneously.

Data volumes are named and persist across container restarts: `postgres-data`, `mongo-data`, `redis-data`, `mysql-data`, `rabbitmq-data`, `elasticsearch-data`, `minio-data`, `redpanda-data`.

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
| `rpk [args...]` | Run the Redpanda `rpk` CLI inside the redpanda container |

`dexb` works by filtering `docker ps` on the `com.docker.compose.service` label, so it finds the container even if it was started under a different project name than the current `dc` alias expects. It silently checks for `bash` first, falls back to `sh`, and errors if neither is found.

`rpk` is the Redpanda CLI for managing topics, ACLs, and cluster config. Examples: `rpk topic list`, `rpk topic create my-topic`, `rpk topic consume my-topic`.

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
| 8888 | Adminer (notify on open) |
| 9090 | Prometheus |
| 3306 | MySQL |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 11211 | Memcached |
| 27017 | MongoDB |
| 9200 | Elasticsearch |
| 4369 | Erlang (RabbitMQ) |
| 2019 | Caddy admin API |
| 1025 | Mailpit SMTP |
| 8025 | Mailpit web UI (notify on open) |
| 9000 | MinIO API |
| 9001 | MinIO console (notify on open) |
| 9092 | Redpanda Kafka API |
| 8081 | Redpanda Schema Registry |
| 8082 | Redpanda HTTP Proxy |
| 9644 | Redpanda Admin API |
| 9080 | Redpanda Console UI (notify on open) |
| 16686 | Jaeger UI (notify on open) |
| 4317 | Jaeger OTLP gRPC |
| 4318 | Jaeger OTLP HTTP |

Add more ports to `forwardPorts` in `devcontainer.json` as needed. `portsAttributes` controls the label and `onAutoForward` behaviour (`notify`, `silent`, `openBrowser`).

---

## GitHub CLI Authentication

`gh` is pre-installed in the container. Authentication is shared from the host automatically on Mac and Linux. On Windows, a token must be passed explicitly.

### Mac / Linux

No setup required. `devcontainer.json` bind-mounts `~/.config/gh` from the host into the container, so if you are already authenticated on the host (`gh auth status` returns OK), the container inherits that auth on every start.

If you are not yet authenticated on the host:

```bash
gh auth login   # run on the host, not inside the container
```

Then rebuild the container once so the mount picks up the new config.

### Windows

`gh` on Windows stores its auth config in `%APPDATA%\GitHub CLI`, not in `~/.config/gh`, so the bind-mount does not apply.

Instead, set `GH_TOKEN` as a persistent environment variable on your host:

1. Generate a personal access token at **GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens**. Grant it the scopes your work needs (at minimum: `repo`, `read:org`).
2. Add it to your host environment:
   - **Windows**: System → Advanced system settings → Environment Variables → add `GH_TOKEN = <your-token>` under user variables.
   - **PowerShell** (current session only): `$env:GH_TOKEN = "your-token"`
3. Rebuild the container — `devcontainer.json` forwards `GH_TOKEN` via `remoteEnv`, and `gh` will pick it up automatically.

### Verifying inside the container

```bash
gh auth status
gh api user --jq .login
```

`post-start.sh` also prints the authenticated username (or a warning) every time the container starts.

### Running gh auth login inside the container

If you prefer, you can skip host-side setup entirely and run `gh auth login` directly in a container terminal. Use the browser flow (`HTTPS + Login with browser`) or a token. The config will persist for the lifetime of the container but will not survive a rebuild unless the `~/.config/gh` bind-mount is in place (Mac/Linux).

---

## git push from inside the container

`git push` works for both HTTPS and SSH remotes.

### HTTPS remotes (`https://github.com/…`)

`post-create.sh` runs `gh auth setup-git` automatically. This registers `gh` as the Git credential helper for GitHub HTTPS URLs, so `git push` silently obtains a token from the already-authenticated `gh` — no password prompts.

Verify the helper is wired up:

```bash
git config --list | grep credential
# should include: credential.https://github.com.helper=!gh auth git-credential
```

### SSH remotes (`git@github.com:…`)

`devcontainer.json` bind-mounts `~/.ssh` from the host into the container. `post-start.sh` normalises file permissions on every start (SSH rejects keys whose permissions are too open, which can happen when Docker copies permissions from a Windows host).

Verify SSH auth works:

```bash
ssh -T git@github.com
# Hi <username>! You've successfully authenticated...
```

If that fails, check that your SSH key is added to your GitHub account and that the key file exists at `~/.ssh` on the **host** machine (not just inside the container).

### Windows note

The `~/.ssh` mount path resolves to `%USERPROFILE%\.ssh` on Windows, which is where the Windows OpenSSH client stores keys. This should work correctly via Docker Desktop's path translation. If SSH still fails, confirm the key permissions are `600` inside the container:

```bash
ls -la ~/.ssh
```

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

Example — adding a hypothetical ClickHouse service:

```yaml
# docker-compose.yml
  clickhouse:
    image: clickhouse/clickhouse-server:latest
    profiles: [ clickhouse, full ]
    restart: unless-stopped
    ports:
      - "8123:8123"
      - "9000:9000"
    networks:
      webdev:
        aliases:
          - clickhouse
```

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
| `admin 0.0.0.0:2019` | Enables the Caddy admin API, reachable at `http://caddy:2019` from the host |
| `local_certs` | Issues certificates via Caddy's internal CA instead of Let's Encrypt (no ACME challenge needed) |
| `:80, :443 { reverse_proxy devcontainer:3000 }` | Default catch-all site proxied to the app |

**Accessing the admin API**

The Caddy admin API is a REST interface, not a browser UI. Direct browser navigation returns an origin error because browsers omit the `Origin` header on plain navigation requests, which Caddy's CSRF protection blocks by design. Use `curl` instead:

```bash
curl http://caddy:2019/config/ | jq .
curl http://caddy:2019/reverse_proxy/upstreams | jq .
```

Alternatively, use the VS Code REST Client extension (`.http` file) or Thunder Client — both send proper request headers.

**Reload config without restarting:**

```bash
curl -s http://caddy:2019/load \
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

### Using Mailpit

Mailpit is an SMTP trap — any email your app sends to `mailpit:1025` is caught and displayed in the Mailpit web UI instead of being delivered. No real email is ever sent.

Configure your app's mail transport (e.g. Nodemailer) to point at the trap:

```js
const transporter = nodemailer.createTransport({ host: "mailpit", port: 1025 });
```

View captured emails at `http://mailpit:8025` from inside the devcontainer. All messages are ephemeral — they are lost when the container stops (no named volume).

### Using MinIO

MinIO exposes an S3-compatible API at `http://minio:9000`. Use the standard AWS SDK in your app with the endpoint overridden:

```js
import { S3Client } from "@aws-sdk/client-s3";

const s3 = new S3Client({
  endpoint: "http://minio:9000",
  region: "us-east-1",
  credentials: { accessKeyId: "dev", secretAccessKey: "devpassword" },
  forcePathStyle: true, // required for MinIO
});
```

The MinIO web console is at `http://minio:9001` (credentials `dev` / `devpassword`). Use it to create buckets and browse objects.

MinIO does not create a default bucket on startup. Create one via the console or with the AWS SDK before your first `PutObject`.

### Using Redpanda

Redpanda is a Kafka-compatible broker. Any library that works with Kafka works with Redpanda. Connect to `redpanda:9092`:

```js
import { Kafka } from "kafkajs";

const kafka = new Kafka({ brokers: ["redpanda:9092"] });
```

**`rpk` CLI** — the `rpk` shell function wraps the Redpanda CLI inside the container:

```bash
rpk topic list
rpk topic create my-topic --partitions 3
rpk topic produce my-topic   # interactive producer
rpk topic consume my-topic --from-beginning
```

**Redpanda Console** — a web UI for browsing topics and messages is at `http://redpanda-console:9080`.

**Schema Registry** — available at `http://redpanda:8081` for Avro/Protobuf schema management.

To reset all topics and data, remove the named volume:

```bash
docker volume rm <project>_devcontainer-redpanda-data
dc-up redpanda
```

To add Redpanda Console config (e.g. to enable authentication or multiple clusters), edit `services/redpanda/console-config.yml` and restart the `redpanda-console` container.

### Using Memcached

Memcached has no persistent volume — data is lost when the container stops, which is the correct behaviour for a pure cache.

Connect from your app using any Memcached client library at `memcached:11211`. Quick connectivity check from the devcontainer terminal:

```bash
echo "stats" | nc memcached 11211
```

### Using Jaeger

Jaeger collects distributed traces from your app via OpenTelemetry. Instrument your Node.js app with the OTEL SDK:

```bash
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node \
            @opentelemetry/exporter-trace-otlp-grpc
```

```js
// tracing.js — import before everything else
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-grpc";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({ url: "http://jaeger:4317" }),
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
```

View traces in the Jaeger UI at `http://jaeger:16686`.

### Using Adminer

Adminer is a single-page web UI for relational databases. Access it at `http://adminer:8888`.

On the login screen:
- **System** — select the database type (PostgreSQL, MySQL, etc.)
- **Server** — use the service hostname (`postgres`, `mysql`)
- **Username / Password / Database** — use the credentials from the service reference table above

Adminer also supports MongoDB and Elasticsearch via plugins, but those are not pre-installed in the `adminer` base image.

### Customising Nginx

- `services/nginx/nginx.conf` — global Nginx config (worker processes, logging format, upstream definitions).
- `services/nginx/conf.d/default.conf` — the default server block. By default it proxies all traffic to `devcontainer:3000` with WebSocket upgrade support.

To proxy multiple apps, add additional `server` blocks in `conf.d/` as separate `.conf` files (Nginx includes the entire `conf.d/` directory). Reload Nginx after changes:

```bash
dexb nginx
nginx -s reload
```
