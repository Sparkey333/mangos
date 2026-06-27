import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { seedDemoLibrary } from './demoRoms'
import { upsertRom } from '../services/localLibrary'
import { HapticEngine } from '../components/HapticEngine/HapticEngine'

// DemoMode banner — shown on the Home screen when the library is empty
// and Drive is not connected. Lets the user kick the tyres with real
// open-source homebrew ROMs before setting up Drive.
export default function DemoMode({ onSeeded }) {
  const nav = useNavigate()
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)

  const handleLoad = async () => {
    HapticEngine.fire('uiSelect')
    setLoading(true)
    const n = await seedDemoLibrary(upsertRom)
    setLoading(false)
    setDone(true)
    onSeeded?.()
    setTimeout(() => nav('/'), 800)
  }

  return (
    <div style={{
      margin: '24px 20px',
      padding: 20,
      background: 'var(--c-surface)',
      borderRadius: 'var(--radius-lg)',
      border: '1px solid var(--c-border)',
    }}>
      <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 6, color: 'var(--c-accent2)' }}>
        DEMO MODE
      </div>
      <p style={{ fontSize: 13, color: 'var(--c-muted)', lineHeight: 1.55, marginBottom: 16 }}>
        No Drive connected yet. Load a couple of free, open-source GBA homebrew
        titles to test the skin and haptics — no sign-in needed.
      </p>
      <div style={{ display: 'flex', gap: 10 }}>
        <button
          className="btn-play"
          style={{ flex: 1, justifyContent: 'center' }}
          onClick={handleLoad}
          disabled={loading || done}
        >
          {done ? '✓ Loaded' : loading ? 'Loading…' : 'Load Demo ROMs'}
        </button>
        <button
          className="btn-info"
          style={{ flex: 1, justifyContent: 'center' }}
          onClick={() => nav('/settings')}
        >
          Connect Drive
        </button>
      </div>
    </div>
  )
}
