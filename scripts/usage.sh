#!/usr/bin/env bash
# Which stow packages does this machine actually use?
#
# Three free signals, no daemon and no state file:
#   runs  - invocations in ~/.zsh_history (timestamped by oh-my-zsh's EXTENDED_HISTORY)
#   proc  - the thing is running right now (the only signal that works for daemons)
#   cold  - neither of the above
#
# Deliberately does NOT use file access times: relatime leaves a running
# daemon's config reading as months-cold, so atime reports live packages dead.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

history_file="${HISTFILE:-$HOME/.zsh_history}"

# Packages whose command name differs from the directory name.
command_for() {
  case "$1" in
    calibre-linux) echo calibre ;;
    ripgrep) echo rg ;;
    hypr) echo Hyprland ;;
    transcription-stack) echo hyprwhspr ;;
    *) echo "$1" ;;
  esac
}

# Sourced by the shell rather than invoked, so zero runs is expected, not cold.
always_on() {
  case "$1" in
    zsh | starship | direnv | ghostty | claude) return 0 ;;
    *) return 1 ;;
  esac
}

# Launched from a keybind, never typed. Without this rofi, wlogout and tmux all
# report cold: nothing invokes them from a prompt and they hold no daemon.
keybound() {
  grep -rqilE "^[^#]*(bind|exec).*\b$1\b" \
    hypr/.config/hypr tmux/.tmux.conf 2>/dev/null
}

# One pass over history -> a "count command" table, sudo stripped. Kept as a
# plain string rather than an associative array so this still runs on macOS's
# bash 3.2, which is the machine most likely to need the report.
runs_table=""
if [ -r "$history_file" ]; then
  runs_table="$(
    sed -e 's/^: [0-9]*:[0-9]*;//' "$history_file" 2>/dev/null |
      awk '{ if ($1 == "sudo") print $2; else print $1 }' |
      sort | uniq -c
  )"
fi

runs_for() {
  printf '%s\n' "$runs_table" | awk -v want="$1" '$2 == want { print $1; exit }'
}

printf '%-22s %6s  %5s  %s\n' PACKAGE RUNS PROC VERDICT
for package in */; do
  package="${package%/}"
  # Same rule as check-stow-targets.sh: a package installs dot-prefixed paths.
  [[ -n "$(find "$package" -maxdepth 1 -name '.*' ! -name '.' ! -name '.gitignore' -print -quit)" ]] || continue

  command="$(command_for "$package")"
  count="$(runs_for "$command")"
  count="${count:-0}"

  if pgrep -x "$command" >/dev/null 2>&1 || pgrep -f "^$command" >/dev/null 2>&1; then
    proc=yes
  else
    proc=no
  fi

  if [[ "$proc" == yes ]]; then
    verdict=live
  elif always_on "$package"; then
    verdict='live (shell integration)'
  elif ((count >= 5)); then
    verdict=live
  elif keybound "$command"; then
    verdict='keybound - history cannot see it'
  elif ((count == 0)); then
    verdict='COLD - nothing invoked it'
  else
    verdict='barely used'
  fi

  printf '%-22s %6s  %5s  %s\n' "$package" "$count" "$proc" "$verdict"
done

printf '\nHistory: %s\n' "$history_file"
printf 'COLD means no invocation in that history and not running now. Check a\n'
printf 'second machine before deleting a package: usage is per-machine.\n'
