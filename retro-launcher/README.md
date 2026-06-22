# RetroLauncher 🎮

A **Netflix/Plex-style** front-end for your own retro library — GBA & PSX games
streamed from your **own Google Drive**, running on a **sideways iPhone** with a
real **GBA device skin** and **button-feel haptics**. Built as an installable PWA
(Add to Home Screen) so it feels like a real app, not a raw emulator glitch-fest.

> Built on the `claude/gba-emulator-iphone-drive-a7kd8d` branch. This lives
> alongside the MaNGOS project as a self-contained sub-app in `retro-launcher/`.

## What's in the box

| Feature | Where |
|---------|-------|
| Netflix-style home (hero + shelves + Continue Playing) | `src/pages/Home.jsx` |
| Plex-style detail page (cover, synopsis, year, genre, rating) | `src/pages/GameDetail.jsx` |
| Interactive **GBA skin** with edge-slip + edge-pop haptics | `src/components/GBASkin/` |
| Haptic engine (CoreHaptics bridge + vibration fallback) | `src/components/HapticEngine/` |
| Google Drive library (list / download / save-sync) | `src/services/googleDrive.js` |
| Box art + metadata (libretro + optional IGDB) | `src/services/metadata.js` |
| Emulator core bridge (EmulatorJS WASM + Delta deep-link) | `src/services/emulatorCore.js` |
| BIOS / ROM hash verification (trust layer) | `src/utils/trust.js` |
| Auto-landscape rotation handling | `src/utils/rotation.js` |
| "1 chosen + 2 runners-up" prefetch policy | `src/services/prefetch.js` |
| First-party-only promo banner (never interrupts) | `src/components/MediaPlayer/` |
| Admin/experimental bench + feature flags | `src/pages/Admin.jsx`, `src/components/AdminPanel/` |
| Delta `.deltaskin` starter skins (native hand-off path) | `deltaskins/` |

## Design principles

- **Trust, smoothly.** Files live in *your* Drive. OAuth2 login. No third-party ad
  SDKs, no trackers. BIOS is hash-verified before boot.
- **No ads, ever — except your own.** A single thin, dismissible, bottom banner that
  serves only first-party promos / own bumpers (Toonami-style) and **never pauses
  gameplay**. Toggleable.
- **Real-device feel.** Sideways auto-landscape, GBA shell, and haptics that buzz as
  your finger skids toward a button edge and pop when it slides off — the tactile
  difference between a real app and a raw web emu.
- **Off-by-default experiments.** New ideas (extra haptic modes, skins) ship behind
  Admin feature flags.

## Quick start

```bash
cd retro-launcher
npm install
npm run dev
```

Open the printed URL on your iPhone (same Wi-Fi), then **Share → Add to Home
Screen**. See [`docs/SETUP.md`](docs/SETUP.md) for Drive connection, BIOS, and the
folder layout, and [`docs/RESEARCH.md`](docs/RESEARCH.md) for sourced links to
emulators, cores, skins, and art databases.

## Targets prepped

- **Pokémon Fire Red** (GBA) — no BIOS needed, primary one-tap target.
- **Metal Gear Solid** + **Small Soldiers** (PSX) — default BIOS `SCPH5501.BIN`
  (US v3.0), hash-verified; MGS multi-disc swap noted in the detail page.

> Use ROMs/BIOS dumped from hardware you own.
