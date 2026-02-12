#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck is required but not installed" >&2
  exit 1
fi

# Keep checks fast and focused on maintained repo scripts.
shopt -s nullglob
scripts=(./*.sh ./scripts/*.sh)
shopt -u nullglob

if [[ "${#scripts[@]}" -eq 0 ]]; then
  echo "No shell scripts found."
  exit 0
fi

shellcheck -x "${scripts[@]}"
