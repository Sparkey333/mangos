#!/usr/bin/env bash
#
# Build a double-clickable AgentDex.app (macOS) straight from Swift Package
# Manager — no Xcode project required. Run this ON A MAC with the Xcode command
# line tools installed (`xcode-select --install`).
#
#   ./Scripts/build_macos_app.sh
#
# Output: build/AgentDex.app
#
set -euo pipefail

cd "$(dirname "$0")/.."   # repo/AgentDex

APP_NAME="AgentDex"
EXECUTABLE_TARGET="AgentDexApp"
CONFIG="release"
BUILD_DIR="build"
APP="${BUILD_DIR}/${APP_NAME}.app"
BUNDLE_ID="com.agentdex.app"

echo "==> swift build ($CONFIG)…"
swift build -c "$CONFIG" --product "$EXECUTABLE_TARGET"

BIN_PATH="$(swift build -c "$CONFIG" --product "$EXECUTABLE_TARGET" --show-bin-path)"
echo "==> bin path: $BIN_PATH"

echo "==> assembling ${APP}…"
rm -rf "$APP"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"

# 1) Executable
cp "${BIN_PATH}/${EXECUTABLE_TARGET}" "${APP}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP}/Contents/MacOS/${APP_NAME}"

# 2) SwiftPM resource bundles (Bundle.module) — copy any *.bundle next to the app
#    into Contents/Resources so ConfigLoader can find the example JSON.
shopt -s nullglob
for b in "${BIN_PATH}"/*.bundle; do
  echo "    + resource bundle: $(basename "$b")"
  cp -R "$b" "${APP}/Contents/Resources/"
done
shopt -u nullglob

# 2.5) App icon (generated procedurally; skipped gracefully if tools missing).
if command -v iconutil >/dev/null 2>&1; then
  echo "==> generating app icon…"
  if swift Scripts/generate_appicon.swift "${BUILD_DIR}/icon-gen" \
     && iconutil -c icns "${BUILD_DIR}/icon-gen/AgentDex.iconset" -o "${APP}/Contents/Resources/AppIcon.icns"; then
    echo "    icon embedded"
  else
    echo "    (icon generation failed; continuing without icon)"
  fi
fi

# 3) Info.plist — makes it a real GUI app (menu bar, dock icon, activation).
cat > "${APP}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>     <string>${APP_NAME}</string>
  <key>CFBundleExecutable</key>      <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>      <string>${BUNDLE_ID}</string>
  <key>CFBundleIconFile</key>       <string>AppIcon</string>
  <key>CFBundleVersion</key>         <string>1</string>
  <key>CFBundleShortVersionString</key><string>0.3.0</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>LSMinimumSystemVersion</key>  <string>13.0</string>
  <key>NSHighResolutionCapable</key> <true/>
  <key>NSPrincipalClass</key>        <string>NSApplication</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.games</string>
</dict>
</plist>
PLIST

# 4) Ad-hoc code signature so Gatekeeper lets it run locally.
if command -v codesign >/dev/null 2>&1; then
  echo "==> ad-hoc codesign…"
  codesign --force --deep --sign - "$APP" || echo "   (codesign failed; app still runs locally)"
fi

echo ""
echo "✅ Built ${APP}"
echo "   Open it with:   open \"${APP}\""
echo "   Or run raw:     swift run ${EXECUTABLE_TARGET}"
