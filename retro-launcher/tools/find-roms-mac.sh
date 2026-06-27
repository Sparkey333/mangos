#!/usr/bin/env bash
# RetroLauncher — Mac ROM finder
#
# Scans every common emulator library location on macOS and lists your
# GBA / GBC / PSX ROMs. Optionally copies them to a staging folder, or
# uploads directly to Google Drive via rclone.
#
# Emulators covered:
#   OpenEmu   ~/Library/Application Support/OpenEmu/Game Library/roms/
#   mGBA      ~/Documents/mGBA/ and ~/.config/mgba/ recent-file paths
#   RetroArch ~/Library/Application Support/RetroArch/downloads/
#   DuckStation ~/Documents/DuckStation/games/
#   Mednafen  ~/Library/Application Support/Mednafen/
#   Manual    ~/Documents/ROMs/  (drop ROMs here if none of the above apply)
#
# Usage:
#   ./tools/find-roms-mac.sh                       # just list
#   ./tools/find-roms-mac.sh copy ~/Desktop/ROMs   # copy to a local folder
#   ./tools/find-roms-mac.sh upload                # upload via rclone

set -euo pipefail

MODE="${1:-list}"
COPY_DEST="${2:-}"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive}"
DRIVE_ROOT="RetroLauncher"

# ── System extension map ──────────────────────────────────────────────────────
declare -A EXT_SYS
EXT_SYS[gba]=GBA; EXT_SYS[gbc]=GBC; EXT_SYS[gb]=GBC
EXT_SYS[bin]=PSX; EXT_SYS[cue]=PSX; EXT_SYS[img]=PSX
EXT_SYS[chd]=PSX; EXT_SYS[pbp]=PSX

# ── Locations to scan ────────────────────────────────────────────────────────
SCAN_DIRS=(
  "$HOME/Library/Application Support/OpenEmu/Game Library/roms/Game Boy Advance"
  "$HOME/Library/Application Support/OpenEmu/Game Library/roms/Game Boy Color"
  "$HOME/Library/Application Support/OpenEmu/Game Library/roms/Game Boy"
  "$HOME/Library/Application Support/OpenEmu/Game Library/roms/Sony PlayStation"
  "$HOME/Library/Application Support/RetroArch/downloads"
  "$HOME/Library/Application Support/Mednafen"
  "$HOME/Documents/DuckStation/games"
  "$HOME/Documents/mGBA"
  "$HOME/Documents/ROMs"
  "$HOME/Downloads"   # catch ROMs dropped straight into Downloads
)

# ── Gather files ─────────────────────────────────────────────────────────────
declare -a FILES
declare -a SYSTEMS

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " RetroLauncher · Mac ROM Scanner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

prev_dir=""
for dir in "${SCAN_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r f; do
    ext="${f##*.}"; ext="${ext,,}"
    sys="${EXT_SYS[$ext]:-}"; [[ -z "$sys" ]] && continue
    if [[ "$dir" != "$prev_dir" ]]; then
      prev_dir="$dir"
      echo "  📂 ${dir/#$HOME/\~}"
    fi
    mb=$(du -sh "$f" 2>/dev/null | awk '{print $1}')
    printf "     [%s]  %-42s  %s\n" "$sys" "$(basename "$f")" "$mb"
    FILES+=("$f")
    SYSTEMS+=("$sys")
  done < <(find "$dir" -maxdepth 4 -type f 2>/dev/null \
    | grep -iE '\.(gba|gbc|gb|bin|cue|img|chd|pbp)$' | sort)
done

total="${#FILES[@]}"
echo ""
echo "  Found $total ROM files."
echo ""

if [[ $total -eq 0 ]]; then
  echo "  No ROMs detected in standard locations."
  echo ""
  echo "  Tip: place ROMs in ~/Documents/ROMs/ like this:"
  echo "    ~/Documents/ROMs/GBA/pokemon_fire_red.gba"
  echo "    ~/Documents/ROMs/PSX/metal_gear_solid.bin"
  echo "  Then re-run this script."
  echo ""
  echo "  Or import via OpenEmu first (drag ROM into OpenEmu → File > Reveal in Finder)"
  exit 0
fi

# ── Act based on mode ────────────────────────────────────────────────────────
case "$MODE" in

  list)
    echo "  Next steps — choose one:"
    echo ""
    echo "  A) Copy to staging folder, then drag into Drive.app or drive.google.com:"
    echo "       ./tools/find-roms-mac.sh copy ~/Desktop/RetroLauncherROMs"
    echo ""
    echo "  B) Upload directly to Google Drive via rclone (fastest):"
    echo "       brew install rclone      # one-time"
    echo "       rclone config            # choose 'Google Drive' when prompted"
    echo "       ./tools/find-roms-mac.sh upload"
    echo ""
    echo "  C) Skip cloud entirely — drag ROMs straight into the launcher:"
    echo "       Open RetroLauncher → Settings → Import Local ROMs"
    ;;

  copy)
    if [[ -z "$COPY_DEST" ]]; then
      echo "Usage: $0 copy <destination-folder>"; exit 1
    fi
    echo "  Copying to $COPY_DEST ..."
    for i in "${!FILES[@]}"; do
      f="${FILES[$i]}"; sys="${SYSTEMS[$i]}"
      dest_dir="$COPY_DEST/$sys"
      mkdir -p "$dest_dir"
      cp -n "$f" "$dest_dir/" && echo "  ✓ $sys/$(basename "$f")" \
                              || echo "  — $sys/$(basename "$f") (already there)"
    done
    echo ""
    echo "  Done. Now:"
    echo "  • Drag $COPY_DEST into the Google Drive app  — OR —"
    echo "  • Upload at drive.google.com into a folder named 'RetroLauncher'"
    echo "  Then open RetroLauncher → Settings → Import Library."
    ;;

  upload)
    if ! command -v rclone &>/dev/null; then
      echo "  rclone is not installed."
      echo ""
      echo "  Install it:"
      echo "    brew install rclone"
      echo ""
      echo "  Configure Google Drive (one-time):"
      echo "    rclone config"
      echo "    → New remote → name: gdrive → Storage: Google Drive → follow prompts"
      echo ""
      echo "  Then re-run:  ./tools/find-roms-mac.sh upload"
      exit 1
    fi
    echo "  Uploading to $RCLONE_REMOTE:$DRIVE_ROOT/ ..."
    echo ""
    for i in "${!FILES[@]}"; do
      f="${FILES[$i]}"; sys="${SYSTEMS[$i]}"
      echo "  ↑ $sys/$(basename "$f")"
      rclone copy "$f" "${RCLONE_REMOTE}:${DRIVE_ROOT}/${sys}/" --progress 2>&1 | grep -v '^$' | tail -1 || true
    done
    echo ""
    echo "  Upload complete."
    echo "  Open RetroLauncher → Settings → Import Library."
    ;;

  *)
    echo "Usage: $0 [list|copy <dest>|upload]"; exit 1;;
esac
