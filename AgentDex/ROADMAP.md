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
      (Still pending — overworld fights currently resolve through the shared
      turn engine; the cooldown-queue presentation is the remaining piece.)
- [x] Throw mini-game polish: shake-and-break beat shipped in v0.3 as Gen-4-style
      catch shake choreography + critical captures (ring was already done; arc
      trajectory folded into the same overlay).
- [x] Opt-in classic screen-switch battle scene (same engine) — `ClassicBattleView`.
- [x] Save/load via shared store; widget reads live party.
- [x] Runnable macOS build + one-command `.dmg` packaging (`Scripts/`).
- [x] XcodeGen project for iPhone + macOS + widgets (`project.yml`).

## M2 — Content & generation depth
- [x] Secondary aspects, abilities (10), expanded move pools per aspect/tier — v0.3.
- [x] `SpriteRecipe` → assembled procedural art (sigil + palette + motif + aura)
      — `DaemonSprite`, zero image assets.
- [x] Regions per project with distinct themes + spawn tables, plus
      Idle/Busy/Peak load cycles — `World/WorldGen.swift`, v0.3.
- [x] Evolution — shipped in v0.3 as **Ascension** (`Progression/Ascension.swift`):
      daemons promote at a per-tier level threshold.

## M3 — Story & humor
- [x] NPC dialogue with quest-aware beats; NPCs tutorialize in character — v0.3.
- [x] Intro arc seeded from `PlayerProfile`; 10-quest main arc
      ("The Silent Orchestrator") culminating in the prime-agent questline — v0.3.
- [x] Comedian-voice dialogue pass; daemon barks during combat
      (`Battle/Narrator.swift`) — v0.3.

## M4 — Ingest automation (your "logs/indirect" idea)
- [x] Optional importer: scan log files / project dirs → auto-author `agents.json`
      (`AgentDexImport` + `agentdex-import` CLI). App auto-loads the result.
- [ ] "Seen in logs" = ghost encounters until met live (data flagged; UI pending).
- [ ] Richer log parsers (structured JSONL sessions, per-project tallies).

## M5 — Desktop + ecosystem
- [ ] macOS build (input remap; window/scene sizing).
- [ ] macOS widgets; Lock Screen + StandBy widgets on iOS.
- [ ] iCloud sync of `SaveState`.

## M6 — Polish & store submission
- [x] App icon: generated procedurally at build time — `Scripts/generate_appicon.swift`
      (embedded as `.icns` by `build_macos_app.sh`/`make_dmg.sh`; the XcodeGen
      targets run it as a pre-build phase and compile the asset catalog).
- [ ] TestFlight archive: set `DEVELOPMENT_TEAM` in `project.yml`,
      `xcodegen generate`, Product → Archive, upload via Organizer
      (see `DISTRIBUTION.md`).
- [ ] App Store screenshots (iPhone 6.7"/6.1", iPad, Mac) captured from
      Simulator; one per tab + a battle + a catch.
- [ ] Review checklist: privacy/data-use answers (no network, all local),
      age rating, `public.app-category.games`, marketing copy, What's-New text.

## Later / maybe
- Trading & co-op; shareable Dex cards; Shortcuts/Live Activities for "your agent
  is working" → spawns a wild daemon.
