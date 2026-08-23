---
name: start-runtime
description: Start and verify the current codebase's local runtime is actually up, for local user testing/evaluation. Use when the user asks to run/start/spin up the app, wants to test a change locally, or asks "is it running" / "get it running" / "start the dev server".
---

# start-runtime

## Purpose

Get the current project's app running locally and *confirm* it's actually
reachable — not just launch a command and hope. "Started" means a real
request against it succeeded, not that a process exists.

## Step 1: Prefer a project's own launch instructions

Check, in order, before guessing:

1. A project-local skill that already documents this — `.claude/skills/verify/SKILL.md`,
   `.claude/skills/run/SKILL.md`, or similar. If one exists, follow it instead
   of anything below; it knows the project's real gotchas.
2. `CLAUDE.md` / `README.md` for an explicit "dev environment" / "getting started" section.

Only fall through to Step 2 if neither exists.

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

## Step 4: Report

State what's running and where to reach it (URL/port), not just "started."
If something was already running and needed no action, say that — don't
restart a healthy runtime unnecessarily.
