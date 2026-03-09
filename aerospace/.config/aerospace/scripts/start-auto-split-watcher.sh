#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
LOCK_DIR="$STATE_DIR/auto-split-watcher-lock"
WATCHER_SCRIPT="${AEROSPACE_WATCHER_SCRIPT:-$HOME/.config/aerospace/scripts/auto-split-watcher.sh}"

mkdir -p "$STATE_DIR"

lock_pid=""
if [ -f "$LOCK_DIR/pid" ]; then
  lock_pid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
fi

if [[ "$lock_pid" =~ ^[0-9]+$ ]] && kill -0 "$lock_pid" 2>/dev/null; then
  exit 0
fi

rm -rf "$LOCK_DIR" >/dev/null 2>&1 || true

if [ ! -x "$WATCHER_SCRIPT" ]; then
  exit 0
fi

perl -e '
  use POSIX qw(setsid);
  my $script = shift @ARGV;
  my $pid = fork();
  exit 0 unless defined $pid;
  exit 0 if $pid;
  setsid() or exit 1;
  $pid = fork();
  exit 0 unless defined $pid;
  exit 0 if $pid;
  chdir "/";
  open STDIN,  "</dev/null" or exit 1;
  open STDOUT, ">/dev/null" or exit 1;
  open STDERR, ">/dev/null" or exit 1;
  exec $script or exit 1;
' "$WATCHER_SCRIPT"
