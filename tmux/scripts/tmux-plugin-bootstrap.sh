#!/usr/bin/env sh
set -eu

AUTO=0
QUIET=0
INTERVAL_SECONDS="${TMUX_PLUGIN_BOOTSTRAP_INTERVAL_SECONDS:-86400}"

while [ $# -gt 0 ]; do
  case "$1" in
    --auto)
      AUTO=1
      ;;
    --quiet)
      QUIET=1
      ;;
    --interval-seconds)
      shift
      INTERVAL_SECONDS="${1:-$INTERVAL_SECONDS}"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: tmux-plugin-bootstrap.sh [--auto] [--quiet] [--interval-seconds N]

Ensures TPM exists and installs missing plugins declared in ~/.tmux.conf.
--auto uses a timestamp gate (default 24h) to avoid running too often.
EOF
      exit 0
      ;;
  esac
  shift
done

log() {
  if [ "$QUIET" -ne 1 ]; then
    printf '%s\n' "$*"
  fi
}

TPM_DIR="$HOME/.tmux/plugins/tpm"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
STAMP_FILE="$CACHE_DIR/plugin-bootstrap.stamp"
LOCK_DIR="${TMPDIR:-/tmp}/tmux-plugin-bootstrap.lock"

mkdir -p "$CACHE_DIR"

if [ "$AUTO" -eq 1 ] && [ -f "$STAMP_FILE" ]; then
  now="$(date +%s)"
  last_run="$(stat -f %m "$STAMP_FILE" 2>/dev/null || stat -c %Y "$STAMP_FILE" 2>/dev/null || echo 0)"
  if [ $((now - last_run)) -lt "$INTERVAL_SECONDS" ]; then
    exit 0
  fi
fi

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  # Another bootstrap is already in progress.
  exit 0
fi
trap 'rmdir "$LOCK_DIR" >/dev/null 2>&1 || true' EXIT

if [ ! -d "$TPM_DIR" ]; then
  if ! command -v git >/dev/null 2>&1; then
    log "tmux-plugin-bootstrap: git not found; cannot install TPM."
    exit 0
  fi
  log "tmux-plugin-bootstrap: installing TPM..."
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR" >/dev/null 2>&1 || true
fi

if [ -x "$TPM_DIR/bin/install_plugins" ]; then
  log "tmux-plugin-bootstrap: installing missing plugins..."
  "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1 || true
fi

touch "$STAMP_FILE"
