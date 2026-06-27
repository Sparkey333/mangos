import { useEffect } from 'react'

// Force landscape when entering a game, portrait for UI pages
// Uses Screen Orientation API + CSS fallback for Safari

export function useRotationLock() {
  useEffect(() => {
    const handle = () => {
      // Prevent accidental pull-to-refresh and bounce scroll
      document.body.style.overscrollBehavior = 'none'
    }
    handle()
  }, [])
}

export async function lockLandscape() {
  try {
    if (screen.orientation?.lock) {
      await screen.orientation.lock('landscape')
      return true
    }
  } catch {
    // Safari doesn't support lock() — fall back to CSS transform trick
    document.documentElement.classList.add('force-landscape')
  }
  return false
}

export async function lockPortrait() {
  try {
    if (screen.orientation?.lock) {
      await screen.orientation.lock('portrait')
      return true
    }
  } catch {
    document.documentElement.classList.remove('force-landscape')
  }
  return false
}

export function unlockOrientation() {
  try {
    screen.orientation?.unlock?.()
    document.documentElement.classList.remove('force-landscape')
  } catch { /* noop */ }
}

export function isLandscape() {
  return window.innerWidth > window.innerHeight
}
