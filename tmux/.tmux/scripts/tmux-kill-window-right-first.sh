#!/usr/bin/env sh
set -eu

session_name="$(tmux display-message -p '#S')"
current_index="$(tmux display-message -p '#I')"

next_index=""
prev_index=""

for idx in $(tmux list-windows -t "$session_name" -F '#I' | sort -n); do
  if [ "$idx" -gt "$current_index" ] && [ -z "$next_index" ]; then
    next_index="$idx"
  fi
  if [ "$idx" -lt "$current_index" ]; then
    prev_index="$idx"
  fi
done

target_after_kill=""
if [ -n "$next_index" ]; then
  # With renumber-windows enabled, the right neighbor shifts into current_index.
  target_after_kill="$current_index"
elif [ -n "$prev_index" ]; then
  target_after_kill="$prev_index"
fi

tmux kill-window -t "$session_name:$current_index"

if [ -n "$target_after_kill" ] && tmux has-session -t "$session_name" 2>/dev/null; then
  tmux select-window -t "$session_name:$target_after_kill" >/dev/null 2>&1 || true
fi
