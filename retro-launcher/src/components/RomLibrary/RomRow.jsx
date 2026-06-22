import React from 'react'
import RomCard from './RomCard'

// Horizontal Netflix-style shelf of ROM cards.
export default function RomRow({ label, roms, activeId }) {
  if (!roms || roms.length === 0) return null
  return (
    <section className="row">
      <h2 className="row__label">{label}</h2>
      <div className="scroll-x">
        {roms.map(rom => (
          <RomCard key={rom.id} rom={rom} active={rom.id === activeId} />
        ))}
      </div>
    </section>
  )
}
