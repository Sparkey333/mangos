# AgentDex Changelog

All notable changes to AgentDex. Versions follow the roadmap milestones; dates
are when the version was cut.

## v0.3.0 — 2026-07-09 — "The Gameplay Update"

The scaffold grows a game. One giant content-and-systems drop:

### Battle
- Full battle sessions (`BattleSession`) driving both the real-time overworld
  fights and the classic screen-switch mode from one engine.
- Stat stages (±6) with Pokémon-style multipliers.
- 10 passive abilities (Failsafe, Overclock, Hardened, Hot Reload, Clean Code,
  Cache Hit, Burst Mode, Firewall, Garbage Collector, Load Balancer).
- 5 status conditions: STALLED, LOOPED, DEPRECATED, RATE-LIMITED, OVERHEATED.
- Battle AI and a deadpan battle narrator with daemon barks.
- Rival duels vs **Rune**, with a team that scales to your progress.

### Progression
- XP and levels with per-tier growth curves; daemons learn new moves as they grow.
- **Ascension** (evolution): daemons promote to the next tier at its threshold.
- Gen-4-style catch shakes and **critical captures** in the catch flow.
- 14 achievements.

### World
- Procedural regions generated per project, each with themes and spawn tables.
- Idle / Busy / Peak load cycles that shift spawns over real time.
- Anomalous (shiny) daemons.

### Story
- 10-quest main arc: **"The Silent Orchestrator"**, tracked in the journal.
- Quest-aware NPC dialogue; NPCs tutorialize in character.
- Onboarding flow with a starter choice.

### Economy
- **Cycles** currency earned from battles and quests.
- **Vex's shop** with 5 items: Hotfix, Full Patch, Rollback, Debugger,
  Training Data.

### Presentation
- Procedural chiptune audio engine + haptic cues (no bundled audio assets).
- Upgraded widgets (party / Daemon-of-the-Day read the live save).
- Procedurally generated app icon, rendered at build time
  (`Scripts/generate_appicon.swift`).

### Save
- Save format v2 (versioned on-disk `SaveFile`) with automatic migration of
  legacy v0.2 saves.

### Tests
- Expanded unit coverage across generation, battle math, catch math, and the
  importer.

## v0.2.0

- Runnable macOS app via SwiftPM (`swift run AgentDexApp`).
- One-command app bundle + DMG packaging (`build_macos_app.sh`, `make_dmg.sh`).
- XcodeGen `project.yml` for the iPhone app + WidgetKit extension + macOS app.
- Agent importer: `AgentDexImport` library + `agentdex-import` CLI scan logs and
  agent folders to auto-author `agents.json`.
- Opt-in classic turn-based battle view.

## v0.1.0

- Initial scaffold: `AgentDexCore` engine (deterministic daemon generation,
  battle + catch math, type chart), unit tests, example configs, and the design
  docs (`DESIGN.md`, `ARCHITECTURE.md`, `ROADMAP.md`).
