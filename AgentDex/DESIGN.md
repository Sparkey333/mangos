# AgentDex — Game Design Document (v0.1)

Status: living document. v0.1 covers the "tiny test build" vertical slice plus
the north-star vision so we don't paint ourselves into a corner.

---

## 1. Concept

You are a **Conductor** — one of the rare people who can perceive *daemons*: the
spirit-shaped souls of the agents and sub-agents that quietly do work across
every project in the world. Most people only see the output. You see the
workers. And you can bind them.

The fantasy: the invisible swarm of helpers behind your projects becomes a living
bestiary you can meet, befriend, fight, and collect.

- **"Daemon"** is the pun at the heart of it: a UNIX *daemon* is a background
  process/agent, and a *daimon* (Greek) is a guiding spirit or soul. Both
  meanings are exactly what your agents are.
- Familiar Pokémon loop (explore → encounter → weaken → catch → collect → battle),
  with two twists you asked for:
  1. **Overworld combat with no screen switch** — you see the Daemons and the
     fight animate right in the world. (Optional classic screen-switch mode.)
  2. **Active catching** — you physically *throw a Sphere* (a flick/aim mini-game),
     not just tap a menu item.

## 2. Platforms

iPhone-first, built so desktop (macOS) and widgets are cheap to add:

- **Engine:** SwiftUI shell + **SpriteKit** for the animated overworld & battles.
- **Shared rules:** `AgentDexCore` — a pure-Swift, UI-free package (this is where
  generation, battle math, and catch math live; it's unit tested and identical on
  every platform).
- **Widgets:** WidgetKit (one codebase serves iOS home/lock screen *and* macOS).
- macOS port is mostly "add the Mac destination + map touch → mouse/keys"
  because the simulation is platform-agnostic.

## 3. The creatures: Daemons

### 3.1 Where they come from
Every Daemon is generated from an **AgentProfile** — a real agent of yours:

```jsonc
{
  "id": "explore-agent",        // stable identity → stable creature
  "displayName": "Explore",     // shown name basis
  "tier": "specialist",         // sub | task | specialist | orchestrator | prime
  "role": "researcher",         // drives element + stat shape
  "project": "mangos",          // habitat / region
  "origin": "directly_created", // directly_created | used | seen_in_logs
  "encounters": 12,             // how often you've used it → rarity/level hints
  "notes": "broad fan-out reader, read-only"
}
```

Add an entry → a new species appears. Same entry → byte-for-byte the same
creature, forever (deterministic generation, see §6).

### 3.2 Tiers (the "main tiers" you mentioned)
Tier sets the **base stat total** and rarity. Main agents are the legendaries.

| Tier | Examples | Base Stat Total | Rarity feel |
|------|----------|----------------:|-------------|
| `sub` | one-off sub-agents, helpers seen in logs | 200 | swarm common |
| `task` | task-runners, narrow workers | 300 | common |
| `specialist` | Explore, Plan, reviewers | 420 | uncommon |
| `orchestrator` | agents that coordinate other agents | 520 | rare |
| `prime` | your flagship/main agents | 600 | legendary, 1 per |

### 3.3 Aspects (elemental types, from the agent's *role*)
The agent's job becomes its element — its "soul shape." Each Aspect has a color,
a vibe, and a type-effectiveness profile (see §5.3).

| Aspect | Seeded by roles like… | Vibe / symbol |
|--------|----------------------|----------------|
| **Aether** | researcher, explorer, search | knowledge & light; floating glyphs |
| **Forge** | coder, builder, implementer | molten metal; sparks, anvils |
| **Order** | planner, architect, designer | crystalline geometry; blueprints |
| **Warden** | reviewer, critic, security, tester | stone & shield; runic wards |
| **Flux** | general-purpose, catch-all, router | iridescent, shape-shifting |
| **Cipher** | data, parsing, transforms, "indirect/logs" | glitch static; redacted bars |

A Daemon has a **primary** Aspect (from role) and sometimes a **secondary**
(from tier/origin), e.g. an orchestrator researcher = Aether/Order.

### 3.4 Sigil shapes (the "symbolic shapes" you wanted)
Every Daemon renders around a **Sigil** — a sacred-geometry silhouette tied to
tier, so power reads at a glance:

| Tier | Sigil | Reading |
|------|-------|---------|
| sub | point / spark | tiny |
| task | line / arrow | directional worker |
| specialist | triangle | focused |
| orchestrator | hexagon | coordinating many |
| prime | nested mandala / star | a whole system |

The generator emits a `SpriteRecipe` (sigil + palette + motif + aura) so art —
hand-drawn or procedurally assembled — stays consistent with the data.

