import React, { useEffect, useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import RomCard from '../components/RomLibrary/RomCard'
import { getRoms } from '../services/localLibrary'

export default function Library() {
  const nav = useNavigate()
  const [roms, setRoms]     = useState([])
  const [filter, setFilter] = useState('ALL')
  const [query, setQuery]   = useState('')

  useEffect(() => { getRoms().then(setRoms) }, [])

  const systems = ['ALL', 'GBA', 'PSX', 'GBC']

  const shown = useMemo(() => {
    let list = filter === 'ALL' ? roms : roms.filter(r => r.system === filter || (filter === 'GBC' && r.system === 'GB'))
    if (query.trim()) {
      const q = query.trim().toLowerCase()
      list = list.filter(r => r.cleanName?.toLowerCase().includes(q) || r.name.toLowerCase().includes(q))
    }
    return list
  }, [roms, filter, query])

  return (
    <motion.div className="page scroll-y" style={{ padding: 16 }}
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>

      <button className="btn-info" style={{ padding: '6px 12px', marginBottom: 14 }} onClick={() => nav('/')}>‹ Home</button>

      {/* Search */}
      <input
        value={query}
        onChange={e => setQuery(e.target.value)}
        placeholder="Search games…"
        style={{
          width: '100%', boxSizing: 'border-box',
          padding: '10px 14px', borderRadius: 10,
          background: 'var(--c-surface)', border: '1px solid var(--c-border)',
          color: '#fff', fontSize: 14, marginBottom: 12,
        }}
      />

      {/* System tabs */}
      <div className="scroll-x" style={{ marginBottom: 16, gap: 8 }}>
        {systems.map(s => (
          <button key={s}
            className={filter === s ? 'btn-play' : 'btn-info'}
            style={{ padding: '6px 16px', fontSize: 13, flexShrink: 0 }}
            onClick={() => setFilter(s)}>{s}</button>
        ))}
      </div>

      {shown.length === 0 && (
        <p style={{ color: 'var(--c-muted)', fontSize: 13, textAlign: 'center', marginTop: 40 }}>
          {roms.length === 0 ? 'Library empty — connect Drive or load demo ROMs from the home screen.'
                             : 'No games match your search.'}
        </p>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(110px, 1fr))', gap: 14 }}>
        {shown.map(rom => <RomCard key={rom.id} rom={rom} />)}
      </div>
    </motion.div>
  )
}
