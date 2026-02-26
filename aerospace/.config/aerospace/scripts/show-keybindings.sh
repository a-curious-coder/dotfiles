#!/usr/bin/env bash
set -euo pipefail

find_doc_file() {
  local script_path script_dir candidate

  script_path="$0"
  if [ -L "$script_path" ]; then
    local target
    target="$(readlink "$script_path")"
    case "$target" in
      /*) script_path="$target" ;;
      *) script_path="$(cd "$(dirname "$script_path")" && cd "$(dirname "$target")" && pwd)/$(basename "$target")" ;;
    esac
  fi

  script_dir="$(cd "$(dirname "$script_path")" && pwd)"

  candidate="$script_dir/../../../../docs/aerospace-hypr-functionality.md"
  [ -f "$candidate" ] && { printf '%s\n' "$candidate"; return 0; }

  candidate="$HOME/.dotfiles/docs/aerospace-hypr-functionality.md"
  [ -f "$candidate" ] && { printf '%s\n' "$candidate"; return 0; }

  candidate="$HOME/Projects/personal/dotfiles/docs/aerospace-hypr-functionality.md"
  [ -f "$candidate" ] && { printf '%s\n' "$candidate"; return 0; }

  return 1
}

doc_file="$(find_doc_file || true)"

if [ -n "$doc_file" ]; then
  open "$doc_file" >/dev/null 2>&1 || true
  exit 0
fi

# Fallback: launch searchable list when docs are not available.
"${HOME}/.config/aerospace/scripts/list-keybindings.sh" >/dev/null 2>&1 || true
