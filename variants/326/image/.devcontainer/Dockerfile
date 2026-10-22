# ============================================================
# Gantry 326 — minimal image for COMPSCI 326 Web Programming
#
# Built by .github/workflows/build-326-image.yml and pushed to
# ghcr.io/timdrichards/gantry-326, so a student's Codespace pulls it
# instead of building anything.
#
# Base: the official Node image on Debian slim, not the Microsoft
# devcontainers base. It already has Node and npm, and its `node`
# user (uid 1000) is renamed to `vscode` below so the rest of the
# 326 config is unchanged. Debian, not Alpine: Alpine's musl libc
# breaks some VS Code extensions and prebuilt npm binaries.
#
# Only what the course uses: Node + npm, git, gh and curl (both all
# over the unit pages), the Docker CLI + compose for `dc-up mongo`,
# a terminal editor for git (Lab 06's interactive rebase opens one),
# and a few small tools the shell aliases use. No compilers: bcrypt
# installs from its prebuilt binary. MongoDB runs as a sidecar, and
# `mongo-dev` runs mongosh inside it, so neither is installed here.
# ============================================================
FROM node:26-bookworm-slim

ARG USERNAME=vscode

# ------------------------------------------------------------
# 1. apt packages, with the GitHub CLI repo, in one layer
# ------------------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl git less nano vim-tiny jq procps lsof sudo; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /etc/apt/keyrings/githubcli.gpg; \
    chmod a+r /etc/apt/keyrings/githubcli.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends gh; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/*

# ------------------------------------------------------------
# 2. Docker CLI + compose plugin, copied in as single binaries
#    (no daemon: the container talks to the host's Docker socket)
# ------------------------------------------------------------
COPY --from=docker:27-cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker/compose-bin:v2.29.7 /docker-compose /usr/local/libexec/docker/cli-plugins/docker-compose

# ------------------------------------------------------------
# 3. The `vscode` user: rename the image's `node` user, add it to a
#    docker group (post-start.sh gives the socket to that group),
#    passwordless sudo, and pre-own the dirs named volumes mount over.
# ------------------------------------------------------------
RUN set -eux; \
    groupmod -n ${USERNAME} node; \
    usermod -l ${USERNAME} -d /home/${USERNAME} -m node; \
    groupadd -f docker; \
    usermod -aG docker ${USERNAME}; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}; \
    chmod 0440 /etc/sudoers.d/${USERNAME}; \
    mkdir -p /home/${USERNAME}/.config/gh /commandhistory; \
    touch /commandhistory/.bash_history; \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} /commandhistory; \
    npm config --global set update-notifier false; \
    npm config --global set fund false

# ------------------------------------------------------------
# 4. Shell config lives in the student repo, so updates to it ship
#    through the template sync without rebuilding this image.
# ------------------------------------------------------------
RUN ln -s /gantry/.devcontainer/shell/.bashrc_devcontainer /etc/bash_devcontainer \
    && echo '[ -f /etc/bash_devcontainer ] && source /etc/bash_devcontainer' >> /etc/bash.bashrc

ENV EDITOR=nano
WORKDIR /gantry
USER ${USERNAME}
