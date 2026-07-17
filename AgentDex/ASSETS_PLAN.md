# AgentDex — Art Asset Pipeline (plan)

Goal: replace the procedural sprites with real art, from three inlets, without
breaking the "runs with zero assets" guarantee. The procedural `DaemonSprite`
stays as the **guaranteed fallback**; real art overlays it when present.

## The three inlets

1. **Curated open-source / CC0 packs** — hand-picked sprite/creature packs from
   OpenGameArt, Kenney, itch.io CC0, Poly Pizza, etc. Used for UI bits, orbs,
   FX, and generic "presence" art.
2. **Openly-licensed AI-gen packs** — batches generated once, then committed
   under a permissive license we own (CC0/CC-BY on our own outputs). These give
   every configured daemon a base portrait.
3. **Higgsfield-connected generator** — an *offline* tool that turns each
   daemon's generated identity (aspect, tier, sigil, motif, nature, palette)
   into a prompt, calls Higgsfield to render **our own creature + N alt
   versions**, and writes them into a pack. This is how we make bespoke art per
   agent and per Ascension form.

## Non-negotiables

- **No live generation or API keys in the shipped app.** Generation happens on
  the Mac / CI, outputs are committed as static assets. (App Store + cost + key
  safety.)
- **Every asset carries a license record.** A missing/unknown license = not
  shipped.
- **Deterministic mapping.** Art is keyed by `species.id` (+ variant tag like
  `ascended`, `anomalous`, `alt2`), matching the deterministic generator so the
  same agent always resolves to the same art.
- **Fallback always works.** No network, no bundle, no manifest → procedural
  sprite renders. Nothing is ever blank.

## Architecture (fits the existing code)

```
AgentDexCore (new, pure)                 AgentDexApp (new, SwiftUI)
├─ ArtManifest.swift                     ├─ ArtResolver.swift   (id+variant → Image?)
│   AssetPack { id, license, entries }   │   • checks bundled packs, then
│   ArtEntry  { key, file, license,      │     Application-Support/AgentDex/art,
│               source, attribution,     │     then nil → caller draws DaemonSprite
│               aspect?, tier? }         └─ ArtworkView.swift   (Image or DaemonSprite)
└─ ArtKey.swift  (species → stable key)

Tools/ (offline, never shipped)
├─ artgen/            Swift or Python CLI
│   ├─ prompt.swift       daemon identity → text prompt (+ negative prompt)
│   ├─ higgsfield.swift   POST generate, poll status, download
│   └─ manifest.swift     write ArtManifest + per-file license record
└─ packs/curated/     vendored CC0 art + its LICENSES.md
```

- **`ArtworkView(species:variant:size:)`** replaces raw `DaemonSprite` at call
  sites (Dex, party, battle, widget): tries `ArtResolver`, else draws the
  procedural sprite. One swap point; everything else unchanged.
- Packs live as folders with a `manifest.json` + images + `LICENSES.md`.
  Bundled packs ship in the app; generated/user packs land in
  `Application Support/AgentDex/art/` (same dir family as the importer).

## Higgsfield connection

- Access: hosted **MCP server** `https://mcp.higgsfield.ai/mcp`, or REST
  (`POST /v1/generations`, `GET .../requests/status/{id}`, `Authorization:
  Bearer`). Key from env (`HIGGSFIELD_API_KEY`), never committed.
- **Prompt derivation** (per daemon, deterministic seed from `species.id`):
  `"{aspect} spirit-creature, {sigil} sigil silhouette, {motif}, palette
  {primaryHex}/{secondaryHex}, {tier} scale, {nature} demeanor, clean game
  sprite, transparent background, centered"` + aspect-specific style tags.
  Negative prompt strips text/watermark/background.
- **Alt versions**: request K images per prompt (K≈3) → `alt1..altK`; plus a
  hue-shifted **anomalous** variant and a higher-detail **ascended** variant.
- Output: PNGs + a manifest entry each, license = our chosen output license.

## Licensing discipline (`packs/*/LICENSES.md` + manifest)

| Field | Purpose |
|-------|---------|
| `license` | SPDX-ish id (CC0-1.0, CC-BY-4.0, our own) |
| `source` | URL or "higgsfield:{model}" |
| `attribution` | required credit line if any |
| CC-BY assets → surfaced in an in-app **Credits** screen (Settings). |

## Rollout (small steps, each shippable)

1. `ArtManifest` + `ArtKey` + `ArtResolver` + `ArtworkView` with **no assets**
   (pure fallback) → swap call sites. Zero visual change, seam in place.
2. Vendor one small CC0 pack (orbs/FX/UI) + its licenses → wire in.
3. `Tools/artgen` prompt builder + a `--dry-run` that emits prompts/manifest
   for the current roster (no API cost).
4. Add Higgsfield REST/MCP call behind the key; generate base portraits + alts
   for the sample roster; commit pack + Credits screen.
5. Batch the full roster; add ascended/anomalous variants.

## Sources
- [Higgsfield MCP](https://higgsfield.ai/mcp) · [Higgsfield Cloud API](https://cloud.higgsfield.ai/) · [How to Use Higgsfield API (apidog)](https://apidog.com/blog/higgsfield-api/) · [higgsfield-js SDK](https://github.com/higgsfield-ai/higgsfield-js) · [higgsfield-client (Python)](https://github.com/higgsfield-ai/higgsfield-client)
