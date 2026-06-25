# AetherForge — Studio Hub

**One dev → a hundred-strong. Claude-powered indie game studio, in one app.**

This is your command center. It started as a feasibility note ("which old-Nintendo-style game
could I realistically build and sell?") and is now a real, buildable **Tauri 2 + web app** that
runs on **desktop (macOS `.dmg`), the web, and mobile browsers** — all from this single project.

Everything you asked for lives in the left sidebar:

| Section | What's in it |
|---|---|
| **Game Design Doc** | The upgraded design — a Hollow-Knight-quality, *show-don't-tell*, boss-driven Metroidvania, simplified to a shippable first slice. |
| **Legal Clean-Room** | The hard rules that keep you on the *Tunic* side of the line and far away from Nintendo's lawyers. |
| **Engines & Tools** | three.js vs Godot vs Unity — plus 2–3 runner-ups each, with links, GitHub repos, and APIs. |
| **Asset Pipeline** | Every way to make sprites, backgrounds, tilesets, 3D models, animation, audio & voice — traditional tools, AI generators, free libraries, and automation APIs. |
| **1 Dev → 100 (AI)** | How to turn yourself into a virtual studio with Claude + agent pipelines. |
| **Mac Setup & Apps** | Install everything on your Mac (Homebrew commands + links), build the `.dmg`, deploy the web build, and where to grab every API key. |
| **Original Feasibility** | The archived source note this all grew from. |

---

## The one thing to internalize first

You **cannot** clone and sell an actual Nintendo game — Nintendo is the most aggressive IP
enforcer in the industry. But **game mechanics and genres are not copyrightable.** *Tunic* legally
plays just like *Zelda* with 100% original art, story, and music. **That is the entire plan:**
build an *original* game in a Nintendo-defined genre, and let your custom electric-guitar + drums
soundtrack be the thing nobody else has. Full rules in **Legal Clean-Room**.

---

## How to run this hub

```bash
# From this project folder on your Mac:
bash scripts/setup-mac.sh     # installs deps, builds the web app, preps icons

npm run dev            # web app at http://localhost:1420 (also works in a phone browser on your LAN)
npm run desktop:dev    # the same hub as a native desktop window
npm run desktop:build  # produces the macOS .dmg  -> src-tauri/target/release/bundle/dmg/
```

The web build in `./dist` is a plain static site — drop it on Vercel, Netlify, or GitHub Pages and
it's instantly usable from any phone browser. Same content, three delivery channels. See
**Mac Setup & Apps** for the full walkthrough.

---

## Status & honest scope

- ✅ This hub (docs + Tauri/web app) is **done and committed** to your repo branch.
- ✅ All references, links, engine options, and asset tools are filled in.
- ⏳ The **game itself** is the next build — start with the vertical slice in the **Game Design Doc**.
- ⚠️ The macOS `.dmg` must be built **on your Mac** (Apple only lets you package `.dmg`/`.app` on
  macOS). This hub was assembled in a Linux cloud sandbox, so the final desktop build is your
  one local step. Everything is wired and ready for it.
