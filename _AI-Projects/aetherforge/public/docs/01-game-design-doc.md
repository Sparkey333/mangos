# Game Design Doc — "Project Aether" (working title)

> Upgraded from the original feasibility note into a real, buildable design.
> Target: the **craft and feel of *Hollow Knight***, told the way Hollow Knight tells it —
> almost no text boxes, everything *shown* through world, animation, and music — but **scoped
> down hard** so a solo dev (you) + Claude-powered pipelines can actually ship a first slice.

---

## 1. Vision in one sentence

*A hand-built 2D Metroidvania where a lone wanderer descends through a dead, beautiful world,
re-learning lost movement and combat one ability at a time — and where the **music (your live
electric guitar + drums)** is the second main character.*

## 2. Why this genre (recap, decided)

Metroidvania won the ranking in the feasibility analysis because it is: (1) the most
**solo-achievable** premium genre, (2) the most **proven on Steam**, (3) the most
**music-forward** — boss themes and exploration ambience are *made* for live guitar/drums, and
(4) the cleanest legally. Closest precedent to your exact ambition: **Axiom Verge** — one person,
Metroid-style, self-composed soundtrack, commercially successful.

## 3. Design pillars (every decision serves these)

1. **Show, don't tell.** Target **< 200 words of dialogue in the whole first slice.** Story is
   delivered by environment, silent NPC animation, item-found pantomimes, and music — *not* text
   boxes. (Hollow Knight's entire opening teaches you the world with almost no words.)
2. **Bosses are the chapters.** Progress is gated and remembered by **boss fights**, each with a
   signature musical theme. Beating a boss = a new traversal ability = new map opens. Three
   bosses in the first slice.
3. **The map is the story.** One interconnected, hand-drawn world (no procedural gen). Getting
   lost and finding a shortcut back *is* the gameplay.
4. **Music as mechanic, not wallpaper.** Adaptive layered audio: an exploration bed that adds a
   guitar lead when enemies engage and a full drum-driven theme in boss arenas. Your soundtrack
   is the marketing hook.
5. **Game feel over content volume.** A small world that feels *incredible* (tight controls,
   readable animation, satisfying hit-stop) beats a big world that feels cheap.

## 4. Core loop

```
Explore hand-built rooms  →  hit a locked gate / unbeatable gap
   →  find the boss that guards the missing ability
   →  learn the boss's pattern (death is cheap, retry is instant)
   →  win → gain ability (dash / double-jump / wall-cling)
   →  backtrack: the ability opens 3–4 previously-blocked paths
   →  repeat, the map blooming outward
```

## 5. Moveset & progression (first slice)

| Unlock | Source | Opens |
|---|---|---|
| Base: run, jump, attack, heal | start | everything |
| **Dash** | Boss 1 | gaps + dash-through gates |
| **Wall-cling / wall-jump** | Boss 2 | vertical shafts |
| **Air-dash or double-jump** | Boss 3 | the path to the slice's finale |

Keep it to **3 abilities.** That is enough to make a world feel like a Metroidvania. Resist adding
a fourth until the slice ships.

## 6. Combat & "game feel" checklist (this is where HK-quality lives)

- **Hit-stop**: freeze 2–4 frames on every successful hit. Single biggest "feels good" trick.
- **Coyote time + input buffering** on jumps (forgive ~6 frames). Players *feel* fairness.
- **Knockback you can read**, screen-shake tuned *low* (taste, not seizure).
- **Generous i-frames** on dash. Dash is the dodge.
- **Telegraphs**: every enemy/boss attack has a clear wind-up pose + an audio cue. Difficulty
  comes from *reading*, not from being cheap.
- **Instant respawn at the boss door.** Friction kills boss-rush joy.

## 7. Boss design philosophy (the heart of the show-don't-tell promise)

Each boss is a **3-phase escalation** with a musical arc:

1. **Phase 1** — teach 2 attacks. Guitar enters clean.
2. **Phase 2** — add a third attack + speed. Drums kick in.
3. **Phase 3** — desperation pattern. Full theme, distortion, double-time.

The *story* of the fight (who this creature was, why it guards this) is told by its arena, its
animation, and a wordless beat *after* the win — never a paragraph. Write the boss's biography for
yourself; show 10% of it to the player.

## 8. World structure (first slice)

- **1 hub + 3 biomes**, each themed to a boss, each ~8–12 rooms. ~30–40 rooms total.
- Interconnected with shortcuts that unlock from the far side (the Dark Souls/HK loop-back).
- One save bench per biome (rest = heal + save + refill; HK-style).
- A silent NPC or two at the hub who react in pantomime to your progress.

## 9. Art direction

- **2D, hand-painted-feeling, dark + luminous** (deep blues/teals with one warm accent — the same
  palette as this hub app). Atmosphere over detail.
- **Silhouette-first** character/enemy design: readable at a glance, distinct shapes per threat.
- **Parallax depth** (3–5 layers) for cheap, gorgeous environments.
- Animation budget is the real cost — keep the playable cast small, animate it *well*. See the
  **Asset Pipeline** doc for AI-assisted and free sources.

## 10. Audio — your differentiator

- **Adaptive layered stems** (compose in your DAW, export as loopable OGG): `ambient_bed`,
  `+guitar_lead` (combat), `+drums_full` (boss). The engine cross-fades layers by game state.
- **One signature boss theme per boss**, recorded live (guitar + drums = your sound).
- **Diegetic stingers**: ability-gained flourish, secret-found chord. Tiny, memorable.
- This is also your **trailer and wishlist hook** — lead every marketing beat with the music.

## 11. Narrative delivery (the < 200 words rule)

- **Environmental storytelling**: ruined architecture, posed corpses, murals.
- **Item pantomime**: finding an ability plays a short wordless animation.
- **Music as narration**: motif recurs, transformed, when a truth is revealed.
- Reserve actual text for: 1 opening line, item names, and a 1-line ending. That's it for v1.

## 12. MVP — the "vertical slice" (ship THIS first)

The slice that proves the game and earns Steam wishlists:

- **1 biome, 1 boss, 1 ability unlock**, ~10 rooms, ~15–20 minutes of play.
- Full game-feel pass (hit-stop, coyote time, adaptive music on that one boss).
- A title screen + the opening line + one save bench.
- **Goal:** a 60-second trailer that makes the music + feel undeniable → put up a Steam "Coming
  Soon" page → gather wishlists *before* building the other two biomes.

## 13. Milestones

| # | Milestone | Definition of done |
|---|---|---|
| M0 | **Greybox movement** | run/jump/dash in a blockout room, coyote time + buffering in |
| M1 | **Combat feel** | 1 enemy, hit-stop, i-frames, death/respawn loop |
| M2 | **Vertical slice** | 1 biome + 1 boss + adaptive music + title → *trailer-ready* |
| M3 | **Steam page** | capsule art, trailer, "Coming Soon" live, wishlists opening |
| M4 | **Full slice → 3 biomes** | scale the proven loop ×3, then content-complete |
| M5 | **Polish + ship** | options, accessibility, controller, localization-ready strings |

## 14. Success criteria

- **Feel test:** a stranger plays 5 minutes and says "this feels *good*" unprompted.
- **Music test:** they hum/notice the boss theme afterward.
- **Wishlist test:** the trailer converts — measurable on the Steam page before full production.

## 15. Open decisions (pick before M2)

- Engine: **Godot 4** (recommended for 2D solo) vs Unity vs a web/three.js build — see **Engines & Tools**.
- Title & protagonist identity (keep it ownable, trademark-clean — see **Legal Clean-Room**).
- Exact 3 abilities (dash is locked in; pick the other two).

---

## 16. ▶ The playable slice exists (start here)

A Godot 4 vertical-slice project is now in the repo at **`_AI-Projects/aether-game/`**. It
greyboxes M0–M1: a player with **coyote time, jump buffering, variable jump height, and a
dash with i-frames**, a follow camera, a greybox room, and the **adaptive guitar/drums music
manager** (ambient → combat → boss) wired to a proximity enemy and a boss zone.

```bash
# Install Godot 4.3+ (brew install --cask godot), then:
#   Godot → Import → select _AI-Projects/aether-game/project.godot → Edit → press ▶
```

Controls: move `A`/`D`, jump `Space`, dash `Shift`. Walk up to the dummy or into the orange
zone to *hear* the music layers cross-fade. Tunables are at the top of `scripts/player.gd`.
Drop your guitar/drums OGG loops in `aether-game/audio/` (see its README) to bring it to life.
