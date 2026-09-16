# Getting updates

Your repo started as a snapshot of the course template. When the instructor
fixes a bug or adds something new to the template, your copy doesn't get it
automatically — you pull it in yourself, the same way you'd pull in any
other change.

## Checking for updates

Every time your container starts, it checks whether the template has moved
ahead and prints a note in the terminal if so:

```
📦 3 update(s) available from the course template.
   Run 'git merge upstream/main' to pick them up, then Rebuild Container.
```

If you don't see that message, you're already up to date (or the check
hasn't run yet — it's throttled to about once every 6 hours to avoid
slowing down every container start).

## Pulling in updates

```bash
git fetch upstream
git merge upstream/main
```

This merges the template's changes into your own work, the same as merging
any other branch. If you haven't changed any of the files the update
touches, this will merge cleanly with no extra steps. If you *have* changed
one of those files (e.g. you edited `.devcontainer/compose.yml` yourself),
git will ask you to resolve the conflict the normal way.

After merging, rebuild your container so the changes actually take effect:
**Command Palette → "Dev Containers: Rebuild Container"**.

## If `upstream` isn't configured

This should be set up automatically the first time your container builds.
If it's missing for some reason, add it yourself:

```bash
git remote add upstream https://github.com/timdrichards/cargo.git
```
