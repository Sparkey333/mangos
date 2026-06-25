# Engines & Tools — Your Options (with runner-ups, repos & APIs)

You named **three.js, Godot, Unity, "all the things."** Here's the honest map: the three you
named, what each is actually *for*, and **2–3 runner-ups per lane** so you have variety. Links go
to the homepage, the **GitHub repo**, and the **API/docs** where one exists.

> **Bottom line for *your* game (a 2D Metroidvania, music-forward, Steam-first):**
> **Godot 4** is the recommendation — free, no royalties, best-in-class 2D, exports to desktop +
> mobile + web. Unity is the proven AAA-indie path (Hollow Knight itself is Unity). three.js is
> the answer only if you want it to *run in the browser as the primary platform* or go 3D/stylized-3D.

---

## Lane A — Web-native / 3D-in-the-browser

### ⭐ three.js (the one you named)
The standard WebGL/WebGPU 3D library for the browser. Not a full game engine — it's a rendering
library you build a game *on*. Perfect when "runs in any browser, including mobile" is the whole
point, or for 3D/stylized worlds.
- Site: <https://threejs.org> · Repo: <https://github.com/mrdoob/three.js> · Docs/API: <https://threejs.org/docs/> · Examples: <https://threejs.org/examples/>
- Pairs beautifully with **React Three Fiber** (declarative three.js): <https://github.com/pmndrs/react-three-fiber> + the **drei** helpers <https://github.com/pmndrs/drei>.
- **Best for:** 3D/2.5D, browser-first delivery, embedding in this very Tauri/web hub.
- **Weak for:** heavy 2D platformer tooling (no built-in level editor/physics-tuned-for-2D) — you assemble more yourself.

**Runner-ups in this lane:**
1. **Babylon.js** — fuller-featured web engine (built-in physics, editor, GUI). Site <https://www.babylonjs.com> · Repo <https://github.com/BabylonJS/Babylon.js> · Docs <https://doc.babylonjs.com>.
2. **PlayCanvas** — web engine with a cloud visual editor; ships real 3D games to browser. Site <https://playcanvas.com> · Repo <https://github.com/playcanvas/engine>.
3. **PixiJS** — the fastest **2D** WebGL renderer (if you want a 2D Metroidvania *in the browser*). Site <https://pixijs.com> · Repo <https://github.com/pixijs/pixijs>.

---

## Lane B — 2D-first game engines (best fit for this project)

### ⭐ Godot 4 (recommended)
Free, open-source, **zero royalties or fees, ever**. Outstanding 2D engine (dedicated 2D renderer,
tilemaps, physics, animation, a built-in scene editor). Exports to Windows/macOS/Linux, **Web
(WASM)**, Android, and iOS. GDScript is python-like and fast to learn; C# supported too.
- Site: <https://godotengine.org> · Repo: <https://github.com/godotengine/godot> · Docs/API: <https://docs.godotengine.org> · Asset Library: <https://godotengine.org/asset-library/asset>
- **Best for:** exactly your game — solo 2D Metroidvania, ship to Steam + web + mobile.
- **Why over Unity:** no licensing drama, lighter, opens instantly, the 2D workflow is more direct.

**Runner-ups in this lane:**
1. **GameMaker** — battle-tested 2D engine; *Hyper Light Drifter*, *Undertale*, *Katana ZERO* shipped on it. Site <https://gamemaker.io>.
2. **Defold** (free, by the Defold Foundation/King) — tiny builds, great for 2D + mobile. Site <https://defold.com> · Repo <https://github.com/defold/defold>.
3. **LÖVE (Love2D)** — minimalist Lua 2D framework if you like coding close to the metal. Site <https://love2d.org> · Repo <https://github.com/love2d/love>.
4. **GDevelop** — no-/low-code 2D, exports web + mobile, friendly start. Site <https://gdevelop.io> · Repo <https://github.com/4ian/GDevelop>.

---

## Lane C — Big general-purpose engines (2D *and* 3D)

### ⭐ Unity (the one you named) — the proven indie-to-AAA path
The most-shipped indie engine. **Hollow Knight, Ori, Cuphead, Cassette Beasts** are all Unity.
Huge **Asset Store**, massive tutorial ecosystem, exports everywhere (desktop, console, mobile,
web). Trade-off: heavier, and its 2023 runtime-fee episode spooked devs (since revised) — read the
current pricing before committing.
- Site: <https://unity.com> · Manual/API: <https://docs.unity3d.com> · Asset Store: <https://assetstore.unity.com> · Learn: <https://learn.unity.com>
- **Best for:** if you want the biggest asset/tutorial ecosystem and a clear console path, and don't mind the weight.

**Runner-ups in this lane:**
1. **Unreal Engine 5** — gold-standard 3D/visuals; overkill for 2D but unmatched for 3D ambition. Site <https://www.unrealengine.com> · Repo (request access) <https://github.com/EpicGames/UnrealEngine>.
2. **Bevy** — modern **Rust** engine (data-oriented/ECS); pairs naturally with your Rust/Tauri stack. Site <https://bevyengine.org> · Repo <https://github.com/bevyengine/bevy>.
3. **Stride** — open-source C# engine (a Unity-like alternative). Site <https://www.stride3d.net> · Repo <https://github.com/stride3d/stride>.
4. **MonoGame** — code-first C# framework; *Celeste* and *Stardew Valley* shipped on it. Site <https://monogame.net> · Repo <https://github.com/MonoGame/MonoGame>.

---

## The desktop/web shell (what this hub is built on)

You wanted "dmg + web/mobile browser for all." That's the **app shell** layer, separate from the
game engine. Your game embeds or links from it.

### ⭐ Tauri 2 (what AetherForge uses)
Rust-based, tiny binaries, builds **macOS `.dmg`, Windows, Linux, iOS, and Android** from one
codebase (confirmed: `tauri ios dev` / `tauri android dev`). Web frontend + Rust backend.
- Site: <https://tauri.app> · Repo: <https://github.com/tauri-apps/tauri> · Docs: <https://v2.tauri.app> · Mobile guide: <https://v2.tauri.app/develop/>

**Runner-ups:**
1. **Electron** — heavier but the most mature/desktop-proven (VS Code, Discord). Site <https://www.electronjs.org> · Repo <https://github.com/electron/electron>.
2. **Wails** — Go + web, Tauri-like. Site <https://wails.io> · Repo <https://github.com/wailsapp/wails>.
3. **Capacitor** — wrap any web build into iOS/Android shells. Site <https://capacitorjs.com> · Repo <https://github.com/ionic-team/capacitor>.

---

## Quick decision table

| If your priority is… | Pick | Backup |
|---|---|---|
| Solo 2D Metroidvania, Steam-first (your case) | **Godot 4** | GameMaker |
| Runs in any browser as the primary platform | **three.js / PixiJS** | PlayCanvas |
| Biggest ecosystem + console path | **Unity** | Unreal (3D) |
| Stay in the Rust/Tauri world end-to-end | **Bevy** | Godot (GDScript) |
| Desktop/mobile app shell for tools & launchers | **Tauri 2** | Electron |

## Recommended starting stack (for Project Aether)

> **Godot 4** (game) → export **Web build** you can preview inside this **Tauri 2** hub → **Steam**
> via Godot's native export → later **Switch/mobile** ports. One language to learn (GDScript), zero
> engine fees, every target platform covered.
