# 1 Dev → 100: Turning Yourself Into a Virtual Studio with Claude

Your vision: *"one team turned 100 team or more with this app and Claude power."* Here's the
realistic version — what AI can genuinely staff, what stays human, and the actual tools/APIs to
wire it together.

> **The honest frame:** AI doesn't give you 100 *people* — it gives you ~100 *person-hours of
> grunt work compressed into one person's day*, across many roles, **as long as you stay the art
> director.** The studios shipping good AI-assisted games use AI for **volume** and keep a human
> on **taste, game-feel, and music.** That's exactly your edge: the guitar/drums and the design
> sense are yours; the asset-grind and boilerplate get automated.

---

## The "virtual departments" you can staff with AI

| Department | What AI does | Tool / API |
|---|---|---|
| **Concept art** | mood boards, character/enemy concepts, biome looks | Midjourney, Firefly, Leonardo, Scenario |
| **Sprite/asset production** | mass-produce on-style assets from a trained model | Scenario API, PixelLab API, Retro Diffusion |
| **3D + animation** | gen base meshes, auto-rig, mocap | Meshy/Tripo API, Mixamo, Cascadeur, DeepMotion |
| **Programming** | gameplay code, tools, shaders, refactors | **Claude Code** (this CLI), Claude API |
| **Level scripting** | boilerplate, enemy placement passes, data tables | Claude + Godot/LDtk file formats |
| **Writing** | item descriptions, lore bible (you cut it to <200 shown words) | Claude API |
| **QA / playtest notes** | bug triage, balance spreadsheets, edge-case hunts | Claude + logs |
| **Marketing** | Steam copy, trailer scripts, social posts, localization | Claude API |
| **Producer** | task breakdowns, milestone tracking, this very hub | Claude + AetherForge |

**Stays human (your moat):** music (live guitar/drums), art direction & final taste, game feel,
the core design decisions, and the *curation* of everything the AI generates.

---

## The Claude layer (the "power" you meant)

- **Claude Code** — agentic coding in your terminal/IDE; writes and edits the game code, builds
  tools, runs your pipelines. <https://claude.com/claude-code> · Docs <https://docs.claude.com/en/docs/claude-code>
- **Claude API / Anthropic SDK** — script your own pipelines (asset captioning, dialogue gen,
  QA triage, batch jobs). Docs <https://docs.claude.com> · Console/keys <https://console.anthropic.com>
- **Claude Agent SDK** — build custom multi-step agents (e.g. an "asset intake" agent that
  captions, tags, and files every generated sprite). <https://docs.claude.com/en/api/agent-sdk/overview>
- **Subagents & workflows** — fan out parallel work (one agent per biome, one per boss) and
  verify results. Available right inside Claude Code.

---

## Automation glue (turn tools into pipelines)

- **ComfyUI** — node-based Stable Diffusion you can drive **headless via its API** for batch sprite
  generation. Repo <https://github.com/comfyanonymous/ComfyUI>
- **Blender Python (`bpy`)** — script batch model cleanup, auto-export, render sprite sheets from
  3D. Docs <https://docs.blender.org/api/current/>
- **Godot headless export** — automate builds from the command line (`godot --headless --export-release`). Docs <https://docs.godotengine.org/en/stable/tutorials/export/exporting_basics.html>
- **GitHub Actions** — CI to auto-build the game + this hub on every push. <https://github.com/features/actions>
- **n8n** — open-source visual workflow automation to chain APIs (gen → tag → commit → notify).
  Site <https://n8n.io> · Repo <https://github.com/n8n-io/n8n>
- **Asset-gen APIs to orchestrate:** Meshy, Tripo, Scenario, PixelLab, Stability
  (<https://platform.stability.ai>), ElevenLabs, OpenAI/Anthropic.

---

## A concrete "studio in a box" example

```
1. You sketch one enemy + write a 1-line brief.
2. Claude (Agent SDK) expands the brief → prompt + style tags.
3. ComfyUI/Scenario API generates 20 variations on your trained style model.
4. A Claude agent captions/tags them, drops the best 3 in /assets/review.
5. You pick 1 (taste = human).  PixelLab API animates it.
6. Blender Python renders the sheet; Godot headless re-imports.
7. GitHub Actions builds a playable web preview; you review it in THIS hub.
```

One person ran a 7-stage pipeline that would've been a small team. That's the "100" — **compressed
labor, not replaced judgment.**

---

## Guardrails (so you ship a gem, not slop)

- **One trained style model**, ruthlessly curated → cohesion. Mixed raw AI output looks cheap.
- **Game feel is hand-tuned**, never generated. It's the difference-maker (see the GDD checklist).
- **Your music is recorded, not generated.** It's the brand.
- **License-check every tool's commercial terms** before shipping its output (see **Legal Clean-Room**).
- **Disclose AI use where stores require it** (Steam has an AI-disclosure field).
- **Quality bar > output volume.** Ship the vertical slice and let *feel* sell it.
