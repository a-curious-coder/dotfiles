#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
LOG_FILE="$ROOT_DIR/docs/tmux-plugin-index-log.md"
TODAY="$(date +%F)"

if [ ! -f "$LOG_FILE" ]; then
  echo "Log file not found: $LOG_FILE" >&2
  exit 1
fi

cat >>"$LOG_FILE" <<EOF

## Review $TODAY
- Added:
- Removed:
- Deferred:
- Rationale:
EOF

printf 'Appended review template to %s\n' "$LOG_FILE"
