---
name: release
description: Cut a new dated GitHub release of this gantry devcontainer template — tags HEAD as vMM-DD-YYYY, builds a distribution zip containing only .devcontainer/, .env.example, and README.md, and publishes it via gh release create. Trigger when the user asks to "cut a release," "make/generate a new release," or references the gantry release procedure.
---

# Release

Cuts a dated release of this repo for distribution to template consumers.
Releases are **not** automated via CI — this is a manual (or Claude-assisted)
procedure run from a clean `main`.

## Before starting

- Confirm the working tree is clean (`git status`). If there are uncommitted
  changes the user wants shipped, commit and push them to `main` first.
- Format today's date as the tag: `vMM-DD-YYYY` (e.g. `v07-06-2026`). Run
  `git tag --sort=-creatordate | head -5` to confirm the existing pattern
  hasn't changed.
- Check whether a tag for today already exists
  (`git tag -l vMM-DD-YYYY`). If it does, ask the user whether to move it to
  the new commit (delete + recreate — see below) or keep both, rather than
  assuming.
- Tagging, pushing, and publishing are visible/hard-to-reverse actions —
  confirm the tag name, target commit, and same-day-collision handling with
  the user before running these commands.

## Steps

1. **Tag and push**

   ```bash
   git tag -a vMM-DD-YYYY -m "gantry vMM-DD-YYYY"
   git push origin vMM-DD-YYYY
   ```

2. **Stage the distribution file set.** The release zip is **not** a full
   repo archive. It contains only:

   - `.devcontainer/`
   - `.env.example`
   - `README.md`

   Explicitly excluded: `docs/`, `CLAUDE.md`, `.vscode/`, `.claude/`,
   `.gitignore`, `.gitattributes`, `NOTES.md`, `cspell.json`, and any other
   repo-meta file. This list has drifted before (`docs/` was mistakenly
   included in an earlier release) — verify against this list each time
   rather than copying the contents of a prior release's zip by analogy.

   ```bash
   STAGE=$(mktemp -d)
   cp -R .devcontainer "$STAGE/"
   cp .env.example "$STAGE/"
   cp README.md "$STAGE/"
   find "$STAGE" -name ".DS_Store" -delete
   cd "$STAGE" && zip -r -X /tmp/gantry-vMM-DD-YYYY.zip .devcontainer .env.example README.md
   ```

3. **Publish the release**

   ```bash
   gh release create vMM-DD-YYYY /tmp/gantry-vMM-DD-YYYY.zip \
     --repo timdrichards/gantry \
     --title "gantry vMM-DD-YYYY" \
     --notes "Distribution release vMM-DD-YYYY."
   ```

## Same-day re-release (tag already exists)

To move today's release to a new commit instead of stacking a second one:

```bash
gh release delete vMM-DD-YYYY --repo timdrichards/gantry --cleanup-tag --yes
git tag -a vMM-DD-YYYY -m "gantry vMM-DD-YYYY" <new-commit-sha>
git push origin vMM-DD-YYYY
```

Then repeat steps 2–3 above.
