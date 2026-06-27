import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getBoxArtUrl } from '../../services/metadata'
import { HapticEngine } from '../HapticEngine/HapticEngine'

export default function RomCard({ rom, active }) {
  const nav = useNavigate()
  const [art, setArt] = useState(rom.boxArt || getBoxArtUrl(rom.system, rom.cleanName))

  return (
    <div
      className={`rom-card ${active ? 'rom-card--active' : ''}`}
      onClick={() => { HapticEngine.fire('uiSelect'); nav(`/game/${rom.id}`) }}
    >
      <img
        className="rom-card__art"
        src={art}
        alt={rom.cleanName}
        loading="lazy"
        onError={() => setArt('/icons/cover-fallback.svg')}
      />
      <div className="rom-card__title">{rom.cleanName}</div>
    </div>
  )
}
