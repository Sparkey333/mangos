# 🌊 Bit Claude's Ocean Dive 🐠

A tiny self-contained 8-bit browser mini-game. Stars an **aqua-recolored
"bit Claude"** scuba diver (the classic Claude blob, retinted from terracotta
to ocean teal and given a dive mask) dodging and collecting hand-drawn pixel
sea creatures — all rendered at matching low-res on a 320×180 canvas.

## Play

Just open `index.html` in any modern browser. No build step, no dependencies.

## How to play

- **Move:** Arrow keys / `WASD`, or click-and-drag (touch supported on mobile).
- **Collect** the friendly creatures for points:
  - 🐠 Clownfish — +10
  - ⭐ Starfish — +15
  - 🐚 Seashell — +20
- **Dodge** the hazards (each hit costs a life — you have 3):
  - 🪼 Jellyfish · 🐡 Pufferfish · 🦀 Crab · 🦑 Squid
- The current swim speed ramps up the longer you survive. High score is
  saved in `localStorage`.

## Notes

Every sprite — Claude and all the sea creatures — is defined as a small
character grid in the `<script>` block and painted pixel-by-pixel, so they
all share the same chunky 8-bit resolution. Sound effects are generated on the
fly with the Web Audio API. The whole game lives in one HTML file.
