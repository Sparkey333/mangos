# Temple Hunters — Prism Ascent 🔺🌈

A mobile-first pixel-art battle game. **Seven creatures, one per color of the
rainbow.** Each binds together one strand of a unified theory —
**color ↔ light frequency ↔ sound tone ↔ stone/gem ↔ sacred geometry ↔
chakra ↔ a stone layer of the Great Pyramid.** Pick a Hunter and climb the
seven layers of the pyramid; beat all seven guardians and the spectrum closes
back into white.

This is the **vertical slice / mock-up** — a real, playable loop you can hold
in your hand today, built to grow into the larger party game (and to sit
alongside the *Prism* screenplay world). See [`LORE.md`](LORE.md) for the full
seven-row mapping table.

---

## ▶ How to play it on your iPhone (primary target)

The whole game is plain HTML/CSS/JS — no build step, no app store, no Xcode.
Three ways, easiest first:

### 1. GitHub Pages (best — a real link you tap on your phone)
1. On GitHub: **Settings → Pages → Build from branch**, pick this branch and
   `/ (root)` (or the `temple-hunters` folder if Pages lets you).
2. Open the published URL in **Safari** on your iPhone.
3. Tap **Share → Add to Home Screen**. Now it launches **full-screen and works
   offline**, just like a native app. 🎮

### 2. Any quick web host
Drag the `temple-hunters/` folder into [netlify.com/drop](https://app.netlify.com/drop)
or run a static server and open the URL on your phone (same Wi‑Fi):
```bash
cd temple-hunters
python3 -m http.server 8080      # then visit http://<your-computer-ip>:8080
```

### 3. Straight off the Mac (your second target)
Just **double-click `index.html`** — it opens in Safari/Chrome and plays.
(Note: the offline service worker only activates over http/https, not `file://`,
but the game itself runs fine either way.)

---

## Why HTML now, native later (the "nest")

| Stage | Tech | Why |
|------|------|-----|
| **Now** | HTML5 + Canvas PWA | Test on iPhone *today*, zero cost, instant edits |
| **Next** | [Capacitor](https://capacitorjs.com) wrapper | Same code → a real Xcode app on your iPhone, App Store ready |
| **Later** | Your dedicated 8/16-bit engine | Once the design is proven, port the verified mechanics |

This ordering means every hour spent now carries forward — the data model in
`js/data.js` and the battle rules in `js/game.js` are engine-agnostic.

---

## File structure

```
temple-hunters/
├── index.html              # app shell + screens (title/select/codex/battle/end)
├── manifest.webmanifest    # PWA metadata (Add to Home Screen)
├── sw.js                   # service worker → offline play
├── icon.svg                # seven-layer pyramid app icon
├── css/
│   └── style.css           # mobile-first, notch-safe dark temple theme
├── js/
│   ├── data.js             # THE SEVEN — all lore + stats (the source of truth)
│   ├── sprites.js          # procedural 16×16 pixel-art creature renderer
│   ├── audio.js            # WebAudio solfeggio tones (you HEAR each frequency)
│   └── game.js             # screens + turn-based battle engine
├── LORE.md                 # the full unified-theory mapping table
└── README.md
```

## The seven (quick glance)

| # | Color | Hunter | Tone | Stone | Geometry | Pyramid layer |
|---|-------|--------|------|-------|----------|----------------|
| 1 | Red | PYROKK | 396 Hz | Garnet | Cube | Aswan red granite |
| 2 | Orange | EMBYRX | 417 Hz | Carnelian | Tetrahedron | Fayum basalt |
| 3 | Yellow | SOLARA | 528 Hz | Citrine | Octahedron | Giza core limestone |
| 4 | Green | VERDYN | 639 Hz | Emerald/Malachite | Icosahedron | Sinai copper |
| 5 | Blue | AZULON | 741 Hz | Sapphire/Turquoise | Dodecahedron | Tura casing |
| 6 | Indigo | INDIGOS | 852 Hz | Amethyst/Lapis | Merkaba | Dolerite pounders |
| 7 | Violet | VIOLETTE | 963 Hz | Selenite | Flower of Life | Alabaster + gold capstone |

## Combat (Pokémon-inspired, but its own thing)

- **Color-wheel type chart:** each Hunter is *strong* against the three colors
  ahead of it on the rainbow, *weak* to the three behind (`effectiveness()` in
  `data.js`). Resonance = ×1.5, dissonance = ×0.75.
- **Two move kinds:** a physical strike and a **signature tone move** that
  literally plays the creature's solfeggio frequency through WebAudio.
- **The climb:** 7 ascending guardians, each tougher than the last. Full heal
  between layers (kind for the MVP — tune later).

## Add an eighth creature

Append one object to `THE_SEVEN` in `js/data.js`. It appears in the roster, the
codex, the type chart, and battles automatically. Nothing else to touch.

---

> **A note on the theory:** the mappings here (solfeggio Hz, chakra colors,
> gemstones, Platonic-solid elements, and which stones were carried to Giza)
> are drawn from real traditions and real archaeology, then arranged
> *symbolically* for the game. It's a playable hypothesis, not a textbook —
> exactly the sandbox you asked for. Details and sources-to-chase are in
> [`LORE.md`](LORE.md).
