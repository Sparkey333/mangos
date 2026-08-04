# Distribution: from local test → App Store

Honest summary of what each step needs. The scaffolding here gets you a running,
installable app; **shipping to a store requires your Apple Developer account and a
Mac** — those can't be done from a CI container or on your behalf.

## The ladder

| Goal | What you need | How |
|------|---------------|-----|
| Run locally | A Mac | `./Scripts/run.sh` |
| Install like an app (you) | A Mac | `./Scripts/make_dmg.sh` → drag to Applications |
| Give the DMG to friends warning-free | Apple Developer account ($99/yr) + notarization | see **Notarizing** below |
| Test on your iPhone | Free Apple ID (7-day) or paid account | Xcode → run on device |
| TestFlight beta | Paid account + App Store Connect | Xcode → Archive → Distribute |
| App Store (iOS) | Paid account + review | App Store Connect submission |
| Mac App Store | Paid account + review | Archive the macOS target |

## Notarizing a macOS DMG (warning-free for others)
Requires a paid Apple Developer account and a "Developer ID Application" cert.
```bash
# 1) Sign with your Developer ID (not ad-hoc):
codesign --force --deep --options runtime \
  --sign "Developer ID Application: YOUR NAME (TEAMID)" build/AgentDex.app

# 2) Notarize (store credentials once with notarytool):
xcrun notarytool store-credentials AC_PASSWORD \
  --apple-id you@example.com --team-id TEAMID --password APP_SPECIFIC_PW
./Scripts/make_dmg.sh
xcrun notarytool submit build/AgentDex.dmg --keychain-profile AC_PASSWORD --wait

# 3) Staple the ticket so it works offline:
xcrun stapler staple build/AgentDex.dmg
```

## iPhone / App Store path (via the Xcode project)
1. `brew install xcodegen && xcodegen generate && open AgentDex.xcodeproj`
2. Set your Team in **Signing & Capabilities** for `AgentDex-iOS` and
   `AgentDexWidgets` (or `DEVELOPMENT_TEAM` in `project.yml`).
3. Confirm the **App Groups** capability (`group.agentdex`) is enabled on both.
4. Pick a real device or "Any iOS Device", then **Product → Archive**.
5. In the Organizer, **Distribute App** → App Store Connect (TestFlight) or
   Ad Hoc / Development for direct installs.

## App Store review notes (worth knowing early)
- **Icons & launch screen**: add an app icon set before submission (placeholder art
  is fine to start; the game uses procedural sprites so no in-game art is blocking).
- **Privacy**: the app stores data locally only (no network, no tracking). Fill the
  App Privacy questionnaire as "Data Not Collected" unless you add analytics.
- **Guideline 4.2 (minimum functionality)**: the vertical slice should show the
  full loop (roam → fight → catch → Dex) so it reads as a real game, not a demo.
- **Trademark**: keep names/art original (this is "inspired by", not Pokémon assets).

## What I (the assistant) cannot do from here
- Compile, run, or screenshot anything (no Swift toolchain in this Linux container).
- Produce a signed/notarized build or a `.dmg` (needs your Mac + `hdiutil`).
- Submit to the App Store (needs your Apple Developer credentials).

Everything above is authored so that on your Mac it's one or two commands.
