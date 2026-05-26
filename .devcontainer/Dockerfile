# ============================================================
# Dev Container — Web Programming & Scalable Web Systems
# Node.js LTS | Docker-in-Docker | Full Network Tooling
# ============================================================
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG NODE_VERSION=22
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

# ------------------------------------------------------------
# 1. Base system packages
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    curl wget ca-certificates gnupg lsb-release \
    git git-lfs unzip zip \
    build-essential pkg-config \
    # Network / analysis tools
    jq \
    httpie \
    netcat-openbsd \
    nmap \
    dnsutils \
    iputils-ping \
    traceroute \
    tcpdump \
    wireshark-common \
    tshark \
    net-tools \
    iproute2 \
    iptables \
    socat \
    openssl \
    mtr \
    # Text / data tools
    ripgrep \
    fzf \
    bat \
    fd-find \
    tree \
    htop \
    less \
    vim \
    nano \
    # Process / system
    procps \
    lsof \
    strace \
    psmisc \
    # Database CLI clients (connect to external containers)
    postgresql-client \
    redis-tools \
    sqlite3 \
    # Python (for scripting / tooling)
    python3 \
    python3-pip \
    python3-venv \
    # Misc
    sudo \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Symlink fd (installed as fdfind on Ubuntu)
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd

# ------------------------------------------------------------
# 2. Node.js via NodeSource (latest LTS)
# ------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 3. Global npm packages for web dev / scalable systems
# ------------------------------------------------------------
RUN npm install -g \
    # Package managers
    pnpm \
    yarn \
    # TypeScript ecosystem
    typescript \
    ts-node \
    tsx \
    @types/node \
    # Build / bundlers
    vite \
    esbuild \
    # Linting / formatting
    eslint \
    prettier \
    # API / HTTP tooling
    httpyac \
    # Process management
    pm2 \
    nodemon \
    # Database ORMs / tools
    prisma \
    # Testing
    vitest \
    jest \
    # Deployment / devops helpers
    dotenv-cli \
    # Misc dev utilities
    concurrently \
    cross-env

# ------------------------------------------------------------
# 4. Docker CLI + Docker Compose (for DinD)
# ------------------------------------------------------------
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
       | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       docker-ce-cli \
       docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Convenience alias: `docker compose` → also available as `docker-compose`
RUN ln -sf /usr/libexec/docker/cli-plugins/docker-compose \
           /usr/local/bin/docker-compose

# ------------------------------------------------------------
# 5. GitHub CLI
# ------------------------------------------------------------
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
       https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 6. Additional CLI tools
# ------------------------------------------------------------

# k6 — load / performance testing (arch-aware; apt repo only ships amd64)
RUN ARCH=$(dpkg --print-architecture) \
    && K6_VER=$(curl -s https://api.github.com/repos/grafana/k6/releases/latest | jq -r .tag_name) \
    && curl -fsSL "https://github.com/grafana/k6/releases/download/${K6_VER}/k6-${K6_VER}-linux-${ARCH}.tar.gz" \
       | tar -xz --strip-components=1 -C /usr/local/bin --wildcards "*/k6" \
    && chmod +x /usr/local/bin/k6 || true

# mongosh — MongoDB shell
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
       | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
       https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
       > /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends mongodb-mongosh \
    && rm -rf /var/lib/apt/lists/*

# grpcurl — gRPC debugging
RUN ARCH=$(dpkg --print-architecture) \
    && GRPCURL_ARCH=$([ "$ARCH" = "amd64" ] && echo "x86_64" || echo "$ARCH") \
    && GRPCURL_VERSION=$(curl -s https://api.github.com/repos/fullstorydev/grpcurl/releases/latest \
         | jq -r .tag_name | tr -d v) \
    && curl -fsSL \
      "https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_linux_${GRPCURL_ARCH}.tar.gz" \
      | tar -xz -C /usr/local/bin grpcurl \
    && chmod +x /usr/local/bin/grpcurl || true

# websocat — WebSocket testing from CLI
RUN ARCH=$(dpkg --print-architecture) \
    && WSCAT_ARCH=$([ "$ARCH" = "amd64" ] && echo "x86_64" || echo "aarch64") \
    && WSCAT_VER=$(curl -s https://api.github.com/repos/vi/websocat/releases/latest \
         | jq -r .tag_name) \
    && curl -fsSL \
      "https://github.com/vi/websocat/releases/download/${WSCAT_VER}/websocat.${WSCAT_ARCH}-unknown-linux-musl" \
      -o /usr/local/bin/websocat \
    && chmod +x /usr/local/bin/websocat || true

# xh — fast, friendly HTTP client (curl alternative)
RUN ARCH=$(dpkg --print-architecture) \
    && XH_ARCH=$([ "$ARCH" = "amd64" ] && echo "x86_64" || echo "aarch64") \
    && XH_VER=$(curl -s https://api.github.com/repos/ducaale/xh/releases/latest \
         | jq -r .tag_name) \
    && curl -fsSL \
      "https://github.com/ducaale/xh/releases/download/${XH_VER}/xh-${XH_VER}-${XH_ARCH}-unknown-linux-musl.tar.gz" \
      | tar -xz --strip-components=1 -C /usr/local/bin --wildcards '*/xh' || true

# ------------------------------------------------------------
# 7. Shell ergonomics
# ------------------------------------------------------------
COPY shell/.bashrc_devcontainer /etc/bash_devcontainer
RUN echo 'source /etc/bash_devcontainer' >> /etc/bash.bashrc

# ------------------------------------------------------------
# 8. User setup — add vscode user to docker group (DinD)
# ------------------------------------------------------------
RUN groupadd -f docker \
    && usermod -aG docker ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME}

# ------------------------------------------------------------
# 9. Working directory
# ------------------------------------------------------------
WORKDIR /workspace
USER ${USERNAME}
