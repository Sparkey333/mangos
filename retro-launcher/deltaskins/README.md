# Delta Skins

These are starter [Delta](https://github.com/rileytestut/Delta) controller skins
for the GBA, for users who prefer to run their library in the native Delta app
(the hand-off path) rather than the in-app WASM emulator.

## What a `.deltaskin` is
A `.deltaskin` file is just a **zip** containing:
- `info.json` — button hit-zones, screen output frame, mapping size (see `gba-classic/`)
- shell art — a `.pdf` (vector, preferred) or `@1x/@2x/@3x` PNGs

## Build one
```bash
cd deltaskins/gba-classic
zip -r ../RetroLauncher-Classic.deltaskin info.json shell-classic.pdf
```
Then AirDrop / open the `.deltaskin` on your iPhone → Delta imports it.

## Notes
- `shell-classic.pdf` art is a placeholder you supply (or generate at
  <https://deltaskins.dev>). The `info.json` button map is ready to use.
- Format reference: <https://noah978.gitbook.io/delta-skins>
- The **in-app** skin (`src/components/GBASkin/`) is independent of these and adds
  the edge-slip / edge-pop haptics that the native Delta skins can't.
