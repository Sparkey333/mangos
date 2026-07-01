# Mac Setup & Apps — Get It All Running Locally

How to pull this onto your Mac, install every tool, build the `.dmg`, deploy the web version, and
grab every API key. **Important reality:** this hub was assembled in a Linux cloud sandbox, so it
**can't reach your Mac or build a `.dmg` remotely** — Apple only lets you package `.dmg`/`.app`
**on macOS**. These are the steps you run locally. Everything is already wired for them.

---

## 0. Get the project onto your Mac (into `~/ansom/_AI-Projects`)

```bash
mkdir -p ~/ansom/_AI-Projects && cd ~/ansom/_AI-Projects
# Clone your repo and grab this branch:
git clone https://github.com/Sparkey333/mangos.git
cd mangos
git checkout claude/nintendo-clone-feasibility-7i3usp
# The app lives here:
cd _AI-Projects/aetherforge
```

(That mirrors the exact path you wanted: `~/ansom/_AI-Projects/.../aetherforge`.)

---

## 1. One-command setup

```bash
bash scripts/setup-mac.sh
```

It installs Node + Rust (via Homebrew), runs `npm install`, builds the web app, and preps icons.
Then:

```bash
npm run dev            # hub in your browser at http://localhost:1420
npm run desktop:dev    # hub as a native desktop window (live reload)
npm run desktop:build  # the macOS .dmg → src-tauri/target/release/bundle/dmg/
```

---

## 2. Install the toolchain (Homebrew)

**Homebrew** is the Mac package manager — <https://brew.sh>:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then the studio toolkit (install what you need):

```bash
# Core dev
brew install node rust git
brew install --cask visual-studio-code        # or:  brew install --cask cursor

# Game engines
brew install --cask godot                      # ⭐ recommended engine
brew install --cask unity-hub                  # Unity (install editor from the hub)
brew install --cask blender                    # 3D / animation / rendering

# 2D art & pixel
brew install --cask krita
brew install --cask aseprite                   # (if licensed) or build LibreSprite
brew install --cask tiled                      # tilemap editor

# Audio (your soundtrack)
brew install --cask reaper                     # DAW
brew install --cask audacity                   # recording/editing

# Helpful extras
brew install --cask github                     # GitHub Desktop
brew install librsvg                            # lets setup script rasterize the app icon
```

**See what you already have** (since I can't):

```bash
brew list && brew list --cask        # installed brew packages
ls /Applications                     # everything installed on your Mac
```

Direct downloads if you prefer not to use brew: Godot <https://godotengine.org/download> ·
Unity <https://unity.com/download> · Blender <https://www.blender.org/download> ·
Aseprite <https://www.aseprite.org> · Reaper <https://www.reaper.fm/download.php>

---

## 3. Build & sign the `.dmg`

```bash
npm run icons          # generate app icons (needs app-icon.png — see src-tauri/icons/README.md)
npm run desktop:build  # → src-tauri/target/release/bundle/dmg/AetherForge_0.1.0_aarch64.dmg
```

To distribute without Gatekeeper warnings you'll eventually want an **Apple Developer account**
($99/yr <https://developer.apple.com>) to **codesign + notarize**. For personal use, the unsigned
`.dmg` runs fine (right-click → Open the first time).

---

## 4. Deploy the web / mobile-browser version

The web build is a plain static site — host it free, instantly usable on any phone browser:

```bash
npm run build          # outputs ./dist
```

- **Vercel** <https://vercel.com> — `npx vercel deploy ./dist`
- **Netlify** <https://www.netlify.com> — drag `./dist` onto the dashboard, or `npx netlify deploy`
- **GitHub Pages** <https://pages.github.com> — push `./dist` to a `gh-pages` branch
- **Cloudflare Pages** <https://pages.cloudflare.com>

(Relative asset paths are already configured, so it works under any subpath.)

---

## 5. Where to get API keys (for the AI pipeline)

| Service | Get a key | Used for |
|---|---|---|
| **Anthropic (Claude)** | <https://console.anthropic.com> | code, agents, writing, QA |
| **OpenAI** | <https://platform.openai.com> | alt LLM / image |
| **Stability AI** | <https://platform.stability.ai> | Stable Diffusion API |
| **Scenario** | <https://www.scenario.com> | on-style game assets + training |
| **Meshy** | <https://www.meshy.ai> | text/image → 3D (REST API) |
| **Tripo** | <https://www.tripo3d.ai> | fast 3D + rigging API |
| **PixelLab** | <https://www.pixellab.ai/pixellab-api> | pixel-art animation API |
| **Leonardo** | <https://leonardo.ai> | game image gen API |
| **ElevenLabs** | <https://elevenlabs.io> | AI voice API |

> **Key hygiene:** never commit keys. Put them in a local `.env` (already git-ignored) and load
> them in your scripts. Rotate any key that leaks.

---

## 6. Mobile app shells (later, optional)

Same Tauri project also builds native iOS/Android:

```bash
npm run ios:dev        # needs Xcode
npm run android:dev    # needs Android Studio + SDK
```

For the **game** on mobile, you'll export from Godot/Unity directly rather than via this hub.
