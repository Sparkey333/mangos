# Asset Pipeline — Every Way to Make the Art, Animation, Audio & Voice

You asked for *"any and all references… sprites, images, backgrounds, 3D models, animations… while
training, learning, tracing, and automating."* Here it is, by asset type. Each section lists
**traditional tools**, **AI generators (with APIs where they exist)**, and **free asset libraries**
so you can mix hand-made + generated + licensed. Links go to homepages, **GitHub repos**, and
**APIs** for automation.

> **The "trace & learn" path, done right (read first):** Learning by tracing and studying real art
> is how every artist levels up — keep those studies *private practice*. What you **ship** must be
> your own or properly licensed. With AI tools, **train style models on your own art** (or CC0/
> licensed art), and always check each tool's **commercial-use license** before shipping its output.
> Details and the legal line are in **Legal Clean-Room**.

---

## 1. Pixel art & sprites (characters, enemies, items)

**Traditional / hand tools**
- **Aseprite** — the industry-standard pixel + animation editor (paid; source is open). Site <https://www.aseprite.org> · Repo <https://github.com/aseprite/aseprite>
- **LibreSprite** — free fork of Aseprite. <https://libresprite.github.io> · Repo <https://github.com/LibreSprite/LibreSprite>
- **Pixelorama** — free, open-source, made in Godot. <https://orama-interactive.itch.io/pixelorama> · Repo <https://github.com/Orama-Interactive/Pixelorama>
- **Piskel** — free, browser-based. <https://www.piskelapp.com> · Repo <https://github.com/piskelapp/piskel>
- **Krita** — free pro painting app (great for higher-res 2D too). <https://krita.org> · Repo <https://invent.kde.org/graphics/krita>

**AI generators (sprite-/game-specialized)**
- **PixelLab** — AI pixel-art *with skeleton-based animation* (walk/run/attack, 8-direction), and an **API**. <https://www.pixellab.ai> · API <https://www.pixellab.ai/pixellab-api>
- **Retro Diffusion** — true pixel-art model incl. an **RD Animation** model for sprite sheets. <https://retrodiffusion.ai>
- **Scenario** — game-asset generation with **trainable custom style models** + **API** (keep your look consistent across hundreds of assets). <https://www.scenario.com>
- **Leonardo.ai** — game-focused image gen, has sprite/asset features + **API**. <https://leonardo.ai>

**Free sprite/asset libraries**
- **Kenney** — enormous **CC0** packs (sprites, UI, audio, 3D). <https://kenney.nl>
- **OpenGameArt** — huge community library (check each license). <https://opengameart.org>
- **itch.io game assets** — free + paid packs. <https://itch.io/game-assets>
- **CraftPix** (some free) <https://craftpix.net> · **Game-icons.net** (CC) <https://game-icons.net>

---

## 2. Backgrounds & environments (parallax, painted scenes)

- **Krita / Photopea** (free Photoshop-alike, browser) <https://www.photopea.com> · **GIMP** <https://www.gimp.org>
- **AI image gen for backdrops:** Stable Diffusion locally via **ComfyUI** (node-based, automatable) <https://github.com/comfyanonymous/ComfyUI> or **Automatic1111** <https://github.com/AUTOMATIC1111/stable-diffusion-webui>; hosted: **Midjourney** <https://www.midjourney.com>, **Adobe Firefly** (commercially-safe training) <https://www.adobe.com/products/firefly.html>, **Recraft** <https://www.recraft.com>, **Leonardo** <https://leonardo.ai>.
- **Parallax-ready / layered backgrounds:** Kenney + itch.io packs above; **Poly Haven** for HDRIs/skies (CC0) <https://polyhaven.com>.

---

## 3. Tilesets & level building

- **Tiled** — the standard tilemap editor; Godot/Unity import it. <https://www.mapeditor.org> · Repo <https://github.com/mapeditor/tiled>
- **LDtk** — modern level editor by *Dead Cells*' Deepnight; lovely Godot/Unity importers. <https://ldtk.io> · Repo <https://github.com/deepnight/ldtk>
- **Tilesetter** — generates auto-tiling tilesets. <https://www.tilesetter.org>
- Free tiles: **Kenney**, **OpenGameArt**, itch.io.

---

## 4. 2D skeletal / cut-out animation (smooth, low-cost-per-frame)

This is how you get Hollow-Knight-style fluid animation without drawing every frame.
- **Spine** — industry standard 2D skeletal animation (paid; integrates with every engine). <https://esotericsoftware.com>
- **DragonBones** — free Spine alternative. <https://dragonbones.github.io> · Repo <https://github.com/DragonBones>
- **Live2D** — for expressive character rigs. <https://www.live2d.com>
- **Godot's own AnimationPlayer + Skeleton2D** — built-in, free, no extra tool.

---

## 5. 3D models (if you go 2.5D or 3D, or for pre-rendered sprites)

**Traditional / hand tools**
- **Blender** — free, the 3D powerhouse (model, sculpt, rig, animate, render). <https://www.blender.org> · Repo <https://github.com/blender/blender>
- **MagicaVoxel** — free voxel modeler (fast, charming, great for indie). <https://ephtracy.github.io>
- **Wings3D** (free) <http://www.wings3d.com> · **SculptGL** (browser) <https://stephaneginier.com/sculptgl/>

