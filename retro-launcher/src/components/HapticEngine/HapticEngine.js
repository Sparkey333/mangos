import { PATTERNS, VIBRATION_FALLBACK } from './hapticPatterns'

// HapticEngine: singleton that drives all tactile feedback
// On iOS Safari: uses navigator.vibrate (limited) + posts to native bridge if available
// Native iOS bridge (WKScriptMessageHandler) unlocks full CoreHaptics

class HapticEngineClass {
  constructor() {
    this.enabled = true
    this.edgeSlipEnabled = true  // toggleable in admin
    this.hasNativeBridge = typeof window.__hapticBridge !== 'undefined'
    this.hasVibration = 'vibrate' in navigator
    this._activeEdgeSlip = null
  }

  setEnabled(v) { this.enabled = v }
  setEdgeSlipEnabled(v) { this.edgeSlipEnabled = v }

  fire(patternName) {
    if (!this.enabled) return
    const pattern = PATTERNS[patternName]
    if (!pattern) return

    if (this.hasNativeBridge) {
      // Pass CoreHaptics params to native iOS layer
      window.__hapticBridge.postMessage({ type: 'haptic', pattern: patternName, ...pattern })
    } else if (this.hasVibration) {
      const seq = VIBRATION_FALLBACK[patternName] || [15]
      navigator.vibrate(seq)
    }
  }

  // Called continuously while pointer is within ~8px of button edge
  startEdgeSlip(buttonId) {
    if (!this.enabled || !this.edgeSlipEnabled) return
    if (this._activeEdgeSlip === buttonId) return
    // Always clear any existing interval before starting a new one; otherwise
    // switching quickly between two buttons leaks the first interval forever.
    clearInterval(this._edgeInterval)
    this._activeEdgeSlip = buttonId
    this.fire('edgeSlip')
    this._edgeInterval = setInterval(() => this.fire('edgeSlip'), 80)
  }

  stopEdgeSlip(buttonId, popped = false) {
    if (this._activeEdgeSlip !== buttonId) return
    clearInterval(this._edgeInterval)
    this._activeEdgeSlip = null
    if (popped) this.fire('edgePop')
  }

  buttonPress(buttonId) {
    const map = { l: 'shoulderPress', r: 'shoulderPress', up: 'dpadClick', down: 'dpadClick', left: 'dpadClick', right: 'dpadClick' }
    this.fire(map[buttonId] || 'buttonPress')
  }

  buttonRelease() {
    this.fire('buttonRelease')
  }
}

export const HapticEngine = new HapticEngineClass()
