import React, { useEffect, useState } from 'react'
import { useFeatureFlags } from '../AdminPanel/FeatureFlags'
import './AdBanner.css'

// AdBanner — the ONLY ad surface in the app.
// Rules baked in by design:
//   • Never a full-screen interstitial. Never blocks input. Never pauses gameplay.
//   • Bottom-anchored thin banner only, over the shell chrome (not the screen).
//   • Only serves FIRST-PARTY promos (own shows / Toonami-style bumpers / own
//     products). No third-party ad networks, no trackers, no external requests.
//   • Fully dismissible and globally toggleable in Settings.
//
// Promos are loaded from a local manifest the owner controls — see promos.js.

export default function AdBanner({ promos }) {
  const { flags } = useFeatureFlags()
  const [idx, setIdx] = useState(0)
  const [dismissed, setDismissed] = useState(false)

  useEffect(() => {
    if (!flags.showPromoBanner || dismissed || promos.length === 0) return
    const t = setInterval(() => setIdx(i => (i + 1) % promos.length), 12000)
    return () => clearInterval(t)
  }, [flags.showPromoBanner, dismissed, promos.length])

  if (!flags.showPromoBanner || dismissed || promos.length === 0) return null
  const promo = promos[idx]

  return (
    <div className="ad-banner" role="complementary" aria-label="Promo">
      <a className="ad-banner__link" href={promo.href} target="_blank" rel="noreferrer">
        {promo.thumb && <img className="ad-banner__thumb" src={promo.thumb} alt="" />}
        <div className="ad-banner__text">
          <span className="ad-banner__kicker">{promo.kicker || 'NOW SHOWING'}</span>
          <span className="ad-banner__title">{promo.title}</span>
        </div>
      </a>
      <button className="ad-banner__close" onClick={() => setDismissed(true)} aria-label="Dismiss">×</button>
    </div>
  )
}
