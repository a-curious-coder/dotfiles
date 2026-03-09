#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail_count=0

run_check() {
  local label="$1"
  shift

  printf '==> %s\n' "$label"
  if "$@"; then
    printf 'ok: %s\n' "$label"
  else
    printf 'fail: %s\n' "$label" >&2
    fail_count=$((fail_count + 1))
  fi
}

run_check "shellcheck" ./scripts/check-shell.sh
run_check "nvim text-specs" ./scripts/run-nvim-text-specs.sh
run_check "tmux config" ./tmux/tests/verify_tmux_config.sh

if [ "$fail_count" -ne 0 ]; then
  printf 'doctor: %s check(s) failed\n' "$fail_count" >&2
  exit 1
fi

printf 'doctor: all checks passed\n'
