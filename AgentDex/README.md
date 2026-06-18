# AgentDex 🔮

> Catch the souls of your agents. A Pokémon-like creature collector where every
> monster is generated from a real AI agent or sub-agent you've used.

**Working title:** *AgentDex — Daemon Tamer*

Each creature is a **Daemon** — the bound "soul" of one of your agents. Main-tier
agents become rare, powerful Daemons; the little sub-agents and helpers that show
up in your logs become the common ones you'll meet first. You explore an
overworld, see wild Daemons roaming and fighting *in the world* (no screen
switch by default), weaken them in real-time combat, then throw a **Sphere** to
bind them. There's an optional classic turn-based "screen-switch" battle mode for
purists.

The story, the protagonist, and the NPCs are seeded from *your* profile — you
play a **Conductor**, someone who can see and bind the daemons that do the work
behind every project.

---

## What's in this folder

| Path | What it is |
|------|------------|
| `DESIGN.md` | The full game design document (mechanics, world, story, humor) |
| `ARCHITECTURE.md` | Technical architecture: how core / app / widget fit together |
| `ROADMAP.md` | Milestones from "tiny test build" → full game |
| `Package.swift` | Swift Package for **AgentDexCore** (pure, testable logic) |
| `Sources/AgentDexCore/` | The portable game engine (no UIKit/SpriteKit) |
| `Tests/AgentDexCoreTests/` | Unit tests for generation, battle, and catching |
| `Config/` | Example `agents.json` / `player.json` you edit to seed the game |
| `App/` | SwiftUI + SpriteKit app sources (iOS-first, macOS-ready) |
| `Widgets/` | WidgetKit sources (iOS + macOS home/lock-screen widgets) |

## The 60-second pitch of how it works

1. You describe your agents in `Config/agents.json` (name, tier, role, project).
2. `DaemonGenerator` turns each agent **deterministically** into a Daemon — same
   agent always yields the same creature (stats, element, sigil shape, looks,
   personality, flavor text). Add a new agent → a new species appears in the wild.
3. You roam the overworld, fight wild Daemons in real time, and throw Spheres to
   catch them. Caught Daemons join your party and your **Dex**.
4. Widgets show your starter / party / "Daemon of the Day" on the home screen.

## Running the prototype (on a Mac)

The shared logic is a Swift Package you can build and test today:

```bash
cd AgentDex
swift test        # runs the AgentDexCore unit tests
```

The app + widgets are plain Swift source files meant to be dropped into an Xcode
project (see `ARCHITECTURE.md` → "Assembling the Xcode project"). They import
`AgentDexCore`, so all the game rules are shared and tested.

> This prototype was scaffolded in a Linux CI container with no Swift toolchain,
> so the core is written to compile cleanly but has not been run here — run
> `swift test` locally first.
