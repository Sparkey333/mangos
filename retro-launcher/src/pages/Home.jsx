import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import RomRow from '../components/RomLibrary/RomRow'
import AdBanner from '../components/MediaPlayer/AdBanner'
import { PROMOS } from '../components/MediaPlayer/promos'
import { getRoms, getContinuePlaying } from '../services/localLibrary'
import DemoMode from '../demo/DemoMode'
import { getBoxArtUrl, getTitleScreenUrl } from '../services/metadata'
import { HapticEngine } from '../components/HapticEngine/HapticEngine'

// Netflix-style home: hero banner + Continue Playing + per-system shelves.
export default function Home() {
  const nav = useNavigate()
  const [roms, setRoms] = useState([])
  const [continueRow, setContinueRow] = useState([])

  useEffect(() => {
    getRoms().then(setRoms)
    getContinuePlaying().then(setContinueRow)
  }, [])

  const featured = continueRow[0] || roms.find(r => r.system === 'GBA') || roms[0]
  const gba = roms.filter(r => r.system === 'GBA')
  const psx = roms.filter(r => r.system === 'PSX')
  const gbc = roms.filter(r => ['GBC', 'GB'].includes(r.system))

  return (
    <motion.div className="page scroll-y"
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>

      {featured && (
        <div className="hero">
          <img className="hero__art"
            src={getTitleScreenUrl(featured.system, featured.cleanName) || getBoxArtUrl(featured.system, featured.cleanName)}
            alt={featured.cleanName}
            onError={(e) => { e.target.style.opacity = 0.2 }} />
          <div className="hero__gradient" />
          <div className="hero__meta">
            <div className="hero__title">{featured.cleanName}</div>
            <div className="hero__subtitle">
              <span className={`sys-badge sys-badge--${featured.system.toLowerCase()}`}>{featured.system}</span>
            </div>
            <div className="hero__actions">
              <button className="btn-play" onClick={() => { HapticEngine.fire('uiSelect'); nav(`/play/${featured.id}`) }}>
                ▶ Play
              </button>
              <button className="btn-info" onClick={() => nav(`/game/${featured.id}`)}>
                ⓘ Info
              </button>
            </div>
          </div>
        </div>
      )}

      {roms.length === 0 && (
        <DemoMode onSeeded={() => getRoms().then(setRoms)} />
      )}

      <RomRow label="Continue Playing" roms={continueRow} activeId={featured?.id} />
      <RomRow label="Game Boy Advance" roms={gba} />
      <RomRow label="PlayStation" roms={psx} />
      <RomRow label="Game Boy / Color" roms={gbc} />

      <AdBanner promos={PROMOS} />
    </motion.div>
  )
}
