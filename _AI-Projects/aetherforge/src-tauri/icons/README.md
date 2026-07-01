# Icons

These are generated, not committed. Before building the desktop `.dmg` (or mobile apps),
generate the icon set from the project's source art:

```bash
# 1. Make a 1024x1024 PNG from app-icon.svg (any of these works):
#    - open app-icon.svg in any editor and export PNG, or
#    - brew install librsvg && rsvg-convert -w 1024 -h 1024 app-icon.svg -o app-icon.png
# 2. Generate every required icon (png/icns/ico) into this folder:
npm run icons   # == tauri icon ./app-icon.png
```

The web build (`npm run dev` / `npm run build`) does NOT need these — only the
desktop/mobile bundle does.