**AI 3D generators (text/image → 3D, several with APIs)**
- **Tripo AI** — fastest gen, built for game devs, includes **rigging & segmentation**; has an **API**. <https://www.tripo3d.ai>
- **Meshy AI** — clean meshes, built-in **auto-rigging**, well-documented **REST API**. <https://www.meshy.ai> · API docs <https://docs.meshy.ai>
- **Rodin / Hyper3D** (ByteDance) — best for realistic characters, clean quad topology. <https://hyper3d.ai>
- **Luma Genie** — free text-to-3D. <https://lumalabs.ai/genie>
- **Sloyd** — parametric (game-ready, editable) 3D + API. <https://www.sloyd.ai>
- Open-source: **TRELLIS** (Microsoft) and **Hunyuan3D** (Tencent) — run locally / via API. <https://github.com/microsoft/TRELLIS> · <https://github.com/Tencent/Hunyuan3D-2>

**Free 3D libraries**
- **Quaternius** — gorgeous **CC0** 3D packs. <https://quaternius.com>
- **Poly Haven** — CC0 models, textures, HDRIs. <https://polyhaven.com>
- **Sketchfab** — millions of models (filter for free/CC). <https://sketchfab.com>
- **Kenney** 3D kits <https://kenney.nl/assets?q=3d>

---

## 6. 3D animation & motion capture (AI-assisted)

- **Mixamo** (Adobe, **free**) — auto-rig any humanoid + a library of mocap animations. <https://www.mixamo.com>
- **Cascadeur** — AI-assisted physics-correct keyframe animation. <https://cascadeur.com>
- **Rokoko Video** — free AI mocap from a single video. <https://www.rokoko.com>
- **DeepMotion** — markerless AI mocap (video → animation), has API. <https://www.deepmotion.com>
- **Plask** — browser AI mocap. <https://plask.ai>

---

## 7. Textures & materials

- **ambientCG** (CC0 PBR textures) <https://ambientcg.com> · **Poly Haven** <https://polyhaven.com> · **Material Maker** (free, procedural, Godot-made) <https://www.materialmaker.org> · Repo <https://github.com/RodZill4/material-maker>
- **Dream Textures** — Stable Diffusion *inside Blender* (seamless texture gen). Repo <https://github.com/carson-katri/dream-textures>

---

## 8. Music & sound (your signature — live guitar + drums)

**Your DAW (record the real thing — this is the whole pitch):**
- **Reaper** — cheap, pro, beloved. <https://www.reaper.fm>
- **LMMS** (free) <https://lmms.io> · **GarageBand** (free on Mac) · **Ardour** (open-source) <https://ardour.org>
- **Audacity** — free recording/editing (voice + guitar takes). <https://www.audacityteam.org>

**Sound effects (SFX)**
- **Bfxr / sfxr / jsfxr** — instant retro game SFX. <https://www.bfxr.net> · <https://sfxr.me>
- **ChipTone** <https://sfbgames.itch.io/chiptone> · **Freesound** (CC) <https://freesound.org> · **Sonniss GDC** free pro SFX <https://sonniss.com/gameaudiogdc>

**AI audio (use sparingly; your live recordings are the brand)**
- **Suno** <https://suno.com> · **Udio** <https://www.udio.com> — fast scratch/temp tracks (check commercial terms before shipping).

---

## 9. Voice (you mentioned voice acting)

- **Record your own** in Audacity/Reaper — most authentic, fully owned.
- **ElevenLabs** — top AI voices + **API**; check the commercial/license tier. <https://elevenlabs.io>
- **Replica Studios** — game-focused AI voices, licensed for games. <https://replicastudios.com>
- **Murf** <https://murf.ai> · **Altered Studio** <https://www.altered.ai>
- For "show, don't tell" (your stated goal), lean on **wordless vocalizations / musical motifs**
  over heavy VO — cheaper, more atmospheric, very Hollow Knight.

---

## 10. A recommended end-to-end pipeline (solo + AI)

```
Concept  → Midjourney/Firefly/Leonardo for mood boards & character concepts
Sprites  → Scenario (train a style model on your concepts) → Aseprite cleanup → consistent cast
Anim     → PixelLab (sprite anim) OR Spine/DragonBones rigs → export sheets
Levels   → Tiled / LDtk → import to Godot
3D (opt) → Tripo/Meshy (gen) → Blender (cleanup/rig) → Mixamo (animate)
Audio    → YOU: guitar + drums in Reaper → layered OGG stems → Godot adaptive music
Voice    → record your own / ElevenLabs for placeholder
Glue     → ComfyUI + Blender Python + Godot headless export, orchestrated by Claude (see "1 Dev → 100")
```

**Golden rule:** AI for **volume and speed**, *you* for **taste, consistency, and the music.** A
trained style model + your art direction is what separates "looks like a real game" from "looks
like AI slop." The next doc shows how to automate that at scale.
