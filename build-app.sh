#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Battery Alert"
BUNDLE="$APP_NAME.app"
EXEC_NAME="BatteryAlert"

echo "==> Building (release)…"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)"

echo "==> Assembling $BUNDLE…"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

cp "$BIN_PATH/$EXEC_NAME" "$BUNDLE/Contents/MacOS/$EXEC_NAME"
cp Info.plist "$BUNDLE/Contents/Info.plist"

if [ -f AppIcon.icns ]; then
  cp AppIcon.icns "$BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "==> Ad-hoc codesigning…"
codesign --force --deep --sign - "$BUNDLE"

echo "==> Done: $(pwd)/$BUNDLE"
echo "    Launch with:  open \"$BUNDLE\""
echo "    First launch may need: right-click → Open (Gatekeeper, ad-hoc signed)."
