#!/usr/bin/env bash
# Build BotAwake.app into ./dist — no dependencies beyond Xcode command-line tools.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="BotAwake"
DIST="dist/${APP_NAME}.app"

command -v swiftc >/dev/null || { echo "error: swiftc not found. Run: xcode-select --install"; exit 1; }

rm -rf "$DIST"
mkdir -p "$DIST/Contents/MacOS" "$DIST/Contents/Resources"
cp Resources/Info.plist "$DIST/Contents/Info.plist"
cp Resources/AppIcon.icns "$DIST/Contents/Resources/AppIcon.icns"
swiftc -O Sources/main.swift -o "$DIST/Contents/MacOS/${APP_NAME}"

echo "Built ${DIST}"
