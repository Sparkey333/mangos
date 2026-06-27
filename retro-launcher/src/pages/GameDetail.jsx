import React, { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { db, getMeta, recordPlay } from '../services/localLibrary'
import { resolveMetadata, getBoxArtUrl } from '../services/metadata'
import { getBIOSCompat } from '../utils/trust'
import { commitAndPrefetch } from '../services/prefetch'
import { HapticEngine } from '../components/HapticEngine/HapticEngine'

// Plex-style detail page: big art, synopsis, year/genre/rating, play CTA.
export default function GameDetail() {
  const { id } = useParams()
  const nav = useNavigate()
  const [rom, setRom] = useState(null)
  const [meta, setMeta] = useState(null)

  useEffect(() => {
    db.roms.get(id).then(async r => {
      setRom(r)
      if (!r) return
      let m = await getMeta(id)
      if (!m) m = await resolveMetadata(r) // art-only if IGDB not configured
      setMeta(m)
    })
  }, [id])

  if (!rom) return <div className="page" style={{ padding: 40 }}>Loading…</div>

  const biosNote = rom.system === 'PSX' ? getBIOSCompat(rom.cleanName) : null

  return (
    <motion.div className="page scroll-y"
      initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
      <div className="hero">
        <img className="hero__art" src={meta?.boxArt || getBoxArtUrl(rom.system, rom.cleanName)} alt={rom.cleanName} />
        <div className="hero__gradient" />
        <button className="btn-info" style={{ position: 'absolute', top: 12, left: 12, padding: '6px 12px' }}
          onClick={() => nav(-1)}>‹ Back</button>
      </div>

      <div style={{ padding: '0 20px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 6 }}>{rom.cleanName}</h1>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginBottom: 14, flexWrap: 'wrap' }}>
          <span className={`sys-badge sys-badge--${rom.system.toLowerCase()}`}>{rom.system}</span>
          {meta?.year && <span style={{ color: 'var(--c-muted)', fontSize: 13 }}>{meta.year}</span>}
          {meta?.rating != null && <span style={{ color: '#46d369', fontSize: 13 }}>★ {meta.rating}%</span>}
          {meta?.genres?.slice(0, 2).map(g => (
            <span key={g} style={{ color: 'var(--c-muted)', fontSize: 13 }}>{g}</span>
          ))}
        </div>

        <button className="btn-play" style={{ width: '100%', justifyContent: 'center', marginBottom: 16 }}
          onClick={async () => {
            HapticEngine.fire('uiSelect')
            await recordPlay(id)
            commitAndPrefetch(rom) // commit chosen + pre-stage 2 runners-up (non-blocking)
            nav(`/play/${id}`)
          }}>
          ▶ Play
        </button>

        {meta?.summary
          ? <p style={{ fontSize: 14, lineHeight: 1.55, color: '#c8c8c8' }}>{meta.summary}</p>
          : <p style={{ fontSize: 13, color: 'var(--c-muted)' }}>
              Box art shown from the libretro database. Add an IGDB key in Settings for full synopsis, year and ratings.
            </p>}

        {biosNote && (
          <div style={{ marginTop: 16, padding: 12, background: 'var(--c-surface)', borderRadius: 10, fontSize: 12 }}>
            <strong>PSX BIOS:</strong> {biosNote.bios}<br />
            <span style={{ color: 'var(--c-muted)' }}>{biosNote.notes}</span>
          </div>
        )}

        <div style={{ marginTop: 16, fontSize: 11, color: 'var(--c-muted)' }}>
          File: {rom.name} · {(rom.size / 1048576).toFixed(1)} MB · {rom.downloaded ? 'On device ✓' : 'In Drive (will download on play)'}
        </div>
      </div>
    </motion.div>
  )
}
