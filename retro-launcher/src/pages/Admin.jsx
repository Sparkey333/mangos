import React from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import Toggle from '../components/AdminPanel/Toggle'
import { useFeatureFlags } from '../components/AdminPanel/FeatureFlags'
import { HapticEngine } from '../components/HapticEngine/HapticEngine'

// Admin / experimental bench. This is where new ideas get toggled and tested
// before they graduate to user Settings. Haptic test pad included.
export default function Admin() {
  const nav = useNavigate()
  const { flags, update } = useFeatureFlags()

  const testPad = ['buttonPress', 'buttonRelease', 'edgeSlip', 'edgePop', 'dpadClick', 'shoulderPress']

  return (
    <motion.div className="page scroll-y" style={{ padding: 20 }}
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
      <button className="btn-info" style={{ padding: '6px 12px', marginBottom: 16 }} onClick={() => nav('/settings')}>‹ Settings</button>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Admin Bench</h1>
      <p style={{ color: 'var(--c-muted)', fontSize: 13, marginBottom: 24 }}>
        Experimental toggles. Flip to test; ship to Settings when proven.
      </p>

      <Toggle label="Admin mode" desc="Unlock overlays & debug HUDs" checked={flags.adminMode} onChange={v => update('adminMode', v)} />
      <Toggle label="Show hit zones" desc="Visualize button edge bands in-game" checked={flags.showHitZones} onChange={v => update('showHitZones', v)} />
      <Toggle label="Haptic debug HUD" checked={flags.hapticDebugHud} onChange={v => update('hapticDebugHud', v)} />
      <Toggle label="Shoulder rumble" desc="Longer-travel L/R feel" checked={flags.shoulderRumble} onChange={v => update('shoulderRumble', v)} />

      <h2 style={{ fontSize: 15, margin: '24px 0 12px' }}>Skin</h2>
      <div style={{ display: 'flex', gap: 10 }}>
        {['gba-classic', 'gba-sp'].map(s => (
          <button key={s}
            className={flags.skin === s ? 'btn-play' : 'btn-info'}
            style={{ flex: 1, justifyContent: 'center', textTransform: 'capitalize' }}
            onClick={() => update('skin', s)}>{s.replace('-', ' ')}</button>
        ))}
      </div>

      <h2 style={{ fontSize: 15, margin: '24px 0 12px' }}>Haptic Test Pad</h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {testPad.map(p => (
          <button key={p} className="btn-info" style={{ justifyContent: 'center', fontSize: 12 }}
            onPointerDown={() => HapticEngine.fire(p)}>{p}</button>
        ))}
      </div>

      <div style={{ height: 40 }} />
    </motion.div>
  )
}
