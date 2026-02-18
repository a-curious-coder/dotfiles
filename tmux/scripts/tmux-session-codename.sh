#!/usr/bin/env sh
set -eu

session_name="${1:-}"
case "$session_name" in
  ""|*[!0-9]*)
    exit 0
    ;;
esac

adjectives="amber calm clear deft lucid quiet steady swift"
nouns="atlas beacon cedar harbor nexus orbit quill vector"

rand_num() {
  od -An -N2 -tu2 /dev/urandom 2>/dev/null | tr -d ' '
}

pick_word() {
  list="$1"
  # shellcheck disable=SC2086
  set -- $list
  count=$#
  [ "$count" -gt 0 ] || return 1
  idx=$(( ($(rand_num) % count) + 1 ))
  eval "printf '%s' \"\${$idx}\""
}

adjective="$(pick_word "$adjectives")" || exit 0
noun="$(pick_word "$nouns")" || exit 0
suffix="$(printf '%02d' $(( $(rand_num) % 100 )))"
new_name="${adjective}-${noun}-${suffix}"

if tmux has-session -t "$new_name" 2>/dev/null; then
  suffix="$(printf '%02d' $(( $(rand_num) % 100 )))"
  new_name="${adjective}-${noun}-${suffix}"
fi

tmux rename-session -t "$session_name" "$new_name" >/dev/null 2>&1 || true
