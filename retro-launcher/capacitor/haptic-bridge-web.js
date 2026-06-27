// Web-layer Capacitor wrapper that patches window.__hapticBridge so the
// existing HapticEngine.js works without changes on both native (CoreHaptics)
// and browser (vibration API fallback).
//
// Include this BEFORE the main app bundle in capacitor.config.ts plugins config
// or simply import it in main.jsx when running inside a Capacitor app.

import { registerPlugin } from '@capacitor/core'

const HapticBridge = registerPlugin('HapticBridge', {
  // Web fallback — use vibration API so the same JS code runs in the browser too
  web: {
    async play(params) {
      const dur = Math.round((params.duration || 0.02) * 1000)
      navigator.vibrate?.([Math.max(dur, 10)])
    },
    async supported() { return { value: 'vibrate' in navigator } },
  },
})

// Patch the global bridge so HapticEngine.js's existing guard
// (typeof window.__hapticBridge !== 'undefined') works immediately.
if (!window.__hapticBridge) {
  window.__hapticBridge = {
    postMessage: (data) => HapticBridge.play(data),
  }
}

export default HapticBridge
