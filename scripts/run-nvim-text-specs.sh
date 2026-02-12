#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
nvim_root="$repo_root/nvim/.config/nvim"

if ! command -v lua >/dev/null 2>&1; then
  echo "lua is required but not installed" >&2
  exit 1
fi

if [[ ! -d "$nvim_root/tests" ]]; then
  echo "Neovim tests directory not found: $nvim_root/tests" >&2
  exit 1
fi

cd "$nvim_root"

shopt -s nullglob
specs=(tests/*_spec.lua)
shopt -u nullglob

if [[ "${#specs[@]}" -eq 0 ]]; then
  echo "No Neovim text-spec files found."
  exit 0
fi

for spec in "${specs[@]}"; do
  echo "Running $spec"
  lua "$spec"
done

echo "Neovim text-specs passed."
