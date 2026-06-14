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

# Install sudoers whitelist for lid-closed mode (pmset disablesleep).
SUDOERS_FILE="/etc/sudoers.d/botawake"
if [ ! -f "$SUDOERS_FILE" ]; then
    sudo sh -c "echo '# BotAwake: allow NOPASSWD pmset disablesleep for lid-closed mode' > '$SUDOERS_FILE'"
    sudo sh -c "echo 'Cmnd_Alias BOTAWAKE = /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0' >> '$SUDOERS_FILE'"
    sudo sh -c "echo 'ALL ALL=(ALL) NOPASSWD: BOTAWAKE' >> '$SUDOERS_FILE'"
    sudo chmod 0440 "$SUDOERS_FILE"
    echo "Created ${SUDOERS_FILE} for lid-closed mode."
else
    echo "${SUDOERS_FILE} already exists, skipping."
fi

echo "Installed to ${DEST} and started. Look for the cup icon in the menu bar."
echo "Lid-closed mode: \"Stay awake with lid closed\" in the menu."
