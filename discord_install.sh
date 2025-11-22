#!/bin/bash

set -e

# --- Configuration ---
APP_NAME="Discord"
INSTALL_DIR="/opt/$APP_NAME"
EXECUTABLE_LINK="/usr/bin/discord"
DISCORD_URL="https://discord.com/api/download?platform=linux&format=tar.gz"
TEMP_DIR="/tmp/discord_install"

echo "Starting Discord update process..."

# --- 1. Terminate Discord if running ---
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

# --- 2. Download ---
echo "Downloading latest Discord..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

if ! curl -fSL "$DISCORD_URL" -o "$TEMP_DIR/discord.tar.gz"; then
    echo "Error: Download failed"
    exit 1
fi

# --- 3. Extract ---
echo "Extracting..."
tar -xzf "$TEMP_DIR/discord.tar.gz" -C "$TEMP_DIR"

EXTRACTED_DIR="$TEMP_DIR/$APP_NAME"
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "Error: Extraction failed - Discord directory not found"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# --- 4. Install ---
echo "Installing to $INSTALL_DIR..."
sudo rm -rf "$INSTALL_DIR"
sudo mv "$EXTRACTED_DIR" "$INSTALL_DIR"
sudo chown -R "$USER:$USER" "$INSTALL_DIR"

# --- 5. Create symlink ---
EXECUTABLE_BIN="$INSTALL_DIR/$APP_NAME"
if [ -x "$EXECUTABLE_BIN" ]; then
    sudo ln -sf "$EXECUTABLE_BIN" "$EXECUTABLE_LINK"
else
    echo "Error: Executable not found at $EXECUTABLE_BIN"
    exit 1
fi

# --- 6. Cleanup ---
rm -rf "$TEMP_DIR"

# --- 7. Launch Discord ---
echo "Installation complete. Launching Discord..."
sleep 1
nohup "$EXECUTABLE_BIN" > /dev/null 2>&1 &
disown

echo "Done."
