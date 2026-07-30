#!/usr/bin/env bash
# Every stow package must install through dot-prefixed paths only. A package
# that ships a plain top-level directory (scripts/, systemd/, docs/) links it
# straight into $HOME and collides with the user's own files.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v stow >/dev/null 2>&1; then
  printf 'stow is required but not installed\n' >&2
  exit 1
fi

target_dir="$(mktemp -d)"
trap 'rm -rf "$target_dir"' EXIT

fail_count=0

for package in */; do
  package="${package%/}"
  # A stow package is a directory with dot-prefixed contents. .gitignore alone
  # does not make one (transcription-stack is a plain project directory).
  if [ -z "$(find "$package" -maxdepth 1 -name '.*' ! -name '.' ! -name '.gitignore' -print -quit)" ]; then
    continue
  fi

  stray="$(stow -n -v -t "$target_dir" "$package" 2>&1 | rg '^(LINK|MKDIR): [^.]' || true)"
  if [ -n "$stray" ]; then
    printf 'FAIL: %s links non-dotfile paths into $HOME\n' "$package" >&2
    printf '%s\n' "$stray" >&2
    fail_count=$((fail_count + 1))
  else
    printf 'PASS: %s installs only dot-prefixed paths\n' "$package"
  fi
done

if [ "$fail_count" -ne 0 ]; then
  printf '%s package(s) would write outside dot-prefixed paths\n' "$fail_count" >&2
  exit 1
fi
