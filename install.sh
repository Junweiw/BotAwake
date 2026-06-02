#!/usr/bin/env bash
# Build, install to ~/Applications, and start at login.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="BotAwake"
DEST="$HOME/Applications/${APP_NAME}.app"
PLIST="$HOME/Library/LaunchAgents/ai.botawake.app.plist"
BIN="$DEST/Contents/MacOS/${APP_NAME}"

./build.sh

mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "dist/${APP_NAME}.app" "$DEST"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.botawake.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>${BIN}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

# Reload the login agent.
launchctl bootout "gui/$(id -u)/ai.botawake.app" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "Installed to ${DEST} and started. Look for the cup icon in the menu bar."
