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
