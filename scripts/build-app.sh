#!/bin/zsh
# Builds Caffeinate in release mode and assembles build/Caffeinate.app.
# Usage: scripts/build-app.sh [--run]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f "$ROOT/Resources/AppIcon.icns" ]; then
  swift "$ROOT/scripts/make-icon.swift"
fi

swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$ROOT/build/Caffeinate.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/Caffeinate" "$APP/Contents/MacOS/Caffeinate"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
echo -n "APPL????" > "$APP/Contents/PkgInfo"

# Copy SwiftPM resource bundles (e.g. KeyboardShortcuts localizations).
for bundle in "$BIN_DIR"/*.bundle; do
  [ -d "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

if [ -f "$ROOT/Resources/AppIcon.icns" ]; then
  cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist" >/dev/null 2>&1 || true
fi

codesign --force --deep --sign - "$APP"

echo "Built $APP"

if [[ "${1:-}" == "--run" ]]; then
  pkill -x Caffeinate 2>/dev/null || true
  open "$APP"
fi
