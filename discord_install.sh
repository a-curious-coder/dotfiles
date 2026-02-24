#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Discord"
INSTALL_DIR="/opt/$APP_NAME"
EXECUTABLE_LINK="/usr/bin/discord"
DISCORD_URL="https://discord.com/api/download?platform=linux&format=tar.gz"
TEMP_DIR="/tmp/discord_install"
OWNER_USER="${USER:-$(id -un)}"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/discord_install.lock"

SUDO_CMD=()

log() {
    printf '[discord-install] %s\n' "$*"
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        local summary="$1"
        local body="${2:-}"
        if [ -n "$body" ]; then
            notify-send -a "Discord Updater" "$summary" "$body" || true
        else
            notify-send -a "Discord Updater" "$summary" || true
        fi
    fi
}

cleanup() {
    rm -rf "$TEMP_DIR"
}

on_error() {
    local rc=$?
    notify "Discord update failed" "Check ~/.local/state/local-voice-commands.log or run manually"
    log "failed (exit=$rc)"
    exit "$rc"
}

trap cleanup EXIT
trap on_error ERR

if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        log "Another discord_install.sh run is active; exiting."
        exit 0
    fi
fi

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log "Missing required command: $1"
        exit 1
    fi
}

read_version_from_build_info() {
    local build_info="$1"
    if [ ! -f "$build_info" ]; then
        echo ""
        return 0
    fi
    grep -oP '"version":\s*"\K[^"]+' "$build_info" 2>/dev/null || true
}

discord_running() {
    pgrep -i -x "discord" >/dev/null 2>&1
}

stop_discord() {
    log "Closing Discord..."
    pkill -i -x "discord" >/dev/null 2>&1 || true

    local waited=0
    while discord_running && [ "$waited" -lt 40 ]; do
        sleep 0.1
        waited=$((waited + 1))
    done

    if discord_running; then
        pkill -9 -i -x "discord" >/dev/null 2>&1 || true
        sleep 0.5
    fi

    if discord_running; then
        log "Could not fully stop Discord process"
        exit 1
    fi

    log "Discord closed."
}

start_discord() {
    local launch_bin="$EXECUTABLE_LINK"
    if [ ! -x "$launch_bin" ] && [ -x "$INSTALL_DIR/$APP_NAME" ]; then
        launch_bin="$INSTALL_DIR/$APP_NAME"
    fi

    if [ ! -x "$launch_bin" ]; then
        log "Discord executable not found after update: $launch_bin"
        return 1
    fi

    nohup "$launch_bin" >/dev/null 2>&1 &
    disown || true
    log "Discord relaunched."
    return 0
}

prepare_sudo() {
    if [ "$EUID" -eq 0 ]; then
        SUDO_CMD=()
        return 0
    fi

    if sudo -n true >/dev/null 2>&1; then
        SUDO_CMD=(sudo -n)
        return 0
    fi

    log "This updater needs passwordless sudo for /opt and /usr/bin changes."
    notify "Discord update blocked" "Passwordless sudo is required for voice-triggered updates"
    return 1
}

run_root() {
    if [ "${#SUDO_CMD[@]}" -gt 0 ]; then
        "${SUDO_CMD[@]}" "$@"
    else
        "$@"
    fi
}

clear_discord_cache() {
    local discord_config="$HOME/.config/discord"
    if [ ! -d "$discord_config" ]; then
        return 0
    fi

    log "Clearing Discord cache (preserving login)..."

    find "$discord_config" -maxdepth 1 -type d -name "0.0.*" -exec rm -rf {} + 2>/dev/null || true

    rm -rf "$discord_config/Cache" \
           "$discord_config/Code Cache" \
           "$discord_config/GPUCache" \
           "$discord_config/DawnGraphiteCache" \
           "$discord_config/DawnWebGPUCache" \
           "$discord_config/VideoDecodeStats" \
           "$discord_config/blob_storage" \
           "$discord_config/shared_proto_db" \
           "$discord_config/Session Storage" 2>/dev/null || true

    rm -f "$discord_config/settings.json" \
          "$discord_config/Preferences" \
          "$discord_config/Local State" 2>/dev/null || true

    log "Discord cache cleared."
}

main() {
    require_command curl
    require_command tar
    require_command grep

    log "Starting Discord update process..."
    notify "Discord updater" "Checking installed and latest versions"

    local installed_version=""
    local installed_build_info="$INSTALL_DIR/resources/build_info.json"

    if [ -d "$INSTALL_DIR" ] && [ -f "$installed_build_info" ]; then
        installed_version="$(read_version_from_build_info "$installed_build_info")"
        log "Currently installed: Discord ${installed_version:-unknown}"
    else
        log "Discord is not currently installed."
    fi

    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"

    log "Checking latest Discord version..."
    curl -fSL "$DISCORD_URL" -o "$TEMP_DIR/discord.tar.gz"

    tar -xzf "$TEMP_DIR/discord.tar.gz" -C "$TEMP_DIR"

    local extracted_dir="$TEMP_DIR/$APP_NAME"
    if [ ! -d "$extracted_dir" ]; then
        log "Extraction failed: Discord directory not found"
        exit 1
    fi

    local latest_build_info="$extracted_dir/resources/build_info.json"
    local latest_version
    latest_version="$(read_version_from_build_info "$latest_build_info")"

    if [ -z "$latest_version" ]; then
        log "Could not determine latest Discord version from archive"
        exit 1
    fi

    log "Latest available: Discord $latest_version"

    if [ -n "$installed_version" ] && [ "$installed_version" = "$latest_version" ]; then
        log "Discord is already up to date (version $installed_version)."
        notify "Discord up to date" "Version $installed_version"
        exit 0
    fi

    local was_running=0
    if discord_running; then
        was_running=1
        stop_discord
    fi

    notify "Discord updater" "Updating Discord to $latest_version"

    prepare_sudo

    log "Installing to $INSTALL_DIR..."
    run_root rm -rf "$INSTALL_DIR"
    run_root mv "$extracted_dir" "$INSTALL_DIR"
    run_root chown -R "$OWNER_USER:$OWNER_USER" "$INSTALL_DIR"

    local executable_bin="$INSTALL_DIR/$APP_NAME"
    if [ ! -x "$executable_bin" ]; then
        log "Executable not found at $executable_bin"
        exit 1
    fi

    run_root ln -sf "$executable_bin" "$EXECUTABLE_LINK"

    clear_discord_cache

    if [ "$was_running" -eq 1 ]; then
        start_discord
    else
        log "Discord was not running before update; not relaunching."
    fi

    notify "Discord updated" "${installed_version:-none} -> $latest_version"
    log "Done."
}

main "$@"