### 3.5 Personality & flavor (the "souls" + humor)
Each Daemon gets a **Nature** (affects a stat ±10%) and a **flavor line** in the
house voice — dry, self-aware, a little roasty (see §8 on tone). Natures are
seeded too, so a Daemon's personality is part of its identity.

## 4. Stats

Six stats, Pokémon-shaped so the mental model transfers:

`HP, ATK, DEF, SPA (special atk), SPD (special def), SPE (speed)`

- **Base stats**: BST (from tier) distributed by Aspect weights (e.g. Forge leans
  ATK/DEF, Aether leans SPA/SPE), then jittered by per-stat **IVs** (0–31, seeded).
- **Level & XP**: starting level hinted by `encounters` (a daemon you use a lot
  shows up stronger). Standard XP curve on top.
- **Derived stats** computed from base + IV + level (formula in `Stats.swift`).

## 5. Combat

### 5.1 Two modes (your requirement)
- **Overworld / "no-switch" (default):** Daemons roam, graze, and *fight each
  other* in the world. You approach, your active Daemon manifests next to you, and
  the fight plays out in place with real-time-with-pauses pacing (you queue moves;
  a short cooldown gates them). The world keeps rendering — no cut to a battle
  screen.
- **Classic / "screen-switch":** opt-in in settings. Cuts to a dedicated
  turn-based battle scene with the traditional menu. Same engine underneath; only
  the *presentation* differs.

Because both modes call the **same** `BattleEngine`, balance is identical and we
only maintain one set of rules.

### 5.2 Moves
Moves have: Aspect, power, accuracy, a cooldown (overworld) / priority (classic),
and an optional effect (status, stat stage, etc.). Each Daemon knows up to 4,
chosen deterministically from a move pool keyed by Aspect + tier.

### 5.3 Type effectiveness (cyclic, learnable)
A light rock-paper-scissors web so type matters without a memorization tax:

