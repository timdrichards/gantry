# Gantry Dev Environment — Getting Started

Welcome! This guide will get your development environment up and running, even if you have never used Docker or a dev container before. Read through each section in order the first time — it only takes about 10 minutes.

---

## What is this, exactly?

When you open this project in VS Code, it automatically builds a **Linux environment** that runs inside your computer. Think of it like a virtual machine, but lighter and faster. Inside that environment you get:

- **Node.js** (latest LTS) and all the tools you need for web development
- **Optional databases** (PostgreSQL, Redis, MongoDB, MySQL, and more) that you can turn on with a single command
- A **pre-configured terminal** with shortcuts that make common tasks faster
- Everything needed for web development — no manual installation required

No matter whether you are on macOS, Windows, or Linux, everyone on the team gets the exact same environment. "It works on my machine" stops being an excuse.

---

## Step 1 — Install the prerequisites

You need three things installed on your computer before you start. Click each link and follow the instructions for your operating system.

1. **[Docker Desktop](https://www.docker.com/products/docker-desktop/)**
   Docker is the engine that runs the dev environment. The Desktop app gives you a graphical dashboard too.
   > **Windows users:** during installation, choose **"Use WSL 2"** if asked. After installing, open Docker Desktop once and let it finish starting up before moving on.

2. **[Visual Studio Code](https://code.visualstudio.com/)**
   The code editor.

3. **[Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)**
   This VS Code extension makes the "open in container" magic work. Click the link, then click **Install**, and VS Code will open and install it automatically.

Once all three are installed, make sure Docker Desktop is **running** (look for the Docker whale icon in your taskbar or menu bar) before continuing.

---

## Step 2 — Open the project in VS Code

1. Open VS Code.
2. Go to **File → Open Folder** and select the project folder.
3. VS Code will show a notification in the bottom-right corner:

   > **"Folder contains a Dev Container configuration file. Reopen in Container?"**

4. Click **"Reopen in Container"**.

   If you missed the notification, open the Command Palette (`Ctrl+Shift+P` on Windows/Linux, `Cmd+Shift+P` on Mac), type **"Reopen in Container"**, and press Enter.

5. **Wait for the build to finish.** The first time takes **3–5 minutes** while it downloads everything. You will see a progress bar in the bottom-right corner. Subsequent openings are almost instant.

When the build finishes, VS Code reloads and you are now inside the development environment.

---

## Step 3 — Open the terminal

The terminal is how you run code and commands. Inside VS Code:

- Go to **Terminal → New Terminal** in the menu bar, or press `` Ctrl+` `` (backtick).

You should see something like this:

```
  ╔══════════════════════════════════════════════════╗
  ║  Web Dev + Scalable Systems  •  Dev Container    ║
  ╠══════════════════════════════════════════════════╣
  ║  Node v26.x.x  npm x.x.x  pnpm x.x.x           ║
  ║  Docker 27.x.x                                   ║
  ║  Plugins: 0 active  •  'plugin help'             ║
  ╠══════════════════════════════════════════════════╣
  ║  Network: gantry (172.28.0.0/16)                 ║
  ║  Type 'dc-up <service>' to start services        ║
  ...
  ╚══════════════════════════════════════════════════╝

vscode@devcontainer:/gantry$
```

That banner confirms everything is working. The `$` at the end of the last line is the **prompt** — it is waiting for you to type a command.

> **New to the terminal?** The terminal works by typing a command and pressing **Enter**. Commands are case-sensitive. If something goes wrong, you can usually press `Ctrl+C` to stop whatever is running.

---

## How-to: Common Scenarios

Work through these examples in order to get comfortable with the environment.

---

### Scenario 1 — Run a Node.js script

Let's confirm Node.js is ready.

```bash
node --version
```

You should see something like `v22.x.x`. Now create and run a tiny script:

```bash
echo 'console.log("Hello from the dev container!")' > hello.js
node hello.js
```

Expected output:
```
Hello from the dev container!
```

---

### Scenario 2 — Install npm packages and run a project

If you have a `package.json` file in your workspace:

```bash
npm install
npm run dev
```

The `npm run dev` command starts your project (exact behavior depends on the project). Press `Ctrl+C` to stop it.

**Shortcuts that save typing:**

| Instead of       | You can type |
|------------------|--------------|
| `npm install`    | `ni`         |
| `npm run dev`    | `nrd`        |
| `npm run`        | `nr`         |
| `npm start`      | `ns`         |
| `npm test`       | `nt`         |

---

### Scenario 3 — Start a database and connect to it

Databases are **off by default** to save memory. Turn one on when you need it.

**Start PostgreSQL:**

```bash
dc-up postgres
```

You will see Docker pulling the image and starting the container. Once it says the container is healthy, connect to it:

```bash
psql-dev
```

You are now inside the PostgreSQL shell. Try a quick command:

```sql
\l
```

This lists all databases. You should see `devdb` in the list. Type `\q` to exit.

**Start Redis:**

```bash
dc-up redis
redis-dev ping
```

Expected output: `PONG`

**Start MongoDB:**

```bash
dc-up mongo
mongo-dev
```

You are now in the MongoDB shell. Type `show dbs` to list databases. Type `exit` to leave.

**Stop everything when you're done:**

```bash
dc-down
```

---

### Scenario 4 — Check what is running

```bash
dps
```

This shows all running containers in a tidy table format. If nothing is running, you will see an empty table.

To see the logs from a running service (like postgres), use:

```bash
dc-logs postgres
```

Press `Ctrl+C` to stop watching logs.

---

### Scenario 5 — Make an HTTP request and read JSON

The environment comes with several tools for working with HTTP APIs.

```bash
curl https://jsonplaceholder.typicode.com/todos/1
```

The output is JSON but it is hard to read. Pipe it through `jq` to pretty-print it:

```bash
curl https://jsonplaceholder.typicode.com/todos/1 | jq .
```

Or use the built-in shortcut `jcurl` which does both steps at once:

```bash
jcurl https://jsonplaceholder.typicode.com/todos/1
```

You can also use `xh` (a friendlier HTTP tool):

```bash
xh https://jsonplaceholder.typicode.com/todos/1
```

---

### Scenario 6 — Check what ports are listening

When your app is running, you might want to see what ports are in use:

```bash
ports
```

This lists every port that has something listening on it.

---

## Available Services

Start any service with `dc-up <name>`. Stop everything with `dc-down`.

| Service           | Start command           | What it is                                      |
|-------------------|-------------------------|-------------------------------------------------|
| PostgreSQL        | `dc-up postgres`        | Relational database. User: `dev`, Pass: `devpassword`, DB: `devdb` |
| Redis             | `dc-up redis`           | In-memory cache and key-value store             |
| MongoDB           | `dc-up mongo`           | Document (NoSQL) database                       |
| MySQL             | `dc-up mysql`           | Relational database (MySQL flavour)             |
| RabbitMQ          | `dc-up rabbitmq`        | Message queue. Management UI on port 15672      |
| Elasticsearch     | `dc-up elastic`         | Full-text search engine                         |
| Memcached         | `dc-up memcached`       | Simple in-memory cache                          |
| MinIO             | `dc-up minio`           | S3-compatible object storage. Console on port 9001 |
| Redpanda          | `dc-up redpanda`        | Kafka-compatible event streaming                |
| Mailpit           | `dc-up mailpit`         | Local email catcher. Web UI on port 8025        |
| Adminer           | `dc-up adminer`         | Web-based database GUI (port 8080)              |
| Nginx             | `dc-up nginx`           | Web / reverse proxy server                      |
| Caddy             | `dc-up caddy`           | HTTPS-capable web / reverse proxy server        |
| Prometheus        | `dc-up prometheus`      | Metrics collection (port 9090)                  |
| Grafana           | `dc-up grafana`         | Metrics dashboards. admin / admin (port 3030)   |
| Jaeger            | `dc-up jaeger`          | Distributed tracing UI (port 16686)             |
| Loki              | `dc-up loki`            | Log aggregation, pairs with Grafana (port 3100) |
| Otelcol           | `dc-up otelcol`         | OpenTelemetry collector for traces/metrics/logs |
| Qdrant            | `dc-up qdrant`          | Vector database for embeddings / similarity search |
| Meilisearch       | `dc-up meilisearch`     | Fast full-text search engine (port 7700)        |
| NATS              | `dc-up nats`            | Lightweight messaging system                    |
| Keycloak          | `dc-up keycloak`        | Identity and access management (SSO/OAuth)      |

**Start multiple services at once:**

```bash
dc-up postgres redis mongo
```

---

## Quick-Connect Shortcuts

Once a service is running, these shortcuts drop you straight into its CLI:

| Command       | What it does                                           |
|---------------|--------------------------------------------------------|
| `psql-dev`    | Opens the PostgreSQL shell connected to `devdb`        |
| `redis-dev`   | Opens `redis-cli` connected to the Redis container     |
| `mongo-dev`   | Opens `mongosh` connected to MongoDB `devdb`           |
| `mysql-dev`   | Opens the MySQL shell connected to `devdb`             |

---

## Opening a Shell Inside a Service Container

Need to run commands directly inside a database container (for example, to run admin commands)?

```bash
dexb postgres
```

Replace `postgres` with any running service name. This opens a bash shell inside that container. Type `exit` to come back.

---

## Customizing Your Terminal

You can add your own aliases, functions, and environment variables without touching any shared files and without restarting the container.

1. Open the file `.bashrc.user` in your workspace root (VS Code's Explorer panel — it is a hidden file, so look for it there or open it from the terminal).
2. Add your customizations. Example:

   ```bash
   # My personal shortcuts
   alias serve='npx http-server . -p 8080'
   alias cls='clear'
   export MY_API_KEY="abc123"
   ```

3. Apply changes **without restarting** by running:

   ```bash
   reload-env
   ```

Your changes are now active in the current terminal.

> **Note:** `.bashrc.user` is listed in `.gitignore` so your personal settings are never accidentally committed to the project repository.

---

## Plugins

The environment has a plugin system that lets you add extra tools and shell commands.

**See what commands are available:**

```bash
plugin help
```

**See installed plugins:**

```bash
plugin list
```

**Install a plugin from a GitHub repository:**

```bash
plugin install https://github.com/example/my-plugin
```

**Create your own plugin (for developers):**

```bash
plugin new my-tool
```

This scaffolds a full plugin directory structure in `.plugins/my-tool/` with a starter script, shell integration file, and documentation template.

---

## All Shell Shortcuts

Here is a quick reference for everything built in.

### Docker / Services

| Shortcut              | What it does                                          |
|-----------------------|-------------------------------------------------------|
| `dc-up <service>`     | Start a service (e.g. `dc-up postgres`)              |
| `dc-down`             | Stop all services                                     |
| `dc-logs <service>`   | Watch a service's log output                          |
| `dps`                 | List running containers (formatted)                   |
| `dexb <service>`      | Open a shell inside a running service container       |
| `dlog <container>`    | Follow raw Docker logs                                |
| `dprune`              | Free up disk space from stopped containers / images   |

### Node / npm

| Shortcut | Equivalent command |
|----------|--------------------|
| `ni`     | `npm install`      |
| `nr`     | `npm run`          |
| `ns`     | `npm start`        |
| `nt`     | `npm test`         |
| `nrd`    | `npm run dev`      |
| `pni`    | `pnpm install`     |
| `pnr`    | `pnpm run`         |

### HTTP

| Shortcut  | What it does                                                   |
|-----------|----------------------------------------------------------------|
| `jcurl`   | `curl` + pretty-print JSON output                              |
| `GET`     | `curl -sS -X GET`                                              |
| `POST`    | `curl -sS -X POST -H "Content-Type: application/json"`        |
| `PUT`     | `curl -sS -X PUT -H "Content-Type: application/json"`         |
| `DELETE`  | `curl -sS -X DELETE`                                           |
| `wstest`  | Open a WebSocket connection (e.g. `wstest ws://localhost:3000`)|

### System

| Shortcut    | What it does                                 |
|-------------|----------------------------------------------|
| `ports`     | Show all listening ports                     |
| `listening` | Show listening sockets with process names    |
| `ll`        | `ls -lAh` (detailed file list)               |
| `reload-env`| Reload your `.bashrc.user` without restarting|

### Git

| Shortcut | Equivalent         |
|----------|--------------------|
| `gs`     | `git status`       |
| `ga`     | `git add`          |
| `gc`     | `git commit`       |
| `gp`     | `git push`         |
| `gl`     | `git log` (graph)  |
| `gd`     | `git diff`         |

---

## Connecting to Services from Your Code

When writing code that connects to a database or other service, use the **service name** as the hostname (not `localhost`).

| Service       | Host to use in your code | Port  | Username | Password    | Database |
|---------------|--------------------------|-------|----------|-------------|----------|
| PostgreSQL    | `postgres`               | 5432  | `dev`    | `devpassword` | `devdb` |
| MongoDB       | `mongo`                  | 27017 | `dev`    | `devpassword` | `devdb` |
| Redis         | `redis`                  | 6379  | —        | —           | —        |
| MySQL         | `mysql`                  | 3306  | `dev`    | `devpassword` | `devdb` |
| RabbitMQ      | `rabbitmq`               | 5672  | `dev`    | `devpassword` | —        |
| Elasticsearch | `elastic`                | 9200  | —        | —           | —        |
| Memcached     | `memcached`              | 11211 | —        | —           | —        |
| MinIO         | `minio`                  | 9000  | `minioadmin` | `minioadmin` | —    |
| Redpanda      | `redpanda`               | 9092  | —        | —           | —        |
| SMTP (Mailpit)| `mailpit`                | 1025  | —        | —           | —        |
| Qdrant        | `qdrant`                 | 6333  | —        | —           | —        |
| Meilisearch   | `meilisearch`            | 7700  | —        | `devmasterkey` (master key) | — |
| NATS          | `nats`                   | 4222  | —        | —           | —        |
| Keycloak      | `keycloak`               | 8180  | `admin`  | `devpassword` | —      |

Example PostgreSQL connection string for Node.js:
```
postgresql://dev:devpassword@postgres:5432/devdb
```

A `.env.example` file in the root of the project has ready-to-use connection strings for every service.

---

## Ports You Can Access from Your Browser

Your browser on your laptop can reach these ports directly (VS Code forwards them automatically):

| Port  | Service / What to open                             |
|-------|----------------------------------------------------|
| 3000  | Your app (default)                                 |
| 5173  | Vite dev server                                    |
| 8080  | HTTP alternate / Adminer database GUI              |
| 8025  | Mailpit email catcher                              |
| 9001  | MinIO console                                      |
| 9090  | Prometheus                                         |
| 3030  | Grafana dashboards (admin / admin)                 |
| 16686 | Jaeger tracing UI                                  |
| 15672 | RabbitMQ management (dev / devpassword)            |
| 3100  | Loki (log aggregation API)                         |
| 14318 | Otelcol OTLP HTTP receiver (14317 for gRPC)        |
| 6333  | Qdrant vector database API                         |
| 7700  | Meilisearch search API                             |
| 8222  | NATS monitoring (4222 for client connections)      |
| 8180  | Keycloak admin console (admin / devpassword)       |

Open `http://localhost:<port>` in your browser.

---

## Troubleshooting

### The "Reopen in Container" notification never appeared

Open the Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`), type **Dev Containers: Reopen in Container**, and press Enter. If that option doesn't appear, make sure the Dev Containers extension is installed and Docker Desktop is running.

### The build failed or got stuck

1. Make sure Docker Desktop is open and running (check the taskbar/menu bar icon).
2. Open the Command Palette and choose **Dev Containers: Rebuild Container**.
3. If it fails again, open Docker Desktop and check that you have at least 4 GB of memory allocated to Docker (Settings → Resources).

### A service won't start

Check Docker is running, then try:

```bash
dc-logs <service>
```

This shows the service's error output. Common fix: the service might need a moment to initialize. Try `dc-up <service>` again after 10 seconds.

### `psql-dev` / `redis-dev` says "connection refused"

The service is not running yet. Start it first:

```bash
dc-up postgres   # or redis, mongo, etc.
```

Wait a few seconds for it to become ready, then try again.

### My app can't connect to the database

Make sure you are using the **service name** as the host (e.g. `postgres`, `redis`, `mongo`) — **not** `localhost`. Inside the dev container, services talk to each other by name. See the connection table above.

### I can't push to GitHub

Run this inside the container terminal:

```bash
gh auth status
```

If it says you are not authenticated, run:

```bash
gh auth login
```

Follow the prompts. After authenticating, git push will work automatically.

### I accidentally ran something and the terminal is frozen

Press `Ctrl+C` to cancel the current command. If that doesn't work, close the terminal tab and open a new one from **Terminal → New Terminal**.

### Everything is broken — I want to start fresh

Open the Command Palette and choose **Dev Containers: Rebuild Container**. This rebuilds the environment from scratch. Your files in the workspace folder are never deleted.

---

## What's installed in the environment

### Runtimes
- **Node.js** (LTS) — `node`, `npm`, `npx`
- **pnpm** and **yarn** — alternative package managers
- **Python 3** — for scripting and tooling

### TypeScript & Build Tools
`typescript`, `ts-node`, `tsx`, `vite`, `esbuild`

### Code Quality
`eslint`, `prettier`

### Database CLI Clients
`psql` (PostgreSQL), `redis-cli`, `mongosh` (MongoDB), `mysql`, `sqlite3`

### HTTP & Network Tools
`curl`, `xh`, `httpie`, `jq`, `websocat`, `grpcurl`, `nmap`, `tcpdump`, `tshark`, `netcat`, `mtr`, `socat`, `dig`

### Load Testing
`k6` — run a load test script: `k6 run script.js`

### Utilities
`ripgrep` (`rg`), `fzf`, `bat`, `fd`, `tree`, `htop`, `lsof`, `git`, `gh` (GitHub CLI), `docker`, `docker compose`

---

## Upgrading Gantry

Already have Gantry set up and just need to move to a newer release? See the
step-by-step
[Upgrading Gantry guide](https://github.com/timdrichards/gantry/blob/main/docs/upgrading.md)
— it covers backing up your work, swapping in the new `.devcontainer/`
folder, checking `.env.example` for new variables, and confirming nothing
about your existing databases or plugins was touched.

---

## Maintainers: Cutting a Release

Releases are dated GitHub releases (tag format `vMM-DD-YYYY`) whose asset is
a distribution zip containing only the parts a template consumer needs:
`.devcontainer/`, `.env.example`, and `README.md`. There is no CI automation
— every release is cut by hand (or with Claude's help).

### Using Claude Code

Ask Claude to "cut a new release," or run `/release`. The full procedure —
including how to handle a same-day re-release — lives in
[`.claude/skills/release/SKILL.md`](.claude/skills/release/SKILL.md), which
Claude will follow.

### Doing it manually

1. Make sure `main` is clean and has everything you want to ship, then tag
   it with today's date:

   ```bash
   git tag -a vMM-DD-YYYY -m "gantry vMM-DD-YYYY"
   git push origin vMM-DD-YYYY
   ```

2. Stage only the distributable files into a temp directory and zip them —
   **not** a full repo archive. Do not include `docs/`, `CLAUDE.md`,
   `.vscode/`, `.claude/`, or other repo-meta files:

   ```bash
   STAGE=$(mktemp -d)
   cp -R .devcontainer "$STAGE/"
   cp .env.example "$STAGE/"
   cp README.md "$STAGE/"
   cd "$STAGE" && zip -r -X /tmp/gantry-vMM-DD-YYYY.zip .devcontainer .env.example README.md
   ```

3. Publish it:

   ```bash
   gh release create vMM-DD-YYYY /tmp/gantry-vMM-DD-YYYY.zip \
     --repo timdrichards/gantry \
     --title "gantry vMM-DD-YYYY" \
     --notes "Distribution release vMM-DD-YYYY."
   ```

If a tag for today already exists and you want to replace it rather than
stack a second release:

```bash
gh release delete vMM-DD-YYYY --repo timdrichards/gantry --cleanup-tag --yes
git tag -a vMM-DD-YYYY -m "gantry vMM-DD-YYYY" <new-commit-sha>
git push origin vMM-DD-YYYY
```

---

*Questions or issues? Open an issue in the repository.*
