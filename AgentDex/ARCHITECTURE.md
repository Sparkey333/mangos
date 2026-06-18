# AgentDex — Technical Architecture

## Layering (why the prototype is split this way)

```
┌──────────────────────────────────────────────────────────────┐
│  App (iOS first, macOS later)        Widgets (WidgetKit)       │
│  SwiftUI + SpriteKit                  SwiftUI timeline views    │
│   • OverworldScene (no-switch fights) │ • Party / Daemon-of-day │
│   • BattleOverlayView / Classic scene │                         │
│   • DexView, GameState (ObservableObject)                       │
└───────────────▲───────────────────────────────▲───────────────┘
                │ imports                         │ imports
        ┌───────┴─────────────────────────────────┴───────┐
        │              AgentDexCore  (pure Swift)           │
        │   no UIKit / SpriteKit / SwiftUI dependencies     │
        │                                                   │
        │  Models/        Daemon, Stats, Aspect, Tier,      │
        │                 SigilShape, Move, Sphere,         │
        │                 AgentProfile, PlayerProfile,      │
        │                 SaveState, SpriteRecipe           │
        │  Generation/    SeededRandom (SplitMix64 + FNV),  │
        │                 DaemonGenerator, Bestiary         │
        │  Battle/        BattleEngine, TypeChart,          │
        │                 CatchCalculator                   │
        │  Dialogue/      NPC, Scripts                      │
        │  Config/        ConfigLoader (Codable JSON)       │
        └───────────────────────────────────────────────────┘
```

**Rule:** all game *rules* (numbers, randomness, outcomes) live in `AgentDexCore`
and are unit-tested. The App/Widgets only *present* and *animate* what the core
decides. This is what makes "iPhone first, desktop + widgets later" cheap: porting
is a presentation problem, not a logic rewrite.

## Determinism contract

- `SeededRandom` implements `RandomNumberGenerator` via SplitMix64.
- Seeds come from `stableHash(_:)` (FNV-1a 64-bit) — **never** from
  `Hashable.hashValue` (which is per-process randomized).
- Therefore: a given `AgentProfile.id` always generates the identical `Daemon` on
  every device and every launch. Tests assert this.

## Data flow

1. `ConfigLoader` decodes `agents.json` → `[AgentProfile]` and `player.json` →
   `PlayerProfile`.
2. `Bestiary(from:)` maps each profile through `DaemonGenerator.generate(from:)`
   → species list (`DaemonSpecies`).
3. At encounter time the App instantiates a live `Daemon` (species + level + IVs).
4. `BattleEngine` resolves moves; `CatchCalculator` resolves throws.
5. Results mutate `SaveState` (party, dex, inventory); App persists it (JSON in
   app container; the prototype uses a simple `Codable` round-trip).
6. Widgets read the same `SaveState` JSON from a shared App Group container.

## Assembling the Xcode project (when you're on a Mac)

The `App/` and `Widgets/` folders are source-only (no `.xcodeproj` is checked in,
to keep the repo clean and merge-friendly). To run on device/simulator:

1. **New Xcode project** → *iOS App* → name `AgentDex`, interface **SwiftUI**.
2. **Add the core package:** File → Add Package Dependencies → "Add Local…" →
   select this `AgentDex/` folder (it has `Package.swift`). Add the
   `AgentDexCore` library to your app target.
3. **Add sources:** drag everything in `App/` into the app target, and the files
   in `Config/` into the bundle (Target Membership ✓) so they ship as resources.
4. **Add a Widget Extension** target → drag `Widgets/` sources into it; add the
   `AgentDexCore` dependency to that target too. **Shared UI files:** add
   `App/SharedStore.swift`, `App/Color+Hex.swift`, and
   `App/Views/DaemonSprite.swift` to **both** the app target *and* the widget
   target (check both boxes in File Inspector → Target Membership) — the widget
   renders the same procedural sprites and reads the same save file.
5. **App Group:** enable the *App Groups* capability on both targets with the same
   group id (default expected: `group.agentdex`) so the widget can read the save.
6. Build & run. For **macOS later**: add a Mac (Designed for iPad or native)
   destination; the core needs no changes.

### Build/test the core alone (works on any Swift toolchain, no Xcode UI)
```bash
cd AgentDex
swift build
swift test
```

## Why SpriteKit for the overworld

The "see the fight animate in the world, no screen switch" requirement is a
real-time scene-graph problem. SpriteKit gives us nodes, physics, actions, and a
game loop for free, integrates natively into a SwiftUI view (`SpriteView`), and
ships on iOS + macOS. The classic screen-switch battle is just a second SpriteKit
scene (or a SwiftUI overlay) driven by the same `BattleEngine`.

## Testing strategy

- **Generation**: determinism (same id → same daemon), tier→BST mapping,
  role→aspect mapping, IV ranges.
- **Battle**: type chart correctness, damage monotonicity, KO detection.
- **Catch**: rate monotonic in HP/Sphere/affinity, bounds [0,1], shake count sane.

See `Tests/AgentDexCoreTests/`.
