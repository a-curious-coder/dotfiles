#!/bin/bash

# --- Configuration ---
APP_NAME="Discord"
INSTALL_DIR="/opt/$APP_NAME"
EXECUTABLE_LINK="/usr/bin/discord"
DISCORD_URL="https://discord.com/api/download?platform=linux&format=tar.gz"
TEMP_DIR="/tmp/discord_install"

echo "Starting Discord update process (always installs latest version)..."

# --- 1. Terminate Discord if running ---
echo "Checking for running Discord instances to terminate..."
if pgrep -x "$APP_NAME" > /dev/null; then
    echo "Discord is running. Attempting to close gracefully..."
    killall "$APP_NAME"
    sleep 3
    if pgrep -x "$APP_NAME" > /dev/null; then
        echo "Discord did not close gracefully. Forcing shutdown..."
        killall -9 "$APP_NAME"
        sleep 1
    fi
fi
echo "Discord process terminated."

# --- 2. Download and Extract Latest Version ---
echo "Preparing temporary directory..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

echo "Downloading latest Discord archive..."
curl -L "$DISCORD_URL" -o "$TEMP_DIR/discord.tar.gz"

echo "Extracting archive..."
tar -xzf "$TEMP_DIR/discord.tar.gz" -C "$TEMP_DIR"

# --- 3. Install Files and Set Permissions ---
echo "Installing new version to $INSTALL_DIR..."
# Remove the existing installation directory
sudo rm -rf "$INSTALL_DIR"

# Find the top-level directory in the extracted files (usually named 'Discord')
EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "$APP_NAME" -print -quit)

if [ -z "$EXTRACTED_DIR" ]; then
    echo "❌ Critical Error: Could not find the top-level 'Discord' directory in the tarball."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Move the new files into the installation directory
sudo mv "$EXTRACTED_DIR" "$INSTALL_DIR"
# Set ownership back to the current user for normal operation
sudo chown -R $USER:$USER "$INSTALL_DIR"

# --- 4. Fix Command-Line Execution ---
# The actual executable is always the file named 'Discord' inside the main directory.
EXECUTABLE_BIN="$INSTALL_DIR/$APP_NAME"

if [ -f "$EXECUTABLE_BIN" ]; then
    echo "Creating/refreshing system link: $EXECUTABLE_LINK -> $EXECUTABLE_BIN"
    # Create a symbolic link from a PATH directory (/usr/bin) to the application executable
    sudo ln -sf "$EXECUTABLE_BIN" "$EXECUTABLE_LINK"
else
    echo "❌ CRITICAL: Could not find the main executable at $EXECUTABLE_BIN. Command execution may fail."
fi

# --- 5. Cleanup ---
rm -rf "$TEMP_DIR"

echo "🎉 Discord installation complete. Run 'discord' to launch the new version."
