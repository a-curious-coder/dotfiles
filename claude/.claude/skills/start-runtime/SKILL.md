---
name: start-runtime
description: Start and verify the current codebase's local runtime is actually up, for local user testing/evaluation — and document the setup process for future reference if no such document exists yet. Use when the user asks to run/start/spin up the app, wants to test a change locally, or asks "is it running" / "get it running" / "start the dev server".
---

# start-runtime

## Purpose

Get the current project's app running locally and *confirm* it's actually
reachable — not just launch a command and hope. "Started" means a real
request against it succeeded, not that a process exists. Every run also
leaves the setup documented, so the next person (or the next run of this
skill) never has to re-derive it.

## Step 1: Look for an existing runtime-setup document

Before anything else, check whether this project already documents its own
setup end to end — not just a one-line launch command, but the full picture:
how to start it, every route/port, and every local credential. Check, in
this order:

1. `docs/local-runtime.md` (this skill's own convention — check first, it's
   the most likely place a prior run left one).
2. A project-local skill that documents this — `.claude/skills/verify/SKILL.md`,
   `.claude/skills/run/SKILL.md`, or similar.
3. `README.md` / `CLAUDE.md` for an explicit "dev environment" / "getting
   started" section.

**If a document exists and is complete** (covers start command, every
route, every credential) — use it, skip to Step 3, and don't rewrite it.

**If a document exists but is thin** (e.g. CLAUDE.md has just the start
command, no route/credential table) — treat it as a lead for Step 2, and
plan to write the fuller `docs/local-runtime.md` once the runtime is up.

**If nothing exists** — proceed to Step 2, and write the document once the
runtime is confirmed running (Step 4).

## Step 2: Detect the stack and start it

Check for these, in order, and use the first match:

- **`docker-compose.dev.yml`** (or `docker-compose.yml` if no `.dev` variant) →
  `docker compose -f <file> up -d`. If services already exist but look stale
  (built more than a few commits ago, or a service the current branch touches
  isn't in `docker compose ps`), rebuild: `docker compose -f <file> up -d --build`.
- **`package.json`** with a `dev` or `start` script → run it with the
  project's actual package manager (check for `pnpm-lock.yaml` /
  `yarn.lock` / `package-lock.json` — don't assume npm). Background it; don't
  block the turn on a long-running dev server.
- **`pyproject.toml` / `manage.py`** → the project's documented run command
  (`manage.py runserver`, `uvicorn ...`, etc. — check `pyproject.toml`
  scripts or README first rather than guessing flags).
- Nothing recognized → ask the user how this project is normally run, rather
  than inventing a command.

Don't build more than the stack needs. A plain `npm run dev` doesn't need
docker; don't reach for docker-compose because it feels more thorough.

While doing this, note down every route/port and every credential
encountered (admin logins, seeded test accounts, service URLs, ports) — this
is the raw material for Step 4's document, and it's much cheaper to note as
you go than to re-derive afterward.

## Step 3: Verify it's actually reachable

A launched process is not a running runtime. After starting (or finding it
already running), confirm with a real request:

- HTTP service → `curl -sf -o /dev/null -w '%{http_code}' <url>` against the
  root or a health endpoint. Retry a few times with short waits if the
  service needs a moment to boot — don't declare failure on the first
  connection-refused.
- Non-HTTP (CLI tool, background worker) → run its actual smoke check if one
  exists (a `--version`, a health command); otherwise confirm the process is
  alive and its logs show no startup error.

If verification fails, read the service's logs before reporting back —
report the actual error, not just "didn't come up."

## Step 4: Write or update the runtime-setup document

Skip this step only if Step 1 found a document that was already complete.

Write (or fill in the gaps of) `docs/local-runtime.md` in the project repo —
not the Obsidian vault; this is project documentation for anyone who clones
the repo, not personal recall. Body in **ASD-STE100** (Simplified Technical
English): short sentences, one instruction per sentence, active voice,
numbered steps for the start procedure. Structure:

1. **Start procedure** — numbered steps, the exact commands, from a clean
   checkout to a running instance.
2. **Routes table** — every reachable service, its local URL/port, and what
   it's for.
3. **Credentials table** — every local login: identity, secret, what it
   unlocks. Local dev-only credentials are fine to write in plain text (they
   are not real secrets); never write a production/live credential into this
   file.
4. **Gotchas** — anything non-obvious hit while starting it (a stale image
   needing `--build`, a service that needs a moment to boot, a port
   collision) — one line each, so the next run doesn't rediscover them.

This step is a real file write — use the Write/Edit tool, not just a chat
reply. The file is what makes this skill self-improving: the next run reads
it back in Step 1 instead of redoing this work.

## Step 5: Report

Reply with a table (routes + credentials) and/or ASD-STE100 prose covering
everything needed to reach and use the runtime right now — every route,
every credential. State what's running and where, not just "started." If
something was already running and needed no action, say that — don't
restart a healthy runtime unnecessarily. If Step 4 wrote or updated the doc,
say so and give its path.
