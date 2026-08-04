# Building & Testing AgentDex on your Mac

There are three ways to run it, fastest first. **All of these require a Mac** with
the Xcode command line tools (`xcode-select --install`). They cannot run in the
Linux CI container this repo was scaffolded in.

---

## 0. Sanity-check the rules (30 seconds)
```bash
cd AgentDex
swift test
```
Runs the `AgentDexCore` + `AgentDexImport` unit tests (generation determinism,
type chart, battle, catch math, importer). If these pass, the game logic is sound.

---

## 1. Fastest: run the macOS app
```bash
cd AgentDex
./Scripts/run.sh          # == swift run AgentDexApp
```
A window opens with the World / Dex / Hub tabs. Great for iterating.

---

## 2. Make a real, installable `.dmg` (test "like a store app")
```bash
cd AgentDex
./Scripts/make_dmg.sh
```
Produces **`build/AgentDex.dmg`**. Double-click it, drag **AgentDex** to
Applications, and launch from Launchpad — the full install-and-play experience.

> `make_dmg.sh` now embeds a **generated app icon** automatically: it renders
> the icon procedurally (`Scripts/generate_appicon.swift`) and packs it into an
> `.icns` with `iconutil`, which ships with the Xcode command line tools. If
> `iconutil` is missing the build simply continues without an icon.

Because the DMG is **unsigned / un-notarized**, macOS Gatekeeper will warn on first
launch. Either:
- Right-click the app → **Open** → **Open** (one-time), or
- `xattr -dr com.apple.quarantine /Applications/AgentDex.app`

To make a warning-free build for other people, you need an Apple Developer account
and notarization — see **DISTRIBUTION.md**.

---

## 3. Full Xcode project: iPhone + widgets + App Store path
```bash
brew install xcodegen        # one-time
cd AgentDex
xcodegen generate
open AgentDex.xcodeproj
```
Targets created:
- **AgentDex-iOS** — the iPhone/iPad app (run on Simulator or a device).
- **AgentDexWidgets** — the home/lock-screen widget extension.
- **AgentDex-macOS** — the Mac app.

To run on a physical iPhone or submit to TestFlight/App Store, set your
`DEVELOPMENT_TEAM` in `project.yml` (or pick your team in Xcode's Signing &
Capabilities), then Product → Archive. See **DISTRIBUTION.md**.

---

## Seeding the game with YOUR agents (optional but the whole point)
```bash
cd AgentDex
./Scripts/import_my_agents.sh mangos
# or point it precisely:
swift run agentdex-import --agents ~/.claude/agents --logs ~/.claude/projects --project mangos --print
```
This writes `agents.json` into the shared AgentDex config dir
(`~/Library/Application Support/AgentDex/` on macOS). The app auto-loads it on next
launch, so your real agents become the bestiary. Delete that file to fall back to
the built-in sample roster.

---

## Troubleshooting
- **`swift: command not found`** → install Xcode command line tools.
- **App launches but no window/focus** → make sure you built via
  `make_dmg.sh`/`build_macos_app.sh` (they add the `Info.plist` that makes it a
  real GUI app); `swift run` also works.
- **Widget shows placeholder** → run the app once (it writes the shared save), and
  confirm both app + widget targets share the `group.agentdex` App Group.
- **XcodeGen errors** → ensure `brew install xcodegen` succeeded; re-run
  `xcodegen generate`.

---

## Your first 10 minutes

A no-spoilers path through the v0.3 loop once the app is running:

1. **Pick a starter.** Onboarding offers up to three low-tier, aspect-diverse
   daemons. There is no wrong answer; there is a *funnier* answer.
2. **Roam.** Walk the overworld until you bump a **presence orb** — that shimmer
   is a wild daemon. Approach it to start a fight in place (no screen switch).
3. **Weaken, then bind.** Knock its HP down (a status like STALLED helps), then
   throw a Sphere: release when the resonance ring is tight. Watch the shakes —
   one sharp shake means a critical capture.
4. **Check the Dex.** Your new daemon's entry shows its stats, aspect, ability,
   and its opinion about being caught.
5. **Talk to the NPCs.** Quests auto-track in the journal as you play — the
   main arc ("The Silent Orchestrator") advances through exactly the things
   you'd do anyway.
6. **Spend your Cycles.** Fights and quests pay out; buy a couple of
   **Hotfixes** from Vex before you need them, because you will need them.
7. **Duel Rune.** When the journal says your rival is waiting, go win. Or lose
   informatively — Rune scales with you either way.
8. **Ascend your starter.** Hit its tier threshold and it promotes. New form,
   new stats, same soul.