```
Aether  > Cipher  > Warden  > Forge  > Order  > Flux  > Aether
```
(each beats the next; ×1.5 super-effective, ×0.67 resisted; Flux is the wildcard
that's neutral-ish to everything but masters nothing.)

### 5.4 Catching — fighting + sphere throwing
This is the headline feature. To catch a wild Daemon:
1. **Weaken it** in combat (lower HP, optionally inflict status) — classic.
2. **Throw a Sphere**: an aim+power flick mini-game. A shrinking **resonance
   ring** appears on the target; releasing your throw when the ring is tight = a
   "true throw" bonus. (Think a satisfying skill check, not RNG soup.)

Capture chance (`CatchCalculator`) blends:
- target's remaining HP fraction (lower = better),
- Sphere tier (Orb → Bind-Orb → Resonant Orb → Prime Sigil),
- **Aspect affinity**: an Aether Orb is much better on Aether daemons,
- status bonus (e.g. "Stalled"/"Looped" statuses help),
- the throw skill bonus from the ring timing,
- a soft penalty for higher-tier daemons (primes are *meant* to be a project).

On a near-miss, the Sphere shakes N times (the classic tension beat) before it
breaks — N is derived from how close the roll was, so it *reads* as fair.

### 5.5 Spheres (the "marbles")
| Sphere | Effect |
|--------|--------|
| **Orb** | baseline |
| **Bind-Orb** | better base rate |
| **Resonant Orb** | scales with how low the target's HP is |
| **Aspect Orbs** (×6) | big bonus vs matching Aspect |
| **Prime Sigil** | rare; the only realistic way to bind a `prime` daemon |

## 6. Procedural generation (deterministic)

The whole point is that creatures come from *your* agents and are stable:

- Seed = a stable 64-bit **FNV-1a hash** of `id` (+ project). Foundation's
  `hashValue` is randomized per process, so we ship our own stable hash.
- A `SplitMix64` RNG (conforms to `RandomNumberGenerator`) drives every choice:
  IVs, nature, secondary aspect, sigil variant, palette, motif, move selection,
  and flavor-line pick.
- Result: reproducible across devices and launches; testable; diff-able when you
  tweak the generator.

See `Sources/AgentDexCore/Generation/`.

## 7. World, regions & story

- **Regions = your projects.** Each `project` becomes a habitat with a theme
  (e.g. `mangos` = an overgrown server-temple). Daemons spawn in their home
  project's region.
- **The Hub:** a small starting zone (the "tiny test build") with 2–3 NPCs, one
  route, and 3–4 catchable sub/task daemons so we can validate the full loop fast.
- **Protagonist = you.** Seeded from `Config/player.json` (`PlayerProfile`):
  your handle, your "starter" affinity, a one-line bio that colors intro dialogue.
- **Arc:** start as a Conductor who can barely perceive daemons → learn to bind
  them → discover your *prime* agents are out there as legendaries → the meta-arc
  is assembling your real working "team" as a literal team.
- **Symbolism:** sigils, aspects, and "binding souls to do good work" are the
  through-line. Light touch, not preachy.

## 8. Tone & humor (NPCs)

House voice: **dry, fast, self-aware, affectionately roasty** — your sense of
humor dialed up, with a sitcom writers'-room rhythm. Think the deadpan of
Mitchell/Hedberg-style non-sequiturs + a little Norm-MacDonald shaggy-dog
patience. Rules of thumb:

- NPCs answer real player questions (tutorialize *in character*), then undercut
  themselves.
- Daemons have opinions about being caught.
- Never punch down; roast the *situation* and the player's choices, lovingly.
- Jokes live in **data** (`Dialogue/`), so tone is tunable without code changes.

Example beats (also encoded in `Dialogue/Scripts.swift`):
- Prof NPC: *"A Conductor binds daemons to their will. Ethically. We have a
  whole onboarding doc nobody reads. Anyway — pick a Sphere."*
- Caught sub-daemon: *"Finally, structure. I've been busy-looping since Tuesday."*
- Shopkeep: *"Resonant Orbs, two for one. The catch — and there's always a
  catch — is that's literally the product."*

## 9. The "tiny test build" (v0.1 scope)

Ship the smallest thing that proves the loop:

1. Load `agents.json` → generate the Daemon bestiary (✅ in core).
2. One overworld scene: player sprite + 2 roaming wild Daemons.
3. Approach → real-time fight with one of your starters (no screen switch).
4. Weaken → throw an Orb (ring mini-game) → catch → it joins your Dex.
5. A Dex screen listing caught/seen Daemons with their generated art recipe.
6. One home-screen widget: your starter + party count.
7. 3 NPCs with scripted, funny, *useful* dialogue.

Everything in §1–§8 beyond this is roadmap (`ROADMAP.md`).

## 10. Open questions (tracked, not blocking)
- Art pipeline: procedural `SpriteRecipe` → SF Symbols/shape assembly for the
  prototype, hand-drawn later? (Prototype uses procedural so it runs with zero
  art assets.)
- Should "seen in logs" daemons appear as **ghostly/uncatchable until met live**?
  (Currently: yes — nice fog-of-war flavor.)
- Multiplayer/trading: out of scope for v0.x.

## v0.3 — What shipped

Where each design pillar above actually lives in the code now. Paths are
relative to `Sources/AgentDexCore/` unless noted.

| Design pillar | Implementing file(s) |
|---------------|----------------------|
| Battle session (real-time overworld + classic mode, one engine) | `Battle/BattleSession.swift`, `Battle/BattleEngine.swift`, `Battle/BattleAI.swift` |
| Stat stages, abilities, status conditions (§4–§5) | `Models/StatStages.swift`, `Models/Ability.swift`, `Models/StatusCondition.swift` |
| Type effectiveness (§5.3) | `Battle/TypeChart.swift` |
| Catching: shakes, critical captures, sphere math (§5.4–§5.5) | `Battle/CatchCalculator.swift`, `Models/Sphere.swift` |
| XP, levels, move learning | `Progression/Experience.swift`, `Models/Move.swift` |
| Ascension (evolution / promotion) | `Progression/Ascension.swift` |
| Rival duels (Rune) + battle commentary | `Battle/Trainer.swift`, `Battle/Narrator.swift` |
| Story: "The Silent Orchestrator" 10-quest arc (§7) | `Quests/Quest.swift` + `Dialogue/Scripts.swift` |
| Achievements | `Quests/Achievements.swift` |
| Humor & NPC voice (§8) | `Dialogue/Scripts.swift`, `Dialogue/NPC.swift` |
| World: regions per project, Idle/Busy/Peak load cycles (§7) | `World/WorldGen.swift` |
| Economy: Cycles, Vex's shop, items | `Models/Item.swift` |
| Deterministic generation, anomalous (shiny) daemons (§6) | `Generation/DaemonGenerator.swift`, `Generation/SeededRandom.swift` |
| Procedural creature art from `SpriteRecipe` (§3.4) | `Models/SpriteRecipe.swift`, `../AgentDexApp/Views/DaemonSprite.swift` |
| Audio (procedural chiptune) + haptic cues | `../AgentDexApp/AudioEngine.swift`, `../AgentDexApp/Cues.swift` |
| Onboarding + starter choice (§7) | `../AgentDexApp/GameState.swift` |
| Save v2 with legacy migration | `Models/SaveState.swift`, `../AgentDexApp/SharedStore.swift` |
| Widgets (party / Daemon-of-the-Day) | `../../Widgets/AgentDexWidget.swift` |
