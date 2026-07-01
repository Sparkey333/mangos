# Project Aether — Vertical Slice (Godot 4)

The playable seed of the Metroidvania in the AetherForge **Game Design Doc**. Open this folder in
**Godot 4.3+** and press ▶ — no assets needed to run; it greyboxes everything in code so you can
feel the controls and fight the first boss immediately.

## What's implemented (M0 → M2 from the GDD)

- **Player controller with real game feel** (`scripts/player.gd`): run accel/friction, heavier
  fall gravity, **variable jump height, coyote time, jump buffering**, **dash + i-frames**.
- **Real combat:** melee attack with a hitbox, **HP (hearts)**, knockback + hit-stun on damage,
  and **instant respawn** (GDD: death is cheap).
- **Hit-stop** (`scripts/hitstop.gd`, autoloaded): every connecting blow briefly freezes time —
  the single biggest "feels good" trick.
- **A 3-phase boss — "The First Warden"** (`scripts/boss.gd`): telegraphed attacks that
  **escalate each phase** (charge → +3-bolt spread → desperation: rapid charge + 5-bolt spread),
  with phase-gated invulnerability and a colour wind-up on every attack (read, don't memorize).
- **A musical arc** (`scripts/music_manager.gd`): each boss phase raises the music a layer
  (bed → +combat → full + pitch-up). Drop your guitar/drums OGGs in `audio/` to hear it.
- **Greybox arena, follow camera, HUD** (hearts + a live boss health/phase bar).

## Controls

| Action | Keys |
|--------|------|
| Move | `A`/`D` or `←`/`→` |
| Jump | `Space` / `W` / `↑` |
| Dash | `Shift` / `J` |
| Attack | `K` / `X` |

## Play the fight

1. Install Godot 4.3+ — <https://godotengine.org/download> (`brew install --cask godot`).
2. Godot → **Import** → this folder's `project.godot` → **Edit** → ▶.
3. Run right, dash the gap, cross the **orange gate** → the Warden wakes. Hit it (`K`), dodge with
   dash i-frames, and watch it speed up + the music climb each phase.

## Tuning & next steps

- All feel/combat numbers are consts at the top of `player.gd` and `boss.gd` — tweak freely.
- Make dash a real **unlock** (set `has_dash = false`, grant after the Warden).
- Drop `ambient.ogg` / `combat.ogg` / `boss.ogg` in `audio/` (see `audio/README.md`) for the score.
- Swap Polygon2D greyboxes for sprites/tilesets (see the hub's **Asset Pipeline** doc).
