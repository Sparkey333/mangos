# Project Aether — Vertical Slice (Godot 4)

The playable seed of the Metroidvania described in the AetherForge **Game Design Doc**.
Open this folder in **Godot 4.3+** and press ▶. No assets required to run — it greyboxes
everything in code so you can feel the controls immediately.

## What's implemented (the M0–M1 milestones from the GDD)

- **Player controller with real game feel:** run accel/friction, heavier fall gravity,
  **variable jump height**, **coyote time**, **jump buffering**, and a **dash with i-frames
  + cooldown**. Tunables live at the top of `scripts/player.gd`.
- **Greybox room:** floor, walls, platforms (with a gap you dash across) — `scripts/world.gd`.
- **Smooth follow camera.**
- **Adaptive music manager** (`scripts/music_manager.gd`): three layered stems
  (ambient → combat → boss) that cross-fade by game state. Drop your guitar/drums OGGs in
  `audio/` (see `audio/README.md`).
- **Proximity enemy + boss zone** that switch the music layer so you can *hear* the system
  working before any audio exists.

## Controls

| Action | Keys |
|--------|------|
| Move | `A`/`D` or `←`/`→` |
| Jump | `Space` / `W` / `↑` |
| Dash | `Shift` / `J` |
| Attack (stub) | `K` / `X` |

## Run it

1. Install Godot 4.3+ — <https://godotengine.org/download> (or `brew install --cask godot`).
2. Godot → **Import** → select this folder's `project.godot` → **Edit** → press ▶.

## Export (later)

- **Steam / desktop:** Project → Export → Windows/macOS/Linux presets.
- **Web (playable in a browser, embeddable in the AetherForge hub):** add the **Web** export
  template and export to HTML5.
- **Mobile:** Android/iOS export presets.

## Next steps (from the GDD)

1. Replace Polygon2D greyboxes with sprites/tilesets (see **Asset Pipeline**).
2. Make the dash a real *unlock* (set `has_dash = false`, grant it after the first boss).
3. Build the first boss (3-phase, musical escalation) — that's the M2 vertical-slice goal.
4. Add hit-stop on successful hits (freeze a few frames) — the single biggest feel upgrade.
