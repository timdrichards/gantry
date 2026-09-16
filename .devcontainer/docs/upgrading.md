# Upgrading Gantry

This guide walks you through updating an existing Gantry dev container to a
newer release. It's written for anyone who already has Gantry set up and
working — if you haven't installed it yet, see the main
[README.md](../README.md) instead.

Upgrading takes about 5 minutes. Read through once before you start typing.

---

## Do I need to do this?

Only when you have a specific reason to, such as:

- Your instructor announces a new Gantry release with a fix you need.
- You hit a bug and someone tells you it's already fixed in a newer release.
- You just want the newest tools and services.

If everything is working fine for you right now, there's no need to upgrade
just because a new release exists.

You can see what's changed between releases on the
[Releases page](https://github.com/timdrichards/gantry/releases) — each one
lists what was fixed or added.

---

## Before you start

An upgrade only ever touches three things in your project folder:

- `.devcontainer/`
- `.env.example`
- `README.md`

It never touches your own code, and it never touches data sitting inside
Docker (more on that below). Still, two things are worth doing first:

1. **Commit your work.** If your project is tracked with git, run:

   ```bash
   git add -A
   git commit -m "checkpoint before Gantry upgrade"
   ```

   That way, if anything looks wrong afterward, you can always undo it.
   > **Not using git yet?** At minimum, make a copy of your project folder
   > somewhere safe before continuing.

2. **Close the dev container.** In VS Code, open the Command Palette
   (`Ctrl+Shift+P` / `Cmd+Shift+P`), type **"Dev Containers: Reopen Folder
   Locally"**, and press Enter. This makes sure no files are locked or in use
   while you replace them.

---

## Step 1 — Download the new release

1. Go to the [Gantry Releases page](https://github.com/timdrichards/gantry/releases).
2. Find the release you want at the top of the list (releases are named by
   date, e.g. `v07-09-2026` — newer dates are newer releases).
3. Under **Assets**, click the `.zip` file to download it.
4. Extract the zip. You should see three items inside:

   ```
   .devcontainer/
   .env.example
   README.md
   ```

   > **Don't see `.devcontainer`?** Folders that start with a dot are
   > hidden by default in most file browsers. See
   > [Can't see the `.devcontainer` folder?](#cant-see-the-devcontainer-folder)
   > below, then come back here.

---

## Step 2 — Replace `.devcontainer`

This is the main step. The new `.devcontainer` folder replaces your old one
completely.

> **Customized `.devcontainer` yourself?** If you (or your instructor) added
> anything custom in there — an extra service in `compose.yml`, a tweaked
> `Dockerfile`, etc. — copy those specific changes out **before** you delete
> the old folder, so you can reapply them afterward. For most students, the
> folder is unmodified and this doesn't apply.

1. In your project folder, delete the existing `.devcontainer` folder.
2. Copy the new `.devcontainer` folder (from the zip you extracted) into
   your project folder, in the same place the old one was.

Your project folder should now have the brand-new `.devcontainer/` sitting
alongside your own code, exactly like before.

---

## Step 3 — Check `.env.example` for anything new

New releases sometimes add new services or connection strings to
`.env.example`. Your own `.env` file (the one with your actual values) is
**never** overwritten automatically — you need to check it manually.

1. Open the new `.env.example` from the zip.
2. Open your project's existing `.env` file.
3. Compare them. If the new `.env.example` has lines that aren't in your
   `.env`, copy those specific lines over.

> **Don't have a `.env` file yet?** Just copy `.env.example` to `.env` in
> your project root — there's nothing to preserve.

---

## Step 4 — Skim the new README (optional)

The zip includes a fresh copy of Gantry's `README.md` — the same getting
started guide you used originally. If you never modified your project's
`README.md`, feel free to replace it with the new one. If you've written
your own project's README over it, just skim the new one for anything
that looks new and skip replacing it.

---

## Step 5 — Rebuild the container

1. Reopen your project in VS Code, if it isn't already open.
2. Open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`).
3. Type **"Dev Containers: Rebuild Container"** and press Enter.
4. Wait for the build to finish — this can take a few minutes, same as the
   very first time you set things up.

---

## Step 6 — Confirm it worked

Open a new terminal inside the container (`` Ctrl+` ``) and check the
banner at the top — it should print without errors:

```
vscode@devcontainer:/gantry$
```

Run a quick sanity check:

```bash
node --version
docker --version
```

If you use any database services, start one and confirm it still connects:

```bash
dc-up postgres
psql-dev
```

---

## What upgrading does *not* touch

It's easy to worry an upgrade will wipe out your database data or other
container state. It won't:

- **Your code** — nothing outside `.devcontainer/`, `.env.example`, and
  `README.md` is ever touched.
- **Database data** — things like your Postgres or MongoDB data live in
  named Docker volumes, which exist outside your project folder entirely.
  Replacing `.devcontainer/` does not delete or reset them.
- **Installed plugins** — anything installed via `plugin install` lives in
  `/gantry/.plugins/` inside the container, which is a separate bind mount
  and isn't affected by replacing `.devcontainer/`.

---

## Can't see the `.devcontainer` folder?

Folders and files that start with a dot — like `.devcontainer` and `.env` —
are treated as hidden by most file browsers. You'll need to turn on "show
hidden files" to see, delete, or copy them in Steps 1 and 2 above.

**macOS (Finder):**

1. Open Finder and navigate to the folder you're working in.
2. Press `Cmd + Shift + .` (period).
3. Hidden files and folders — including `.devcontainer` — will now show up
   slightly faded. Press the same shortcut again to hide them once you're
   done.

**Windows (File Explorer):**

1. Open File Explorer and navigate to the folder you're working in.
2. Click the **View** tab at the top of the window.
   - **Windows 11:** click **View → Show → Hidden items**.
   - **Windows 10:** check the **Hidden items** box in the View tab's
     ribbon.
3. `.devcontainer` will now appear alongside your other files.

Either way, this setting stays on until you turn it off again — you won't
need to repeat it for future upgrades.

---

## Troubleshooting

**Rebuild fails or hangs.**
Make sure Docker Desktop is running, then try again. If it still fails,
run **"Dev Containers: Rebuild Container Without Cache"** from the Command
Palette for a clean rebuild.

**A database service won't authenticate after upgrading.**
This is almost never caused by the upgrade itself — it means the database
container was already running with old settings. Stop it and start it
again fresh:

```bash
dc-down <service>
dc-up <service>
```

**Something in `.devcontainer` looks different than what your instructor
expects.**
Double check you replaced the *entire* `.devcontainer` folder rather than
merging files by hand — partial merges are the most common source of
confusing, hard-to-explain bugs. When in doubt, delete it and copy the new
one in fresh.

**Still stuck?**
Ask your instructor or TA, and mention which release version you upgraded
*from* and *to* (the dates in the zip filenames) — that's the most useful
piece of information for someone helping you debug it.
