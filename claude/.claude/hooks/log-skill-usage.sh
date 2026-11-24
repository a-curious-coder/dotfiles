#!/usr/bin/env bash
# PostToolUse hook (matcher: Skill) — appends one JSON line per Skill invocation
# to ~/.claude/logs/skill-usage.jsonl so usage can be reported on later.
mkdir -p "$HOME/.claude/logs"
jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{ts: $ts, skill: .tool_input.skill, args: .tool_input.args}' \
  >> "$HOME/.claude/logs/skill-usage.jsonl" 2>/dev/null || true
