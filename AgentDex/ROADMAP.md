# AgentDex — Roadmap

Milestones are ordered to keep a *playable* build at every step. Each builds on
the prior; nothing here requires throwing earlier work away.

## M0 — Core engine + tiny test build  ← (this scaffold)
- [x] `AgentDexCore`: models, deterministic generator, battle + catch math.
- [x] Unit tests for generation / battle / catch.
- [x] Example `agents.json` / `player.json`.
- [x] App sources: SwiftUI shell, SpriteKit overworld, throw-to-catch overlay, Dex.
- [x] One widget (party / Daemon-of-the-Day).
- [ ] (You) Assemble in Xcode, `swift test`, run on simulator.

## M1 — Make the loop feel good
- [ ] Real-time-with-cooldown move queue + telegraphs in the overworld.
- [ ] Throw mini-game polish: resonance ring, arc trajectory, shake-and-break beat.
- [ ] Opt-in classic screen-switch battle scene (same engine).
- [ ] Save/load via App Group; widget reads live party.

## M2 — Content & generation depth
- [ ] Secondary aspects, abilities, expanded move pools per aspect/tier.
- [ ] `SpriteRecipe` → assembled procedural art (shapes/SF Symbols + palettes).
- [ ] Regions per project with distinct themes + spawn tables.
- [ ] Evolution: a daemon "promotes" when its source agent gains tier/usage.

## M3 — Story & humor
- [ ] Branching NPC dialogue trees; in-game "ask an NPC" Q&A help system.
- [ ] Intro arc seeded from `PlayerProfile`; prime-agent legendaries questline.
- [ ] Comedian-voice dialogue pass; daemon barks during combat.

## M4 — Ingest automation (your "logs/indirect" idea)
- [ ] Optional importer: scan log files / project dirs → auto-author `agents.json`.
- [ ] "Seen in logs" = ghost encounters until met live.

## M5 — Desktop + ecosystem
- [ ] macOS build (input remap; window/scene sizing).
- [ ] macOS widgets; Lock Screen + StandBy widgets on iOS.
- [ ] iCloud sync of `SaveState`.

## Later / maybe
- Trading & co-op; shareable Dex cards; Shortcuts/Live Activities for "your agent
  is working" → spawns a wild daemon.
