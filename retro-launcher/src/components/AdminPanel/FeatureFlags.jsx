import React, { createContext, useContext, useEffect, useState } from 'react'
import { getSetting, setSetting } from '../../services/localLibrary'

// Central feature-flag store. Everything experimental is toggleable here and in
// the Admin page, so new ideas ship "off by default, flip to test."

const DEFAULTS = {
  // Haptics
  haptics: true,
  edgeSlipHaptic: true,        // the "skid off the button" feel
  edgePopHaptic: true,         // the "pop" when finger fully leaves a button
  shoulderRumble: true,

  // Display / device
  rotationLock: true,          // auto-landscape in game
  pixelPerfect: true,          // crisp pixel scaling
  skin: 'gba-classic',         // gba-classic | gba-sp

  // Library / UX
  showPromoBanner: true,       // first-party banner only, never blocks
  betweenSessionBumpers: false,// own bumper clips on exit (opt-in)
  continuePlayingRow: true,

  // Trust / safety
  validateBios: true,          // verify PSX BIOS hash before boot
  validateRoms: true,          // sanity-check ROM headers
  offlineFirst: true,          // download to device, never stream-on-launch

  // Admin / experimental
  adminMode: false,
  showHitZones: false,         // visualize button edge bands
  hapticDebugHud: false,
}

const FlagCtx = createContext(null)

export function AdminFlagProvider({ children }) {
  const [flags, setFlags] = useState(DEFAULTS)

  useEffect(() => {
    getSetting('flags').then(saved => {
      if (saved) setFlags(f => ({ ...f, ...saved }))
    })
  }, [])

  const update = (key, value) => {
    setFlags(prev => {
      const next = { ...prev, [key]: value }
      setSetting('flags', next)
      return next
    })
  }

  return <FlagCtx.Provider value={{ flags, update }}>{children}</FlagCtx.Provider>
}

export function useFeatureFlags() {
  const ctx = useContext(FlagCtx)
  if (!ctx) throw new Error('useFeatureFlags must be used within AdminFlagProvider')
  return ctx
}
