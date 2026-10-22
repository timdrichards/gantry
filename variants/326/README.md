# Gantry 326 variant

A stripped-down build of gantry for COMPSCI 326 Web Programming. The image
is built on the official `node:26-bookworm-slim` image, not the Microsoft
devcontainers base, and ships only what 326 uses: Node and npm, git, gh, curl,
the Docker CLI and compose (for `dc-up mongo`), a terminal editor for git, and
a few small tools the shell aliases need. MongoDB is an on-demand sidecar.
Everything else in gantry (Postgres, Redis, Kafka, the observability stack,
global npm packages, compilers, Java, the plugin system, ~70 VS Code
extensions) is left out.

Sizes, measured 2026-10-22: the full gantry image is 4.88 GB; the first 326
image (on the Microsoft base) was 1.23 GB, about 450 MB to download; this one
is about 530 MB, about 190 MB to download.

| Folder | What it is | Shipped to students as |
|---|---|---|
| `image/.devcontainer/` | Dockerfile + features for `ghcr.io/timdrichards/gantry-326` | nothing (built into the image) |
| `devcontainer/` | compose (dev container + mongo), devcontainer.json, shell, scripts | `.devcontainer/` |
| `root/` | `.env.example`, `.gitignore`, `.gitattributes`, `work/README.md` | repo root |

Gantry's `doc/` is shipped too. The target repo's own `README.md` is never
touched (same rule as the main cargo sync).

## Why it starts fast

The image is built once, in GitHub Actions, by
`.github/workflows/build-326-image.yml`, with the Dev Containers CLI so the
sshd feature (for `gh codespace ssh`) is baked in. It is pushed to
GHCR for `linux/amd64` (Codespaces) and `linux/arm64` (Apple-silicon Macs).
A Codespace pulls the image; it builds nothing and installs no features.
The extension list is 11 instead of 71.

The image rebuilds on a push to `main` that touches `variants/326/image/`,
on the 1st of each month (security updates), or by hand from the Actions
tab. Each build is tagged `latest` and with the commit SHA, so a bad image
can be rolled back by pointing `devcontainer/compose.yml` at an older SHA.

## Sync to the student repo

`.github/workflows/sync-cargo-326.yml` runs `.github/scripts/stage-cargo-326.sh`
and pushes the result to the repo named in the `CARGO_326_REPO` repository
variable (default `timdrichards/cargo`, which is 326-only from 2026-10-22; the full-gantry sync, `sync-cargo.yml`, is turned off so it cannot overwrite it), using
`CARGO_SYNC_TOKEN`. That token must have Contents: Read and write on the
target repo.

## Test locally

```bash
npx @devcontainers/cli build --workspace-folder variants/326/image --image-name gantry-326:dev
```
