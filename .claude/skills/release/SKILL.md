---
name: release
description: Cut a new dated GitHub release of the cargo student distribution repo (timdrichards/cargo) — tags cargo's current main HEAD as vMM-DD-YYYY, builds a distribution zip from cargo's tree (no filtering needed — cargo's main is already the exact student-facing content, kept in continuous sync from gantry), and publishes it via gh release create. Trigger when the user asks to "cut a release," "make/generate a new release," or references the gantry/cargo release procedure.
---

# Release

Cuts a dated release of **`timdrichards/cargo`** (the public student
distribution repo), not `gantry`. `gantry` is the instructor/development
repo; releases there wouldn't be usable by students even if `gantry` is
public, and the whole point of `cargo` is that it's the thing students
actually consume — see `CLAUDE.md`'s "Student Distribution: the `cargo`
Repo" section for the full architecture.

Releases are **not** automated via CI — this is a manual (or
Claude-assisted) procedure, run whenever a set of changes is judged
release-worthy. The continuous sync (`sync-cargo.yml`) already keeps
`cargo`'s `main` branch current on every push to `gantry`; a "release" is
just a deliberate, dated, zip-downloadable checkpoint on top of that for
people who'd rather download a zip than deal with git.

## Before starting

- Confirm `cargo`'s `main` is caught up with the latest `gantry` push —
  check the most recent `sync-cargo.yml` run succeeded
  (`gh run list --repo timdrichards/gantry --workflow=sync-cargo.yml --limit 1`).
  If it's still running or failed, sort that out first; don't release
  against a stale `cargo`.
- Format today's date as the tag: `vMM-DD-YYYY` (e.g. `v09-18-2026`). Run
  `git ls-remote --tags https://github.com/timdrichards/cargo.git | sort | tail -5`
  to confirm the existing pattern hasn't changed.
- Check whether a tag for today already exists on `cargo`
  (`git ls-remote --tags https://github.com/timdrichards/cargo.git | grep vMM-DD-YYYY`).
  If it does, ask the user whether to move it to the new commit (delete +
  recreate — see below) or keep both, rather than assuming.
- Tagging, pushing, and publishing are visible/hard-to-reverse actions —
  confirm the tag name, target commit, and same-day-collision handling
  with the user before running these commands.

## Steps

1. **Get a clean checkout of cargo's current main:**

   ```bash
   CHECKOUT=$(mktemp -d)
   git clone --depth 1 https://github.com/timdrichards/cargo.git "$CHECKOUT"
   ```

2. **Tag and push** (on `cargo`, not `gantry`):

   ```bash
   cd "$CHECKOUT"
   git tag -a vMM-DD-YYYY -m "cargo vMM-DD-YYYY"
   git push origin vMM-DD-YYYY
   ```

3. **Build the zip.** Unlike the old gantry-targeted process, there's no
   filtering to do — `cargo`'s tree at this commit *is* the exact,
   already-correct distribution content (the sync already stripped
   `CLAUDE.md`, `.claude/`, `.devcontainer/docs/`, etc. before it ever
   reached `cargo`). Just zip the checkout, excluding `.git`:

   ```bash
   cd "$CHECKOUT"
   rm -rf .git
   find . -name ".DS_Store" -delete
   zip -r -X /tmp/cargo-vMM-DD-YYYY.zip .
   ```

4. **Publish the release:**

   ```bash
   gh release create vMM-DD-YYYY /tmp/cargo-vMM-DD-YYYY.zip \
     --repo timdrichards/cargo \
     --title "cargo vMM-DD-YYYY" \
     --notes "Distribution release vMM-DD-YYYY."
   ```

## Same-day re-release (tag already exists)

To move today's release to a new commit instead of stacking a second one:

```bash
gh release delete vMM-DD-YYYY --repo timdrichards/cargo --cleanup-tag --yes
git tag -a vMM-DD-YYYY -m "cargo vMM-DD-YYYY" <new-commit-sha>
git push origin vMM-DD-YYYY
```

Then repeat steps 3–4 above.
