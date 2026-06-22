import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import RomCard from '../components/RomLibrary/RomCard'
import { getRoms } from '../services/localLibrary'

// Full grid view of every game (vs. Home's curated shelves).
export default function Library() {
  const nav = useNavigate()
  const [roms, setRoms] = useState([])
  const [filter, setFilter] = useState('ALL')

  useEffect(() => { getRoms().then(setRoms) }, [])

  const systems = ['ALL', 'GBA', 'PSX', 'GBC']
  const shown = filter === 'ALL' ? roms : roms.filter(r => r.system === filter || (filter === 'GBC' && r.system === 'GB'))

  return (
    <motion.div className="page scroll-y" style={{ padding: 16 }}
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
      <button className="btn-info" style={{ padding: '6px 12px', marginBottom: 14 }} onClick={() => nav('/')}>‹ Home</button>
      <div className="scroll-x" style={{ marginBottom: 16 }}>
        {systems.map(s => (
          <button key={s}
            className={filter === s ? 'btn-play' : 'btn-info'}
            style={{ padding: '6px 16px', fontSize: 13 }}
            onClick={() => setFilter(s)}>{s}</button>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(110px, 1fr))', gap: 14 }}>
        {shown.map(rom => <RomCard key={rom.id} rom={rom} />)}
      </div>
    </motion.div>
  )
}
