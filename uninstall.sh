#!/usr/bin/env bash
# Stop, remove from login, and delete the app.
set -euo pipefail

launchctl bootout "gui/$(id -u)/ai.botawake.app" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/ai.botawake.app.plist"
pkill -f "BotAwake.app/Contents/MacOS/BotAwake" 2>/dev/null || true
rm -rf "$HOME/Applications/BotAwake.app"

SUDOERS_FILE="/etc/sudoers.d/botawake"
if [ -f "$SUDOERS_FILE" ]; then
    sudo rm -f "$SUDOERS_FILE" && echo "Removed ${SUDOERS_FILE}."
fi

echo "Uninstalled. (Sudoers whitelist removed.)"
