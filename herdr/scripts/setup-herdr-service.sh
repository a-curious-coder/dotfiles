#!/usr/bin/env bash
# Installs and enables the herdr server as a background service, so
# sessions/workspaces survive a reboot instead of dying with the terminal
# that launched them. Run this yourself: Linux uses sudo for enable-linger.
set -euo pipefail

if [[ "$(uname -s)" == "Darwin" ]]; then
  # macOS: homebrew's herdr formula already ships a launchd job
  # (RunAtLoad + KeepAlive) — `brew services` is the whole setup.
  brew services start herdr
  # launchd starts the server with PATH=/usr/bin:/bin:/usr/sbin:/sbin, so
  # plugin binaries (clauth in ~/.cargo/bin, ...) fail to spawn. brew
  # regenerates the plist on start/upgrade, so re-run this script after
  # `brew upgrade herdr`. Takes effect on the next server restart:
  #   launchctl bootout gui/$(id -u)/homebrew.mxcl.herdr
  #   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/homebrew.mxcl.herdr.plist
  plist="$HOME/Library/LaunchAgents/homebrew.mxcl.herdr.plist"
  path_value="$HOME/.cargo/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  /usr/libexec/PlistBuddy -c "Delete :EnvironmentVariables" "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables dict" \
    -c "Add :EnvironmentVariables:PATH string $path_value" "$plist"
  echo "herdr started via brew services and enabled at login."
  brew services info herdr
  exit 0
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_SRC="$REPO_DIR/systemd/herdr.service"
UNIT_DST_DIR="$HOME/.config/systemd/user"

mkdir -p "$UNIT_DST_DIR"
cp "$UNIT_SRC" "$UNIT_DST_DIR/herdr.service"

systemctl --user daemon-reload
systemctl --user enable --now herdr.service

# Lets the service start at boot even before you log in graphically.
sudo loginctl enable-linger "$USER"

echo "herdr.service installed and enabled."
systemctl --user status herdr.service --no-pager
