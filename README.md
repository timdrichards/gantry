# Dev Container — Web Programming & Scalable Web Systems

A fully-featured VS Code Dev Container for COMPSCI 326 / 426 coursework.
Docker-in-Docker enabled. All services share the `webdev` network and are
reachable by hostname from the VS Code integrated terminal.

---

## Quick Start

1. **Prerequisites** — install on your host machine:
   - [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine on Linux)
   - [VS Code](https://code.visualstudio.com/)
   - [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Open the project:**
   ```
   code .
   ```
   VS Code will detect `.devcontainer/devcontainer.json` and prompt
   **"Reopen in Container"** — click it.

3. **First build** takes 3–5 minutes (downloads base image + all tools).
   Subsequent starts are instant.

---

## Starting Services

From the VS Code terminal (inside the container), use the `dc-up` alias:

```bash
# Start a single service
dc-up postgres
dc-up redis
dc-up mongo

# Start multiple at once
dc-up postgres redis mongo

# Start everything (the 'full' profile)
dc up -d --profile full

# Stop everything
dc-down

# View logs for a service
dc-logs postgres
```

Or use the full docker compose path from anywhere (inside or outside the container):
```bash
docker compose -f .devcontainer/docker-compose.yml up -d postgres redis
```

---

## Network: `webdev` (172.28.0.0/16)

Every container resolves every other container by **service name**:

| Service         | Hostname(s)              | Port(s)        | Credentials              |
|-----------------|--------------------------|----------------|--------------------------|
| devcontainer    | `devcontainer`           | —              | —                        |
| PostgreSQL      | `postgres`, `db`         | 5432           | dev / devpassword        |
| MongoDB         | `mongo`, `mongodb`       | 27017          | dev / devpassword        |
| Redis           | `redis`, `cache`         | 6379           | —                        |
| MySQL           | `mysql`                  | 3306           | dev / devpassword        |
| RabbitMQ        | `rabbitmq`, `mq`         | 5672, 15672    | dev / devpassword        |
| Elasticsearch   | `elastic`                | 9200           | (security disabled)      |
| Prometheus      | `prometheus`             | 9090           | —                        |
| Grafana         | `grafana`                | 3030           | admin / admin            |
| Nginx           | `nginx`, `proxy`         | 80, 443        | —                        |

### Example connection strings

```bash
# PostgreSQL
psql -h postgres -U dev -d devdb
# → alias: psql-dev

# Redis
redis-cli -h redis ping
# → alias: redis-dev

# MongoDB
mongosh "mongodb://dev:devpassword@mongo:27017/devdb"
# → alias: mongo-dev

# Elasticsearch
curl http://elastic:9200/_cluster/health | jq .

# RabbitMQ management
open http://localhost:15672  # dev / devpassword
```

---

## Running Your Own docker-compose Inside the Container

The Docker socket is mounted, so you can run `docker compose` for your own
project stacks from the VS Code terminal:

```bash
# From /workspace (or any subdirectory with a docker-compose.yml)
docker compose up -d

# To join the shared webdev network, add this to your compose file:
networks:
  webdev:
    external: true
    name: webdev
```

Any container you spin up that joins `webdev` will immediately be reachable
by hostname from the VS Code terminal and from other services.

---

## Installed Tools

### Runtimes & Package Managers
| Tool     | Purpose                        |
|----------|--------------------------------|
| Node.js  | Latest LTS (via NodeSource)    |
| npm      | Latest                         |
| pnpm     | Fast, disk-efficient installs  |
| yarn     | Classic package manager        |

### Global npm Packages
`typescript`, `ts-node`, `tsx`, `vite`, `esbuild`, `eslint`, `prettier`,
`prisma`, `pm2`, `nodemon`, `vitest`, `jest`, `concurrently`, `cross-env`,
`dotenv-cli`, `httpyac`

### Network & HTTP Analysis
| Tool        | Usage                                        |
|-------------|----------------------------------------------|
| `curl`      | HTTP requests                                |
| `xh`        | Friendlier curl alternative                  |
| `httpie`    | `http GET http://api:3000/users`             |
| `jq`        | JSON processing                              |
| `websocat`  | WebSocket testing: `websocat ws://host:3000` |
| `grpcurl`   | gRPC service testing                         |
| `nmap`      | Port scanning                                |
| `tcpdump`   | Packet capture                               |
| `tshark`    | Wireshark CLI                                |
| `netcat`    | Raw TCP/UDP: `nc -zv postgres 5432`          |
| `mtr`       | traceroute + ping combined                   |
| `socat`     | Socket relay / tunneling                     |
| `dnsutils`  | `dig`, `nslookup`, `host`                    |
| `iproute2`  | `ip addr`, `ip route`, `ss`                  |

### Database CLIs
`psql`, `redis-cli`, `mongosh`, `mysql`, `sqlite3`

### Load & Performance Testing
`k6` — `k6 run script.js`

### Shell Utilities
`ripgrep (rg)`, `fzf`, `bat`, `fd`, `tree`, `htop`, `lsof`, `strace`

---

## Shell Aliases Reference

```bash
# Docker
d          → docker
dc         → docker compose -f .devcontainer/docker-compose.yml
dps        → docker ps (formatted)
dlog       → docker logs -f
dex        → docker exec -it
dc-up      → dc up -d
dc-down    → dc down
dc-logs    → dc logs -f

# Node
ni / pni   → npm/pnpm install
nr / pnr   → npm/pnpm run
nrd        → npm run dev

# Network
ports      → ss -tulnp (all listening ports)
listening  → lsof listening sockets
jcurl      → curl + pipe to jq
GET/POST/PUT/DELETE  → curl shortcuts with correct headers

# DB shortcuts
psql-dev   → psql -h postgres -U dev -d devdb
redis-dev  → redis-cli -h redis
mongo-dev  → mongosh mongodb://...@mongo:27017/devdb
```

---

## Adding a Custom Service

1. Add it to `.devcontainer/docker-compose.yml` under `services:`.
2. Set `networks: webdev:` on the new service.
3. Run `dc-up <yourservice>` from the terminal.

The new container is immediately reachable by hostname inside VS Code.

---

## Ports Forwarded to Your Host

| Port  | Service                 |
|-------|-------------------------|
| 3000  | App default             |
| 5173  | Vite dev server         |
| 8080  | HTTP alt                |
| 9090  | Prometheus              |
| 3030  | Grafana                 |
| 5432  | PostgreSQL              |
| 6379  | Redis                   |
| 27017 | MongoDB                 |
| 3306  | MySQL                   |
| 5672  | RabbitMQ AMQP           |
| 15672 | RabbitMQ Management UI  |
| 9200  | Elasticsearch           |

---

## Troubleshooting

**Docker socket permission denied:**
```bash
sudo chmod 666 /var/run/docker.sock
# or rebuild the container (VS Code: Ctrl+Shift+P → Rebuild Container)
```

**Service not reachable by hostname:**
```bash
# Check it's on the webdev network
docker network inspect webdev
# Make sure the service is running
dc ps
```

**Rebuild the devcontainer after Dockerfile changes:**
`Ctrl+Shift+P` → `Dev Containers: Rebuild Container`
