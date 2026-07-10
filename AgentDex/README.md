# AgentDex 🔮

> Catch the souls of your agents. A Pokémon-like creature collector where every
> monster is generated from a real AI agent or sub-agent you've used.

**Working title:** *AgentDex — Daemon Tamer* · **Current version:** v0.3
("The Gameplay Update" — see `CHANGELOG.md`)

Each creature is a **Daemon** — the bound "soul" of one of your agents. Main-tier
agents become rare, powerful Daemons; the little sub-agents and helpers that show
up in your logs become the common ones you'll meet first. You explore an
overworld, see wild Daemons roaming and fighting *in the world* (no screen
switch by default), weaken them in real-time combat, then throw a **Sphere** to
bind them. There's an optional classic turn-based "screen-switch" battle mode for
purists.

As of v0.3 this is no longer just a scaffold: it's a full game loop — story
quests, a rival, an economy, evolution, achievements, procedural regions, music,
and a save file that remembers all of it.

The story, the protagonist, and the NPCs are seeded from *your* profile — you
play a **Conductor**, someone who can see and bind the daemons that do the work
behind every project.

---

## What's in v0.3 — "The Gameplay Update"

- **Full battle system** — stat stages (±6, Pokémon-style), 10 passive abilities
  (Failsafe, Overclock, Firewall…), and 5 status conditions (STALLED, LOOPED,
  DEPRECATED, RATE-LIMITED, OVERHEATED).
- **Progression** — XP and levels, move learning as daemons grow, and
  **Ascension** (evolution): daemons promote at their tier's threshold.
- **Catching, tuned** — Gen-4-style catch shake choreography plus critical
  captures for that one-shake heart-stopper.
- **Rival duels** — trainer battles against **Rune**, a Conductor who
  force-pushes to main; their team scales with your progress.
- **Story** — a 10-quest main arc, *"The Silent Orchestrator"*, tracked in the
  in-game journal and paced by the NPC dialogue.
- **14 achievements** to chase alongside the Dex.
- **Economy** — earn **Cycles**, spend them in **Vex's shop** on 5 items
  (Hotfix, Full Patch, Rollback, Debugger, Training Data).
- **A living world** — procedural regions generated per project, with
  Idle / Busy / Peak load cycles that shift spawns over real time.
- **Anomalous daemons** — the shiny hunt begins.
- **Presentation** — procedural chiptune audio + haptics, onboarding with a
  starter choice, upgraded widgets, and a generated app icon.
- **Save v2** — versioned on-disk format with automatic migration of legacy
  (v0.2) saves.

---

## What's in this folder

| Path | What it is |
|------|------------|
| `DESIGN.md` | The full game design document (mechanics, world, story, humor) |
| `ARCHITECTURE.md` | Technical architecture: how core / app / widget fit together |
| `BUILD.md` | **How to run it on your Mac** (test app, `.dmg`, Xcode project) |
| `DISTRIBUTION.md` | Local test → TestFlight → App Store, and what each step needs |
| `ROADMAP.md` | Milestones from "tiny test build" → full game |
| `CHANGELOG.md` | What shipped in each version (v0.1 → v0.3) |
| `Package.swift` | Swift Package: core, importer, the macOS app, and the CLI |
| `Sources/AgentDexCore/` | The portable game engine (no UIKit/SpriteKit) |
| `Sources/AgentDexApp/` | SwiftUI + SpriteKit app (runs on macOS via SwiftPM; iOS via Xcode) |
| `Sources/AgentDexImport/` | Log/folder → `agents.json` importer library |
| `Sources/agentdex-import/` | The importer CLI (`swift run agentdex-import`) |
| `Tests/` | Unit tests for generation, battle, catching, and importing |
| `Scripts/` | `run.sh`, `build_macos_app.sh`, `make_dmg.sh`, `import_my_agents.sh`, `generate_appicon.swift` |
| `Config/` | Example `agents.json` / `player.json` you edit to seed the game |
| `Widgets/` | WidgetKit sources (added via the Xcode project) |
| `project.yml` | XcodeGen spec → full iPhone + macOS + widgets Xcode project |

## The 60-second pitch of how it works

1. You describe your agents in `Config/agents.json` (name, tier, role, project).
2. `DaemonGenerator` turns each agent **deterministically** into a Daemon — same
   agent always yields the same creature (stats, element, sigil shape, looks,
   personality, flavor text). Add a new agent → a new species appears in the wild.
3. You roam the overworld, fight wild Daemons in real time, and throw Spheres to
   catch them. Caught Daemons join your party and your **Dex**.
4. Widgets show your starter / party / "Daemon of the Day" on the home screen.

## Running it (on a Mac)

Full instructions in **BUILD.md**. The short version:

```bash
cd AgentDex
swift test                    # 1. verify the game rules (generation/battle/catch/import)
./Scripts/run.sh              # 2. play it: opens the macOS app (swift run AgentDexApp)
./Scripts/make_dmg.sh         # 3. build build/AgentDex.dmg — install like a store app
```

Seed it with **your** agents (optional but the whole point):
```bash
./Scripts/import_my_agents.sh mangos
# or precisely:
swift run agentdex-import --agents ~/.claude/agents --logs ~/.claude/projects --project mangos
```

For the **iPhone app + widgets** (and the App Store path):
```bash
brew install xcodegen && xcodegen generate && open AgentDex.xcodeproj
```

> Scaffolded in a Linux container with no Swift toolchain, so the code is written
> to compile cleanly but has **not been run here**. Run `swift test` on your Mac
> first; if anything trips, it'll be a quick fix.
