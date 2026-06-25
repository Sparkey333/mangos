# AetherForge

**An indie game studio command hub — desktop (`.dmg`) + web + mobile browser, from one codebase.**
Built with **Tauri 2 + Vite**. It holds the design docs, engine & asset references, the AI
automation playbook, and the legal guardrails for building an original, Nintendo-*genre*-inspired
game (the *Tunic* path) with a custom live electric-guitar + drums soundtrack.

> One dev → a hundred-strong. Claude-powered.

## What's inside

```
_AI-Projects/aetherforge/
├── index.html, src/            # the hub UI (vanilla JS + marked, dark "Hollow Knight" theme)
├── public/docs/                # all content, rendered in-app from Markdown
│   ├── 00-start-here.md
│   ├── 01-game-design-doc.md   # the upgraded, scoped Metroidvania design
│   ├── 02-engines-and-tools.md # three.js / Godot / Unity + runner-ups, repos, APIs
│   ├── 03-asset-pipeline.md    # sprites→3D→anim→audio→voice: tools, AI, free libs, APIs
│   ├── 04-mac-setup-and-apps.md# brew installs, dmg build, web deploy, API keys
│   ├── 05-legal-cleanroom.md   # the rules that keep you clear of Nintendo's lawyers
│   ├── 06-scaling-with-ai.md   # 1 dev → 100 with Claude + pipelines
│   ├── 99-backup-log.md        # provenance / backup hygiene
│   └── archive-original-feasibility.md  # the source note this grew from
├── src-tauri/                  # Tauri 2 (Rust) desktop + mobile shell
├── scripts/setup-mac.sh        # one-command local setup
└── app-icon.svg                # icon source (run `npm run icons` to generate the set)
```

## Quickstart (on your Mac)

```bash
bash scripts/setup-mac.sh
npm run dev            # web hub at http://localhost:1420
npm run desktop:dev    # native desktop window
npm run desktop:build  # macOS .dmg  → src-tauri/target/release/bundle/dmg/
npm run build          # static web build (deploy anywhere, works on mobile browsers)
```

Full walkthrough: open the hub and read **Start Here** → **Mac Setup & Apps**.

## Why a Linux note in a Mac project?

This was scaffolded in a cloud sandbox, so the macOS `.dmg`/`.app` is the one step that must run
on your Mac (Apple requirement). Everything is pre-wired for it.

## Tech
Tauri 2 · Vite 5 · marked · (game engine TBD — **Godot 4 recommended**, see *Engines & Tools*)

## License
Your code/content. Third-party assets must be tracked in a `CREDITS.md` — see *Legal Clean-Room*.
