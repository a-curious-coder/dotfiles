#!/usr/bin/env bash
set -euo pipefail

AERO_CONFIG="${AEROSPACE_CONFIG_PATH:-$HOME/.config/aerospace/aerospace.toml}"

extract_bindings() {
  awk '
    /^\[mode\.main\.binding\]/ { mode = "main"; next }
    /^\[mode\.service\.binding\]/ { mode = "service"; next }
    /^\[/ { mode = ""; next }

    mode != "" {
      line = $0
      sub(/^[ \t]+/, "", line)
      if (line == "" || line ~ /^#/) next
      if (line !~ /=/) next

      key = line
      sub(/[ \t]*=.*/, "", key)
      sub(/^[ \t]+/, "", key)
      sub(/[ \t]+$/, "", key)

      cmd = line
      sub(/^[^=]*=[ \t]*/, "", cmd)

      printf "%s\t%s\t%s\n", mode, key, cmd
    }
  ' "$AERO_CONFIG"
}

launch_in_terminal() {
  open "hammerspoon://aerospace-keybindings" >/dev/null 2>&1 || true
}

copy_selection() {
  local line
  line="$1"

  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s\n' "$line" | pbcopy
    osascript -e 'display notification "Copied selected keybinding" with title "AeroSpace"' >/dev/null 2>&1 || true
  fi
}

interactive_list() {
  local rows selection
  rows="$(extract_bindings | sort -u)"
  [ -n "$rows" ] || exit 0

  if command -v fzf >/dev/null 2>&1 && [ -t 1 ]; then
    selection="$(printf '%s\n' "$rows" | \
      fzf --prompt='Aero keybinds > ' \
          --delimiter=$'\t' \
          --with-nth=2,1,3 \
          --layout=reverse \
          --height=85% \
          --header='Enter: copy selected row to clipboard  |  Esc: close' \
          --preview='echo {} | awk -F"\t" '\''{printf("mode: %s\nkey:  %s\ncmd:  %s\n",$1,$2,$3)}'\''')"

    [ -n "$selection" ] || exit 0
    copy_selection "$selection"
    printf '%s\n' "$selection" | awk -F'\t' '{printf "[%s] %s -> %s\n", $1, $2, $3}'
    exit 0
  fi

  # Fallback when fzf is unavailable.
  if [ -t 1 ]; then
    printf '%s\n' "$rows" | column -t -s $'\t' | less -R
  else
    printf '%s\n' "$rows" | column -t -s $'\t'
  fi
}

mode="${1:-}"

if [ ! -f "$AERO_CONFIG" ]; then
  exit 0
fi

if [ "$mode" = "--interactive" ]; then
  interactive_list
  exit 0
fi

if [ "$mode" = "--print" ]; then
  extract_bindings | sort -u
  exit 0
fi

if [ -t 1 ]; then
  interactive_list
else
  launch_in_terminal
fi
