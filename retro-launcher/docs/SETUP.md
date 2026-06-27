# RetroLauncher — Setup Guide

A Netflix/Plex-style front-end for your own GBA & PSX library, streamed from your
own Google Drive, running on a sideways iPhone with a real GBA device skin and
button-feel haptics. **No ads except your own** first-party promos.

> **Trust first.** This launcher never uploads your files to anyone. Your library
> lives in *your* Google Drive. Auth is OAuth2 (Google's own login). The only
> network calls are: Google Drive (your files), the libretro art database (public
> box art), and optionally IGDB (synopsis). No trackers, no third-party ad SDKs.

---

## 1. The realistic stack (what runs what)

This repo is the **launcher / front-end**. It does not re-implement emulation — it
hands ROM bytes to a proven emulator core. Two delivery modes:

| Mode | Core | Where it runs | Best for |
|------|------|---------------|----------|
| **In-app (default)** | [EmulatorJS](https://emulatorjs.org) WASM (mGBA, Gambatte, PCSX-ReARMED) | Inside this PWA, no app switch | Seamless one-tap play, custom skin + haptics |
| **Hand-off (native iOS)** | [Delta](https://apps.apple.com/us/app/delta-game-emulator/id1048524688) / [RetroArch](https://apps.apple.com/us/app/retroarch/id1531768469) | Deep-link out via URL scheme | Max speed, save-state polish |

**Why both?** As of 2024 Apple officially permits emulators on the App Store, so
Delta and RetroArch are first-class. The in-app WASM path gives you the bespoke
GBA skin + edge-slip haptics you asked for; the hand-off path is the fallback for
heavy PSX titles.

---

## 2. One-time Google Drive connection

1. Go to <https://console.cloud.google.com> → create a project (free).
2. **APIs & Services → Library →** enable **Google Drive API**.
3. **Credentials → Create Credentials → OAuth client ID → Web application.**
4. Under *Authorized JavaScript origins* add your launcher URL
   (e.g. `http://localhost:5173` for dev, and your deployed origin).
5. Copy the **Client ID** → paste into RetroLauncher **Settings → Google Drive**.
6. Tap **Connect Drive**, approve, then **Import Library**.

### Drive folder layout
Make one folder named exactly **`RetroLauncher`** in your Drive:

```
RetroLauncher/
├── GBA/
│   └── Pokemon - Fire Red.gba
├── PSX/
│   ├── Metal Gear Solid (Disc 1).bin/.cue
│   └── Small Soldiers.bin/.cue
└── BIOS/
    └── SCPH5501.BIN
```

The importer reads `.gba .gbc .gb` (Game Boy line) and `.bin .cue .img .chd .pbp`
(PlayStation). File names are auto-cleaned (region tags stripped) for matching
box art.

---

## 3. PlayStation BIOS — what's *actually* required

PSX emulation needs a BIOS dump (legally, from your own console). Research summary:

- **PCSX-ReARMED is not picky** — any retail PS1/PSone BIOS works. ([libretro docs](https://docs.libretro.com/library/pcsx_rearmed/))
- **Most compatible single file: `SCPH5501.BIN`** (US v3.0). Use this as the default.
- `SCPH1001.BIN` (US v2.2) also works. `PSXONPSP660.BIN` is favored by some
  handheld setups for edge-case compatibility.
- The RetroArch core can be filename-sensitive — keep it named exactly
  `SCPH5501.BIN`.

Verification hashes baked into `src/utils/trust.js`:

| File | MD5 | Region |
|------|-----|--------|
| `SCPH5501.BIN` | `490f666e1afb15b7362b406ed1cea246` | US v3.0 ✅ default |
| `SCPH1001.BIN` | `924e392ed05558ffdb115408c263dccf` | US v2.2 |
| `SCPH5502.BIN` | `32736f17079d0b2b7024407c39bd3050` | EU v3.0 |
| `SCPH5500.BIN` | `8dd7d5296a650fac7319bce665a6a5aa` | JP v3.0 |

RetroLauncher **hash-checks your BIOS before boot** and refuses corrupt/wrong-region
files (toggleable in Settings → Trust & Safety).

### Your two PSX targets
- **Metal Gear Solid** — multi-disc. Disc 1 boots; the game prompts a disc swap at
  the codec point — load Disc 2 via the in-emulator disc-swap control.
- **Small Soldiers** — single disc, runs cleanly on `SCPH5501.BIN`.

---

## 4. Pokémon Fire Red (GBA) — the primary target

GBA needs **no BIOS** (mGBA has a high-accuracy HLE BIOS built in). Drop
`Pokemon - Fire Red.gba` into `RetroLauncher/GBA/`, import, tap Play. The launcher
locks landscape, wraps the screen in the GBA skin, and you're in Pallet Town.

---

## 5. The "1 chosen + 2 runners-up" download policy

By design the launcher commits the **one chosen game** to device storage (IndexedDB)
for instant offline play, and **pre-stages the next two** most-likely titles
(top of Continue Playing / same system) in the background. See
`src/services/prefetch.js`. Everything else stays in Drive until tapped.

---

## 6. Run it

```bash
cd retro-launcher
npm install
npm run dev      # open the printed URL on your iPhone (same network)
```

Add to Home Screen (Safari → Share → Add to Home Screen) to get the full-screen,
status-bar-hidden PWA experience with haptics.

See [`docs/RESEARCH.md`](RESEARCH.md) for sourced links to emulators, cores, BIOS
guidance, skins, and art databases.
