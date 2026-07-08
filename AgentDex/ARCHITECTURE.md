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

## Building & running

Full, current instructions live in **BUILD.md**. Two paths:

- **macOS app + `.dmg`** — pure SwiftPM, no Xcode project needed:
  `./Scripts/run.sh` (play) or `./Scripts/make_dmg.sh` (installable DMG). The app
  is the `AgentDexApp` executable target in `Package.swift`; the `Info.plist` and
  bundle are assembled by `Scripts/build_macos_app.sh`.
- **iPhone + widgets (App Store path)** — generated from `project.yml`:
  `brew install xcodegen && xcodegen generate && open AgentDex.xcodeproj`. This
  creates `AgentDex-iOS`, `AgentDexWidgets` (extension), and `AgentDex-macOS`
  targets, each depending on the `AgentDexCore` / `AgentDexImport` package
  products. The widget target pulls in the three shared UI files
  (`SharedStore.swift`, `Color+Hex.swift`, `Views/DaemonSprite.swift`) so it
  renders the same procedural sprites and reads the same save. The App Group
  (`group.agentdex`) is set on both app and widget in the spec.

### Build/test the core alone (any Swift toolchain, no Xcode UI)
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
