#!/bin/bash

set -e

# --- Configuration ---
APP_NAME="Discord"
INSTALL_DIR="/opt/$APP_NAME"
EXECUTABLE_LINK="/usr/bin/discord"
DISCORD_URL="https://discord.com/api/download?platform=linux&format=tar.gz"
TEMP_DIR="/tmp/discord_install"

echo "Starting Discord update process..."

# --- 1. Check current installed version ---
INSTALLED_VERSION=""
if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/resources/build_info.json" ]; then
    INSTALLED_VERSION=$(grep -oP '"version":\s*"\K[^"]+' "$INSTALL_DIR/resources/build_info.json" 2>/dev/null || echo "")
    echo "Currently installed: Discord $INSTALLED_VERSION"
else
    echo "Discord is not currently installed."
fi

# --- 2. Download and check latest version ---
echo "Checking latest Discord version..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

if ! curl -fSL "$DISCORD_URL" -o "$TEMP_DIR/discord.tar.gz"; then
    echo "Error: Download failed"
    exit 1
fi

echo "Extracting to check version..."
tar -xzf "$TEMP_DIR/discord.tar.gz" -C "$TEMP_DIR"

EXTRACTED_DIR="$TEMP_DIR/$APP_NAME"
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "Error: Extraction failed - Discord directory not found"
    rm -rf "$TEMP_DIR"
    exit 1
fi

LATEST_VERSION=$(grep -oP '"version":\s*"\K[^"]+' "$EXTRACTED_DIR/resources/build_info.json" 2>/dev/null || echo "")
echo "Latest available: Discord $LATEST_VERSION"

# --- 3. Compare versions ---
if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ] && [ -n "$INSTALLED_VERSION" ]; then
    echo "Discord is already up to date (version $INSTALLED_VERSION). Skipping installation."
    rm -rf "$TEMP_DIR"
    exit 0
fi

echo "Version mismatch detected. Proceeding with installation..."

# --- 4. Terminate Discord if running ---
if pgrep -xi "discord" > /dev/null; then
    echo "Closing Discord..."
    killall -q discord || true
    sleep 2
    if pgrep -xi "discord" > /dev/null; then
        killall -9 discord 2>/dev/null || true
        sleep 1
    fi
    echo "Discord closed."
fi

# --- 5. Install ---
echo "Installing to $INSTALL_DIR..."
sudo rm -rf "$INSTALL_DIR"
sudo mv "$EXTRACTED_DIR" "$INSTALL_DIR"
sudo chown -R "$USER:$USER" "$INSTALL_DIR"

# --- 6. Create symlink ---
EXECUTABLE_BIN="$INSTALL_DIR/$APP_NAME"
if [ -x "$EXECUTABLE_BIN" ]; then
    sudo ln -sf "$EXECUTABLE_BIN" "$EXECUTABLE_LINK"
else
    echo "Error: Executable not found at $EXECUTABLE_BIN"
    exit 1
fi

# --- 7. Cleanup ---
rm -rf "$TEMP_DIR"

# --- 8. Clear Discord cache to prevent "Splash.updateCountdownSeconds: undefined" error ---
# Preserves Local Storage (login tokens) so you stay logged in
DISCORD_CONFIG="$HOME/.config/discord"
if [ -d "$DISCORD_CONFIG" ]; then
    echo "Clearing Discord cache (preserving login)..."

    # Remove module version directories (0.0.XXX) - common cause of splash errors
    find "$DISCORD_CONFIG" -maxdepth 1 -type d -name "0.0.*" -exec rm -rf {} + 2>/dev/null || true

    # Remove all cache directories
    rm -rf "$DISCORD_CONFIG/Cache" \
           "$DISCORD_CONFIG/Code Cache" \
           "$DISCORD_CONFIG/GPUCache" \
           "$DISCORD_CONFIG/DawnGraphiteCache" \
           "$DISCORD_CONFIG/DawnWebGPUCache" \
           "$DISCORD_CONFIG/VideoDecodeStats" \
           "$DISCORD_CONFIG/blob_storage" \
           "$DISCORD_CONFIG/shared_proto_db" \
           "$DISCORD_CONFIG/Session Storage" 2>/dev/null || true

    # Remove potentially corrupted settings/state files
    rm -f "$DISCORD_CONFIG/settings.json" \
          "$DISCORD_CONFIG/Preferences" \
          "$DISCORD_CONFIG/Local State" 2>/dev/null || true

    echo "Discord cache cleared."
fi

# --- 9. Launch Discord ---
# echo "Installation complete. Launching Discord..."
# sleep 1
# nohup "$EXECUTABLE_BIN" > /dev/null 2>&1 &
# disown

echo "Done."
