# ============================================================
# Gantry 326 — slim image for COMPSCI 326 Web Programming
#
# Built once by .github/workflows/build-326-image.yml and pushed to
# ghcr.io/timdrichards/gantry-326, so a student's Codespace pulls it
# instead of building anything. Only what 326 uses: Node + npm, git,
# gh, the Docker CLI (from the docker-outside-of-docker feature, for
# `dc-up mongo`), and build tools for native npm modules (bcrypt).
# MongoDB itself runs as a sidecar (see variants/326/devcontainer/
# compose.yml); its shell is reached through `mongo-dev`, which runs
# mongosh inside that container, so mongosh is not installed here.
#
# Layer order is deliberate: the slow, rarely-changing apt + Node
# layer first, so a change further down rebuilds in seconds.
# ============================================================
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG NODE_VERSION=26
ARG USERNAME=vscode

# ------------------------------------------------------------
# 1. All apt packages in ONE layer: add the NodeSource and GitHub CLI
#    repos first, then a single update + install, then clean up.
# ------------------------------------------------------------
RUN set -eux; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /etc/apt/keyrings/githubcli.gpg; \
    chmod a+r /etc/apt/keyrings/*.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      nodejs gh \
      build-essential python3 \
      jq ripgrep tree less nano vim-tiny \
      lsof psmisc iproute2 netcat-openbsd; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/*; \
    npm config --global set update-notifier false; \
    npm config --global set fund false

# ------------------------------------------------------------
# 2. Shell config lives in the student repo, so updates to it ship
#    through the normal template sync without rebuilding this image.
# ------------------------------------------------------------
RUN ln -s /gantry/.devcontainer/shell/.bashrc_devcontainer /etc/bash_devcontainer \
    && echo '[ -f /etc/bash_devcontainer ] && source /etc/bash_devcontainer' >> /etc/bash.bashrc

# ------------------------------------------------------------
# 3. User setup: docker group (DooD), passwordless sudo, and the gh
#    config dir pre-owned so the named volume over it inherits vscode.
# ------------------------------------------------------------
RUN groupadd -f docker \
    && usermod -aG docker ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && mkdir -p /home/${USERNAME}/.config/gh /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config /commandhistory

WORKDIR /gantry
USER ${USERNAME}
