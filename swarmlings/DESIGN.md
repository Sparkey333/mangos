# SWARMLINGS — Design & Roadmap

A swarm-command game in the lineage of the "command a horde of little
helpers to carry, fight, and build against a day-timer" genre. **Original
IP.** The *mechanic* is genre (not copyrightable); every name, character,
color, sound, and line of lore here is our own. See `IP-FINDINGS.md`.

The prototype is one HTML5 file (`index.html`) — no build step, runs in any
browser, on iPhone Safari, Android Chrome, and desktop. It is the seed for
all three versions below.

---

## The three versions (your v1 / v2 / v3)

| Ver | Codename | Goal | Status |
|----|----------|------|--------|
| **v1** | *Engine* | Prove the core loop with neutral placeholder art. "Can we make commanding a swarm feel good?" | ✅ shipped in this prototype |
| **v2** | *Bloomlings* (faithful skin) | Get as close to the genre's *feel* as is legal. Every IP-risky element swapped & logged. | ✅ playable skin (theme switch) |
| **v3** | *Tidewardens* (shadow) | Same engine, spirit kept, world changed **entirely** — different setting, palette, lore, enemies. | ✅ playable skin (theme switch) |

> We deliberately did **not** build a literal asset-for-asset clone of the
> source game. That version cannot be sold on the App Store, Google Play,
> Steam, or the eShop, and invites takedowns. v1 instead nails the *mechanic*
> on neutral art so the fun is proven before any skin is painted.

Flip between v2 and v3 live in-game: **⚙ Dials → World Skin**. Same code,
two completely different games — that's the proof that the value lives in the
engine, not the borrowed coat of paint.

---

## Core loop (the part that is genre, not IP)

1. A **leader** walks a field with a trailing **swarm**.
2. **Throw/dispatch** creatures at tasks: carry **cargo**, fight **foes**,
   break **hazard-walls**.
3. Heavy cargo needs **multiple carriers** (emergent crowd logic).
4. Carry cargo to the **Hive** → it **hatches more creatures** (growth loop).
5. **Day timer**: bank cargo before dusk. Strays left in the field are lost.
6. **Three creature types**, each **resists one hazard** (fire / water /
   shock) — the rock-paper-scissors that drives routing decisions.

## The dials (your "working dials" request)

All live in **⚙ Dials**, all hot-applied:

- **Swarm cap** — population ceiling (20–300). "Scale lines" for crowd size.
- **Creature scale** — physical size of each creature (0.6×–2.2×).
- **Leader speed** — pace tuning.
- **Day length** — session length / difficulty (30–240s).
- **Music amp** — *Volume* + *Intensity*. The procedural score's tempo and
  layers rise automatically with swarm size; the amp scales the whole mix.
- **Fidelity** — Lite / Standard / Hi-Def: toggles shadows, glow, grass
  density, particle counts, and render resolution. Lite for old phones,
  Hi-Def for "go up from there if requested more design and hi def."

These exist so the same build self-tunes across a $150 Android phone and a
Steam machine without code changes.

---

## Platform plan (your targets)

The single HTML5 file is the cross-platform secret. One codebase →

| Platform | Path |
|----------|------|
| **Web / itch.io** | ship `index.html` as-is |
| **iPhone / iPad (App Store)** | wrap with **Capacitor** (WKWebView) |
| **Android (Google Play)** | wrap with **Capacitor** (Trusted Web Activity / WebView) |
| **Mac / Windows / Linux (Steam)** | wrap with **Tauri** (tiny) or Electron |
| **Nintendo eShop** | port the engine to a native/WebGL runtime once a devkit is approved; the design is already controller-friendly |

If the prototype graduates, the natural next step is to re-author the same
loop in **Godot** (free, exports to every target above incl. consoles) while
keeping this HTML build as the design sandbox.

---

## Roadmap from here

- [ ] Auto-grab: creatures pick up adjacent cargo without a manual throw.
- [ ] Carrier path-finding around walls.
- [ ] Boss foe + multi-stage hazards.
- [ ] Persistent meta-progression across days (upgrades, new types).
- [ ] Controller support (for eShop/Steam Deck).
- [ ] A third "shadow" theme to prove the engine is theme-agnostic.
- [ ] Replace placeholder primitives with commissioned original art per skin.

## Run it

Open `swarmlings/index.html` in any modern browser. On desktop use WASD +
mouse; on mobile, drag to move and tap to throw.
