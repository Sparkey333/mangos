# 🕹️⚡ Awakening Arcade

A personal **learning OS** for two passions:

1. **Game Dev Through the Ages** — build games the way they were built in the 80s, 8-bit, 16-bit, and early-2000s
   eras, carry that craft onto modern phones/PCs, and aim at your own nostalgia **console line** + a 90s-YMCA-style
   community "third place."
2. **Electrical — Theory to Trade** — the real history of electricity (including the "forgotten"/occult ideas, handled
   with a skeptic's flashlight), down to a **licensed electrician earning money in Colorado Springs, CO**, with real
   wage ranges, timeframes, and accredited degree pathways.

Everything is organized around the **three pillars of career evolution**:

> 📚 **Coursework** (learn it) · 💼 **Career** (get hired for it) · ⚡ **Sidegigz** (ship small & earn now)

Every section → subsection → checkable subtasks, plus 🔁 **Reinforcement** that loops back on what you just learned and
earlier sections — rarely on what comes next (spaced repetition that builds, not overwhelms).

## How to run it

It's a **self-contained offline web app** — no install, no build, no server.

- **Just open `curriculum/index.html` in any browser** (double-click it), on any OS.
- Works on desktop and mobile.

## Features

- **Two full tracks** with eras, objectives, the 3 pillars, tasks, resources/course links, and reinforcement.
- **Progress tracking** — check off tasks; section, track, and overall progress bars update live.
- **📖 My Book** — a write-along self-help book with chapters, autosave, and Markdown export. Send any subsection to the
  book as a chapter prompt.
- **🌌 Journal** — dated "awakening" entries with mood.
- **🎬 Asset Vault** — log coursework notes, images, clips, and course ideas to repurpose into Udemy/YouTube.
- **🔎 Find related jobs** — one-click Indeed searches seeded from each subsection.
- **💾 Backup / 📂 Restore** — export/import all your data as a JSON file to move between devices.

## Privacy

100% local. Your progress, book, journal, and assets are stored **only in your browser on your device** and are never
uploaded. Clearing browser data erases them — **back up regularly** with the 💾 button.

## Extending the curriculum

The curriculum is plain data:

- `js/data/gamedev.js`
- `js/data/electrical.js`

Each track is `{ id, title, tagline, accent, intro, sections: [...] }`; each section has `sub` subsections carrying
`pillars { coursework, career, sidegigz }`, `tasks[]`, `resources[]`, and `reinforce[]`. Add to these files and the UI
picks them up automatically. New tracks: copy the pattern and `window.TRACKS.push(...)`.

### Planned expansions (same data model)

- Certification & course directories with deep links and price/accreditation tags.
- Location-aware course finder (in-person near Colorado Springs).
- Career-fit profiling that records secure local data to recommend next steps.
- Auto-generated course outlines (for Udemy/YouTube) from completed sections.

## Disclaimer

Wage ranges, course costs, timelines, and licensing rules are **ballpark guidance** to point you in the right
direction — always verify current figures and requirements with the official sources linked in-app (CO DORA Electrical
Board, ABET, schools, NEC). **Never perform live electrical work untrained or unlicensed.**
