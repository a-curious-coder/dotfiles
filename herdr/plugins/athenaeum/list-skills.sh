#!/bin/bash
# Athenaeum: fuzzy cheatsheet of AI agent skills/rules.
# Scoped to the focused pane's detected agent when herdr reports one;
# otherwise lists every agent's skills, grouped and labelled.
set -euo pipefail

# --- 1. Which agent, if any, owns the pane we were opened from? ------------
# herdr pane list gives every pane's .agent field (confirmed via `herdr pane
# list` — see docs/plugins/ for the runtime env vars this reads).
focused_agent=""
if [[ -n "${HERDR_PANE_ID:-}" ]] && command -v herdr >/dev/null 2>&1; then
  focused_agent=$(herdr pane list 2>/dev/null \
    | jq -r --arg pid "$HERDR_PANE_ID" \
      '.result.panes[]? | select(.pane_id == $pid) | .agent // empty' 2>/dev/null || true)
fi

# --- 2. Per-agent skill sources ---------------------------------------------
# ponytail: only Claude (SKILL.md frontmatter) and Cursor (.mdc rule
# frontmatter) have a verified, documented file format as of Aug 2026.
# Every other herdr-recognised agent (codex, gemini, opencode, copilot,
# cline, devin, droid, amp, grok, kimi, kiro, kilo, qoder, qodercli, pi,
# hermes) gets a stub line instead of a guessed-at file format. Add a
# `list_<agent>` function + a case arm below once that agent ships a real
# skills convention worth reading.

cwd=""
if [[ -n "$focused_agent" && -n "${HERDR_PANE_ID:-}" ]]; then
  cwd=$(herdr pane list 2>/dev/null \
    | jq -r --arg pid "$HERDR_PANE_ID" \
      '.result.panes[]? | select(.pane_id == $pid) | (.foreground_cwd // .cwd // empty)' 2>/dev/null || true)
fi

# ponytail: single-line frontmatter values only. A `description: >` or `|`
# YAML block scalar (continues on following lines) prints empty here — fix by
# reading subsequent indented lines if that gap starts mattering.
frontmatter_field() { # $1 file, $2 field name -> prints value
  awk -v f="$2" '
    BEGIN { in_fm=0 }
    /^---$/ { in_fm++; next }
    in_fm==1 && $0 ~ "^"f":" {
      sub("^"f": *", "")
      gsub(/^"|"$/, "")
      gsub(/^> *$/, "")
      print
      exit
    }
  ' "$1"
}

list_claude() {
  local dirs=("$HOME/.claude/skills")
  [[ -n "$cwd" && -d "$cwd/.claude/skills" ]] && dirs+=("$cwd/.claude/skills")
  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    for f in "$dir"/*/SKILL.md; do
      [[ -f "$f" ]] || continue
      name=$(frontmatter_field "$f" name)
      [[ -z "$name" ]] && name=$(basename "$(dirname "$f")")
      desc=$(frontmatter_field "$f" description)
      printf 'claude\t%s\t%s\n' "$name" "$desc"
    done
  done
}

list_cursor() {
  [[ -n "$cwd" && -d "$cwd/.cursor/rules" ]] || return 0
  for f in "$cwd"/.cursor/rules/*.mdc; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f" .mdc)
    desc=$(frontmatter_field "$f" description)
    printf 'cursor\t%s\t%s\n' "$name" "$desc"
  done
}

KNOWN_AGENTS="pi claude codex gemini cursor devin cline opencode copilot kimi kiro droid amp grok hermes kilo qodercli qoder"

collect_for() {
  case "$1" in
    claude) list_claude ;;
    cursor) list_cursor ;;
    *) printf '%s\t(no known skill source yet)\t-\n' "$1" ;;
  esac
}

rows=""
if [[ -n "$focused_agent" ]]; then
  rows=$(collect_for "$focused_agent")
else
  for a in $KNOWN_AGENTS; do
    out=$(collect_for "$a")
    [[ -n "$out" ]] && rows+="$out"$'\n'
  done
fi

rows=$(printf '%s\n' "$rows" | sed '/^$/d' | sort -t $'\t' -k2,2)

if [[ -z "$rows" ]]; then
  echo "No skills found${focused_agent:+ for agent '$focused_agent'}."
  read -r -p "Press enter to close..." _
  exit 0
fi

if command -v fzf >/dev/null 2>&1; then
  printf '%s\n' "$rows" \
    | awk -F'\t' '{printf "%-8s  %-28s  %s\n", $1, $2, $3}' \
    | fzf --header="Athenaeum — skills${focused_agent:+ (agent: $focused_agent)}" \
          --prompt="skill> " --no-sort
else
  printf '%s\n' "$rows" | awk -F'\t' '{printf "%-8s  %-28s  %s\n", $1, $2, $3}'
  read -r -p "Press enter to close..." _
fi
