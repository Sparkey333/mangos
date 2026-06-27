// Haptic patterns for GBA button feel
// Uses iOS CoreHaptics via Web Haptics API (navigator.vibrate) as fallback
// For native iOS: these patterns map to CHHapticPattern objects in the WKWebView bridge

export const PATTERNS = {
  // Crisp click when pressing a button center
  buttonPress: {
    intensity: 0.8,
    sharpness: 0.9,
    duration: 0.02,
  },

  // Softer release pop
  buttonRelease: {
    intensity: 0.4,
    sharpness: 0.6,
    duration: 0.015,
  },

  // Subtle buzz as finger edge-slides off a button boundary
  // This is the "skidding off" sensation — continuous low rumble
  edgeSlip: {
    intensity: 0.3,
    sharpness: 0.2,
    duration: 0.08,
    attackTime: 0.01,
    releaseTime: 0.04,
  },

  // Sharp pop when finger fully leaves the button zone
  edgePop: {
    intensity: 0.65,
    sharpness: 0.95,
    duration: 0.02,
  },

  // D-pad direction click (slightly softer than face buttons)
  dpadClick: {
    intensity: 0.6,
    sharpness: 0.8,
    duration: 0.018,
  },

  // Shoulder button (L/R) — longer travel feel
  shoulderPress: {
    intensity: 0.5,
    sharpness: 0.5,
    duration: 0.04,
    attackTime: 0.01,
  },

  // UI navigation / confirm
  uiSelect: {
    intensity: 0.4,
    sharpness: 0.7,
    duration: 0.015,
  },
}

// Web Vibration API fallback sequences (ms pattern: vibrate, pause, vibrate...)
export const VIBRATION_FALLBACK = {
  buttonPress:   [15],
  buttonRelease: [8],
  edgeSlip:      [6, 4, 6],
  edgePop:       [20],
  dpadClick:     [12],
  shoulderPress: [25],
  uiSelect:      [10],
}
