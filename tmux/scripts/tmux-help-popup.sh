#!/usr/bin/env sh
set -eu

DUMP=0
TMUX_SOCKET="${TMUX_SOCKET:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --dump)
      DUMP=1
      ;;
    --help|-h)
      cat <<'EOF'
Usage: tmux-help-popup.sh [--dump]

Interactive tmux keybinding navigator.
--dump prints the parsed key table data without launching fzf.
EOF
      exit 0
      ;;
  esac
  shift
done

tmux_cmd() {
  if [ -n "$TMUX_SOCKET" ]; then
    tmux -L "$TMUX_SOCKET" "$@"
  else
    tmux "$@"
  fi
}

generate_rows() {
  tmux_cmd list-keys | awk '
    {
      line = $0
      table = "root"
      if (match(line, /-T[[:space:]]+[^[:space:]]+/)) {
        table = substr(line, RSTART + 3, RLENGTH - 3)
      }

      key = "?"
      n = split(line, parts, " ")
      for (i = 2; i <= n; i++) {
        token = parts[i]
        if (token == "-T" || token == "-N") {
          i++
          continue
        }
        if (substr(token, 1, 1) == "-") {
          continue
        }
        key = token
        break
      }

      printf "%s\t%s\t%s\n", table, key, line
    }
  '
}

if [ "$DUMP" -eq 1 ]; then
  generate_rows
  exit 0
fi

if ! command -v fzf >/dev/null 2>&1; then
  generate_rows | awk -F '\t' '{printf "%-20s %-16s %s\n", $1, $2, $3}' | "${PAGER:-less}"
  exit 0
fi

selection="$(
  generate_rows | fzf \
    --delimiter='\t' \
    --with-nth=1,2 \
    --layout=reverse \
    --height=100% \
    --border \
    --preview='printf "%s\n" {3}' \
    --preview-window='right,65%,wrap' \
    --header='tmux key navigator: type to filter, Enter copies selected command'
)"

[ -n "$selection" ] || exit 0

table="$(printf '%s' "$selection" | cut -f1)"
key="$(printf '%s' "$selection" | cut -f2)"
command_line="$(printf '%s' "$selection" | cut -f3-)"

tmux_cmd set-buffer -- "$command_line"
tmux_cmd display-message "Copied binding command from ${table}:${key}"
