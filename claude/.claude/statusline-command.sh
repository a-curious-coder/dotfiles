#!/usr/bin/env bash
input=$(cat)
model=$(jq -r '.model.display_name' <<<"$input")
dir=$(jq -r '.workspace.current_dir' <<<"$input")
branch=$(git -C "$dir" branch --show-current 2>/dev/null)

printf '%s · %s' "$model" "${dir/#$HOME/\~}"
[ -n "$branch" ] && printf ' (%s)' "$branch"
