#!/usr/bin/env sh
set -eu

usage() {
  cat <<'USAGE'
Usage: tmux-session-workspace.sh [target_dir] [session_name]

When run inside tmux with no session_name, inserts a workspace layout at
windows 1/2/3 in the current session (existing windows are shifted right):
  1: term
  2: git   (runs lazygit when available)
  3: codex (runs codex when available)

When session_name is provided (or when run outside tmux), creates/switches to
that named session rooted at target_dir.
USAGE
}

sanitize_name() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs '[:alnum:]_-' '-' \
    | sed 's/^-*//; s/-*$//'
}

attach_or_switch() {
  session="$1"
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}

new_git_window() {
  session="$1"
  target_dir="$2"

  if command -v lazygit >/dev/null 2>&1; then
    tmux new-window -d -t "$session:2" -c "$target_dir" -n "git" env EDITOR=nvim lazygit
  else
    tmux new-window -d -t "$session:2" -c "$target_dir" -n "git"
  fi
}

new_codex_window() {
  session="$1"
  target_dir="$2"

  if command -v codex >/dev/null 2>&1; then
    tmux new-window -d -t "$session:3" -c "$target_dir" -n "codex" codex
  else
    tmux new-window -d -t "$session:3" -c "$target_dir" -n "codex"
  fi
}

create_workspace_session() {
  session="$1"
  target_dir="$2"

  tmux new-session -d -s "$session" -c "$target_dir" -n "term"
  new_git_window "$session" "$target_dir"
  new_codex_window "$session" "$target_dir"

  tmux select-window -t "$session:1"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

target_dir="${1:-$PWD}"
session_name="${2:-}"

if [ ! -d "$target_dir" ]; then
  printf 'tmux-session-workspace: directory does not exist: %s\n' "$target_dir" >&2
  exit 1
fi

target_dir="$(cd "$target_dir" && pwd -P)"

if [ -n "${TMUX:-}" ] && [ -z "$session_name" ]; then
  current_session="$(tmux display-message -p '#S')"

  if command -v codex >/dev/null 2>&1; then
    tmux new-window -d -b -t "$current_session:1" -c "$target_dir" -n "codex" codex
  else
    tmux new-window -d -b -t "$current_session:1" -c "$target_dir" -n "codex"
  fi

  if command -v lazygit >/dev/null 2>&1; then
    tmux new-window -d -b -t "$current_session:1" -c "$target_dir" -n "git" env EDITOR=nvim lazygit
  else
    tmux new-window -d -b -t "$current_session:1" -c "$target_dir" -n "git"
  fi

  tmux new-window -b -t "$current_session:1" -c "$target_dir" -n "term"
  exit 0
fi

if [ -z "$session_name" ]; then
  base_name="$(sanitize_name "$(basename "$target_dir")")"
  [ -n "$base_name" ] || base_name="workspace"
  checksum="$(printf '%s' "$target_dir" | cksum | awk '{print $1}')"
  suffix="$(printf '%s' "$checksum" | sed 's/.*\(....\)$/\1/')"
  session_name="${base_name}-${suffix}"
else
  session_name="$(sanitize_name "$session_name")"
  if [ -z "$session_name" ]; then
    printf 'tmux-session-workspace: invalid session_name\n' >&2
    exit 1
  fi
fi

if tmux has-session -t "$session_name" 2>/dev/null; then
  attach_or_switch "$session_name"
  exit 0
fi

create_workspace_session "$session_name" "$target_dir"

attach_or_switch "$session_name"
