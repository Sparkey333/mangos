# Research & Sourced Links

Everything below is verified against current (2026) sources. Use legally-obtained
ROMs and BIOS dumps from hardware you own.

## iOS emulation landscape (2024–2026)

Apple changed its App Store policy in 2024 to permit retro console emulators.
That's why this is now smooth and dependable — no jailbreak, no 7-day sideload
expiry.

- **Delta** — all-in-one (GBA/GBC/NES/SNES/N64/DS), free, App Store, custom skins,
  Google Drive + Dropbox save sync.
  <https://apps.apple.com/us/app/delta-game-emulator/id1048524688> ·
  source: <https://github.com/rileytestut/Delta>
- **RetroArch** — most powerful, every core incl. PSX, App Store.
  <https://apps.apple.com/us/app/retroarch/id1531768469>
- **Gamma** — dedicated PS1 emulator that landed on the App Store after Delta.
- **Provenance** — broad multi-system incl. PlayStation.
- Overview: <https://readonlymemo.com/ios-emulation-launches-delta-retroarch-iphone-emulator-list/>

> Note on landscape: Delta auto-rotates for GBA but has historically *disabled*
> manual autorotation lock for some systems. Our launcher handles orientation
> itself (`src/utils/rotation.js`) so the sideways experience is deterministic.

## Emulator cores (the WASM path)

- **EmulatorJS** (RetroArch cores compiled to WASM, MIT) — <https://emulatorjs.org>,
  docs <https://emulatorjs.org/docs/>
  - GBA → **mGBA** (high accuracy, built-in HLE BIOS, no external BIOS needed)
  - GB/GBC → **Gambatte**
  - PSX → **PCSX-ReARMED** (fast on mobile) — <https://docs.libretro.com/library/pcsx_rearmed/>

## PSX BIOS — what's really required

- PCSX-ReARMED accepts any retail PS1 BIOS; **`SCPH5501.BIN` (US v3.0)** is the
  safest single choice. <https://docs.libretro.com/library/pcsx_rearmed/>
- Recalbox BIOS reference: <https://wiki.recalbox.com/en/emulators/consoles/playstation-1/pcsx-rearmed>
- Batocera PSX system notes: <https://wiki.batocera.org/systems:psx>
- Keep the RetroArch core's BIOS filename exact (`SCPH5501.BIN`) — it can be
  filename-sensitive.

## Device skins (the GBA shell + feel)

- **Delta skins** community + generator: <https://delta-skins.github.io> ·
  <https://deltaskins.dev>
- Skin format reference (`.deltaskin` = zip of PDF/PNG art + `info.json` button map):
  <https://noah978.gitbook.io/delta-skins>
- This repo ships two starter skins in `deltaskins/` (classic purple + SP blue)
  plus a fully interactive in-app skin (`src/components/GBASkin/`) with
  **edge-slip haptics** — a subtle buzz as a finger skids toward a button edge and
  a sharp pop when it fully slides off (your requested "feel beneath the original
  device architecture").

## Box art & metadata (the Netflix/Plex info pull)

- **libretro-thumbnails** (free, keyless) — Named_Boxarts / Named_Titles /
  Named_Snaps PNGs by exact game name:
  <https://github.com/libretro-thumbnails> served via <https://thumbnails.libretro.com>
- **IGDB** (optional, free with a Twitch dev app) for synopsis/year/genre/rating:
  <https://api-docs.igdb.com>

## Haptics on iOS

- Web `navigator.vibrate` is limited in Safari; full **CoreHaptics** (sharpness +
  intensity transients, the real "click/slip/pop") requires a thin native WKWebView
  bridge. Our `HapticEngine` posts CoreHaptics params to `window.__hapticBridge`
  when present and falls back to vibration patterns otherwise.
  CoreHaptics docs: <https://developer.apple.com/documentation/corehaptics>

## ROM sources

Use ROMs dumped from your own cartridges/discs (a flashcart + dumper for carts; a
disc ripper for PSX). This keeps the whole pipeline legal and dependable, which is
the entire point of building it on *your* Drive.

---

### Sources
- <https://apps.apple.com/us/app/delta-game-emulator/id1048524688>
- <https://github.com/rileytestut/Delta>
- <https://readonlymemo.com/ios-emulation-launches-delta-retroarch-iphone-emulator-list/>
- <https://docs.libretro.com/library/pcsx_rearmed/>
- <https://wiki.recalbox.com/en/emulators/consoles/playstation-1/pcsx-rearmed>
- <https://wiki.batocera.org/systems:psx>
- <https://emulatorjs.org>
- <https://github.com/libretro-thumbnails>
- <https://api-docs.igdb.com>
- <https://developer.apple.com/documentation/corehaptics>
