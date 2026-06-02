#!/usr/bin/env bash
# Stop, remove from login, and delete the app.
set -euo pipefail

launchctl bootout "gui/$(id -u)/ai.botawake.app" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/ai.botawake.app.plist"
pkill -f "BotAwake.app/Contents/MacOS/BotAwake" 2>/dev/null || true
rm -rf "$HOME/Applications/BotAwake.app"

echo "Uninstalled. (Your system sleep settings were never changed, so nothing else to undo.)"
