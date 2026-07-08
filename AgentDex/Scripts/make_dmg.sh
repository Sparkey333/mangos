#!/usr/bin/env bash
#
# Package AgentDex.app into a distributable AgentDex.dmg so you can install and
# test it exactly like an app you downloaded. Run ON A MAC.
#
#   ./Scripts/make_dmg.sh
#
# Output: build/AgentDex.dmg  (drag-to-Applications installer layout)
#
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="AgentDex"
BUILD_DIR="build"
APP="${BUILD_DIR}/${APP_NAME}.app"
DMG="${BUILD_DIR}/${APP_NAME}.dmg"
STAGING="${BUILD_DIR}/dmg-staging"

# 1) Ensure the app is built.
./Scripts/build_macos_app.sh

# 2) Stage the classic "drag to Applications" layout.
echo "==> staging DMG contents…"
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# 3) Build a compressed DMG.
echo "==> hdiutil create…"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$DMG"

rm -rf "$STAGING"

echo ""
echo "✅ Built ${DMG}"
echo "   Double-click it, drag ${APP_NAME} to Applications, then launch from Launchpad."
echo ""
echo "NOTE: This DMG is unsigned/un-notarized. On first launch macOS Gatekeeper"
echo "      will warn. Right-click the app → Open (once), or run:"
echo "        xattr -dr com.apple.quarantine \"/Applications/${APP_NAME}.app\""
echo "      For a warning-free install for others, see DISTRIBUTION.md (notarization)."
