# DESIGN — evolution tiers & the bestiary (seed)

Design captures for where the game grows. Like `LORE_VAULT.md`, this is a living
doc — buildable specs, not final rules. Two parts:
**A) the evolution system** (Golden Sun "Djinn"-inspired, but ours) and
**B) the enemies & hidden bosses** (NeverEnding Story, Labyrinth, animatronic,
Sephiroth-style secret bosses).

---

## A. EVOLUTION — aligning the strands

Each of the Seven **evolves through tiers** by *aligning* the strands it already
carries: **color · symbol · power · geometry · numerology · stone · tone.** When
enough strands line up, the Hunter ascends a tier — new sprite, new move, new
resonance. Hidden, gradual, earned — the Golden Sun *Djinn* feel (collect, set,
unleash, evolve) but tuned to our seven-fold structure.

### The Djinn analogue — "Shards" (working name)
Golden Sun has elemental Djinn you collect, *Set* (boost stats / change class),
and *unleash* (spend, then they recharge). Ours:

- **Shards** = fragments of the other six colors, plus hidden 8/9/0 motes.
- **Set** a Shard to a Hunter to tilt its alignment (e.g., set a Blue shard on
  PYROKK → it leans toward the throat/expression strand, unlocking a hybrid).
- **Unleash** = spend a Shard for a burst move keyed to that Shard's tone, then
  it recharges over turns.
- **Align** enough matching strands and the Hunter **evolves a tier** for good.

### Tier ladder (per Hunter)
| Tier | Name idea | Gate (align N strands) | What changes |
|-----:|-----------|------------------------|--------------|
| 0 | **Spark** | starting form | base sprite, 2 moves + Attune |
| 1 | **Resonant** | align 3 strands | brighter palette, +stats, new move |
| 2 | **Attuned** | align 5 strands | ornament grows (horns→crown), signature upgrade |
| 3 | **Prismatic** | align all 7 + a hidden mote | near-final form, dual-tone move |
| ★ | **Unity-touched** | carry an `8` mote | secret white-edged form (ties to AUREON) |
| �​ | **Shadow-touched** | carry a `9` mote | secret dark form (ties to OUROBOS) |

> Numerology hooks: tier gates can use the Hunter's number (Red=1 needs 1-step
> aligns, Violet=7 needs the full set), and evolution windows can open on
> resonant turn-counts (e.g., a move charged for 3/6/9 turns).

### Data scaffold (when we wire it)
Add to each Hunter in `data.js`:
```js
evo: {
  tier: 0,
  line: ["Spark", "Resonant", "Attuned", "Prismatic"],
  gates: [0, 3, 5, 7],          // strands aligned to reach each tier
  setShards: [],                // colors currently Set on this Hunter
  motes: []                     // hidden 8 / 9 / 0 motes carried
}
```
The sprite renderer already varies by palette + ornament, so an evolved tier =
brighter palette + a bigger ornament + an extra accent. Cheap to show, big feel.

---

## B. BESTIARY — enemies & hidden bosses (inspirations, made ours)

The Seven are the *party*. The world is full of everything else. Tone targets:
**wonder + dread + uncanny machinery.** Pull from these, file off the serial
numbers, make them ours.

### Inspiration palette
- **NeverEnding Story 1** — the wolf **Gmork** (the Nothing's servant), the
  **Rockbiter**, **Morla** the ancient one, the **Sphinx gate** (eyes that judge
  the unworthy), **Falkor** the luckdragon (an ally, not an enemy).
- **NeverEnding Story 2** — **The Nothing as emptiness/forgetting**, **Xayide**
  and her **mechanical/giant automatons** (the Giants, the metal hand), wishes
  that cost memory. → our **0/Void** material and our **animatronic** enemies.
- **Labyrinth** — the shifting **maze**, **Helping Hands**, the **Fireys** (who
  pull themselves apart), the **oubliette**, the **Goblin King** (a charming,
  rule-bending boss). → puzzle-rooms + a trickster mid-boss.
- **Animatronic / "Five Nights" feel** — temple **guardian automatons** that sit
  dormant and *wake*; jerky, uncanny, stop-motion timing. Great for the
  pyramid's mechanical layer-keepers.
- **Sephiroth-style secret superboss** — an optional, late, brutally hard hidden
  boss with its own theme and a multi-phase fight. Ours below.

### Enemy classes (mooks → elites)
| Class | Feel | Source vibe |
|-------|------|-------------|
| **Mote-wisps** | weak color fragments, swarm | drifting spectrum bits |
| **Stone-kin** | slow, tanky, earthy | Rockbiter / golems |
| **Maze-tricksters** | dodge, swap positions, confuse | Labyrinth Fireys/goblins |
| **Automaton-keepers** | dormant→wake, telegraphed heavy hits, uncanny timing | animatronic / Xayide's giants |
| **Forgetlings** | drain your moves/"memory" (disable an ability) | the Nothing's reach |

### Hidden bosses (the deep cuts)
1. **GMORK-analogue — "The Hollow Wolf"** — the Void's hunter. Appears when you
   linger/forget; punishes hesitation. Servant of THE NOTHING (0).
2. **The Tail-Eater — OUROBOS (9)** — secret dark-cycle boss. A ring-arena fight:
   damage travels around the circle; the dragon's head chases its tail. Tie to
   the sub-octave 198Hz drone.
3. **AUREON (8) — the Unity mirror** — not evil; a *test*. It fights as all seven
   colors at once, rotating resonance every turn — you must read the wheel.
4. **THE NOTHING (0) — superboss (Sephiroth slot)** — multi-phase, optional,
   end-of-everything. Phase 1: erases the UI/your move names (forgetting).
   Phase 2: silence (0 Hz) — the music drops out. Final phase: you win not by
   damage but by **naming one true thing** (a remembered grain) — callback to
   the LORE_VAULT "one grain of sand" motif. Its own theme; beatable only after
   all Seven reach a high tier.

### Encounter design notes
- **Telegraph + timing** sells the animatronic dread: dormant pose → wind-up
  frame → strike. Reuse the sprite bob/blink system for "waking."
- **Puzzle-rooms** between battles (Labyrinth): tune a chamber to the right Hz /
  align a geometry to open the next layer — turns the theory into mechanics.
- **Falkor-type ally:** consider a non-combat companion that ferries you between
  layers and offers hints — warmth against the dread.

> Keep 8/9/0 bosses **hidden and optional** for now, exactly as their lore says:
> researched, measured, flexible. They're the endgame the tiers climb toward.
