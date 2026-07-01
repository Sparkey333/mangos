#!/usr/bin/env bash
# AetherForge — one-shot local setup for macOS.
# Gets the studio hub running on the web AND prepares the desktop .dmg build.
set -euo pipefail

say() { printf "\n\033[36m==> %s\033[0m\n" "$1"; }

say "Checking prerequisites (Homebrew, Node, Rust)…"
command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh"; exit 1; }
command -v node >/dev/null || brew install node
command -v cargo >/dev/null || { echo "Installing Rust…"; curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; source "$HOME/.cargo/env"; }

say "Installing JS dependencies…"
npm install

say "Building the web app (deployable to any host / mobile browser)…"
npm run build
echo "Web build is in ./dist — host it anywhere (Vercel, Netlify, GitHub Pages)."

say "Generating app icons (needed for the .dmg)…"
if [ ! -f app-icon.png ]; then
  if command -v rsvg-convert >/dev/null; then
    rsvg-convert -w 1024 -h 1024 app-icon.svg -o app-icon.png
  else
    echo "No app-icon.png and no rsvg-convert. Export app-icon.svg to a 1024x1024 app-icon.png,"
    echo "then run:  npm run icons   (skipping icon generation for now)"
  fi
fi
[ -f app-icon.png ] && npm run icons || true

cat <<'NEXT'

Setup done. Next:
  • Run the hub on the web:        npm run dev      (http://localhost:1420)
  • Run it as a desktop app:       npm run desktop:dev
  • Build the macOS .dmg:          npm run desktop:build
       -> dmg lands in src-tauri/target/release/bundle/dmg/
  • (Optional) mobile shells:      npm run ios:dev   /   npm run android:dev
NEXT
