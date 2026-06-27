# Native iOS Build — Capacitor + CoreHaptics

This turns the PWA into a real App Store `.ipa` with full **CoreHaptics** (transient
+ continuous events, sharpness + intensity, attack/release envelopes) instead of
`navigator.vibrate`.

## One-time setup (needs a Mac + Xcode)

```bash
cd retro-launcher
npm install @capacitor/core @capacitor/ios @capacitor/cli
npx cap init          # already have capacitor.config.json — skip if prompted
npm run build         # Vite builds into dist/
npx cap add ios       # scaffolds ios/ directory
npx cap sync          # copies dist/ + plugins into the Xcode project
```

Then open in Xcode:
```bash
npx cap open ios
```

The `HapticBridgePlugin.swift` and `.m` files are already in
`capacitor/ios/App/App/HapticBridge/`. Drag them into the Xcode project under
`App/App/` — Xcode picks them up automatically.

## How it works

```
JS HapticEngine.fire('edgeSlip')
  → window.__hapticBridge.postMessage({ type:'haptic', intensity:0.3, sharpness:0.2, duration:0.08 })
  → Capacitor bridge (WKScriptMessageHandler)
  → HapticBridgePlugin.swift play()
  → CHHapticEngine plays a real CoreHaptics transient + optional continuous tail
```

The JS layer (`HapticEngine.js`) is unchanged — it already guards on
`typeof window.__hapticBridge !== 'undefined'`. The Capacitor plugin patches that
global in `haptic-bridge-web.js` before the app bundle loads.

## Requirements

- iPhone 8 or later (Taptic Engine 2 = CoreHaptics support)
- iOS 13+
- `CHHapticEngine.capabilitiesForHardware().supportsHaptics` checked at runtime;
  falls back to nothing silently if not supported (simulator, older devices)

## App Store packaging

Emulators are permitted on the App Store since April 2024 (Apple App Review
Guideline 4.7). Capacitor apps are standard WKWebView containers and pass review.
The launcher does not include ROM or BIOS data — those come from the user's own
Google Drive at runtime, so there is no distribution of copyrighted content.
