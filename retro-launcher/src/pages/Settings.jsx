import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import Toggle from '../components/AdminPanel/Toggle'
import { useFeatureFlags } from '../components/AdminPanel/FeatureFlags'
import { initDriveAuth, requestAccess, isAuthed, findFolder, listRoms } from '../services/googleDrive'
import { upsertRom, getSetting, setSetting, saveBlob } from '../services/localLibrary'
import { validateBIOS } from '../utils/trust'

// User-facing settings: connect Drive, import library, BIOS, comfort toggles.
export default function Settings() {
  const nav = useNavigate()
  const { flags, update } = useFeatureFlags()
  const [clientId, setClientId] = useState('')
  const [authed, setAuthed] = useState(isAuthed())
  const [importing, setImporting] = useState('')
  const [biosStatus, setBiosStatus] = useState('')

  useEffect(() => {
    getSetting('googleClientId', '').then(setClientId)
    // Load GIS script once
    if (!window.google?.accounts) {
      const s = document.createElement('script')
      s.src = 'https://accounts.google.com/gsi/client'
      s.async = true
      document.body.appendChild(s)
    }
  }, [])

  const connect = () => {
    setSetting('googleClientId', clientId)
    initDriveAuth(clientId, () => setAuthed(true))
    requestAccess()
  }

  const importLibrary = async () => {
    setImporting('Finding RetroLauncher folder…')
    const folder = await findFolder('RetroLauncher')
    if (!folder) { setImporting('No "RetroLauncher" folder found in your Drive.'); return }
    setImporting('Listing ROMs…')
    const files = await listRoms(folder.id)
    let n = 0
    for (const f of files) {
      if (f.isFolder) continue
      await upsertRom({
        id: f.id, driveId: f.id, name: f.name, cleanName: f.cleanName,
        system: f.system, ext: f.ext, size: f.size, downloaded: false, lastPlayed: null,
      })
      n++
    }
    setImporting(`Imported ${n} games. Open the home screen!`)
  }

  const onBiosFile = async (e) => {
    const file = e.target.files[0]
    if (!file) return
    const v = await validateBIOS(file)
    if (!v.valid) { setBiosStatus(`✗ ${v.reason}`); return }
    await saveBlob(`BIOS:${v.name}`, file)
    setBiosStatus(`✓ ${v.name} (${v.region}) verified & stored`)
  }

  return (
    <motion.div className="page scroll-y" style={{ padding: 20 }}
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
      <button className="btn-info" style={{ padding: '6px 12px', marginBottom: 16 }} onClick={() => nav('/')}>‹ Home</button>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Settings</h1>
      <p style={{ color: 'var(--c-muted)', fontSize: 13, marginBottom: 24 }}>
        Your library lives in your own Google Drive. Nothing is uploaded to us, ever.
      </p>

      <h2 style={{ fontSize: 15, marginBottom: 8 }}>Google Drive</h2>
      <input
        value={clientId}
        onChange={e => setClientId(e.target.value)}
        placeholder="Google OAuth Client ID"
        style={{ width: '100%', padding: 12, borderRadius: 8, background: 'var(--c-surface)',
          border: '1px solid var(--c-border)', color: '#fff', marginBottom: 10 }}
      />
      {!authed
        ? <button className="btn-play" style={{ width: '100%', justifyContent: 'center' }} onClick={connect}>Connect Drive</button>
        : <button className="btn-play" style={{ width: '100%', justifyContent: 'center' }} onClick={importLibrary}>Import Library</button>}
      {importing && <p style={{ fontSize: 12, color: 'var(--c-muted)', marginTop: 8 }}>{importing}</p>}

      <h2 style={{ fontSize: 15, margin: '24px 0 8px' }}>PlayStation BIOS</h2>
      <p style={{ fontSize: 12, color: 'var(--c-muted)', marginBottom: 8 }}>
        Required to run PSX games. Use SCPH5501.BIN (US, most compatible). Verified against known-good hash.
      </p>
      <input type="file" accept=".bin,.BIN" onChange={onBiosFile} style={{ fontSize: 12 }} />
      {biosStatus && <p style={{ fontSize: 12, marginTop: 6, color: biosStatus.startsWith('✓') ? '#46d369' : '#e50914' }}>{biosStatus}</p>}

      <h2 style={{ fontSize: 15, margin: '24px 0 8px' }}>Feel & Comfort</h2>
      <Toggle label="Haptics" desc="Tactile button feedback" checked={flags.haptics} onChange={v => update('haptics', v)} />
      <Toggle label="Edge-slip buzz" desc="Subtle buzz as a finger skids toward a button edge" checked={flags.edgeSlipHaptic} onChange={v => update('edgeSlipHaptic', v)} />
      <Toggle label="Edge pop" desc="Sharp pop when a finger fully slides off a button" checked={flags.edgePopHaptic} onChange={v => update('edgePopHaptic', v)} />
      <Toggle label="Auto-landscape in game" desc="Rotate to GBA landscape automatically" checked={flags.rotationLock} onChange={v => update('rotationLock', v)} />
      <Toggle label="Pixel-perfect scaling" checked={flags.pixelPerfect} onChange={v => update('pixelPerfect', v)} />

      <h2 style={{ fontSize: 15, margin: '24px 0 8px' }}>Trust & Safety</h2>
      <Toggle label="Verify PSX BIOS" desc="Hash-check BIOS before boot" checked={flags.validateBios} onChange={v => update('validateBios', v)} />
      <Toggle label="Validate ROMs" desc="Sanity-check ROM headers" checked={flags.validateRoms} onChange={v => update('validateRoms', v)} />
      <Toggle label="Offline-first" desc="Download to device, never stream on launch" checked={flags.offlineFirst} onChange={v => update('offlineFirst', v)} />

      <h2 style={{ fontSize: 15, margin: '24px 0 8px' }}>Promos</h2>
      <Toggle label="First-party banner" desc="Own shows/products only · never interrupts gameplay" checked={flags.showPromoBanner} onChange={v => update('showPromoBanner', v)} />
      <Toggle label="Between-session bumpers" desc="Own clips on exit (opt-in, skippable)" checked={flags.betweenSessionBumpers} onChange={v => update('betweenSessionBumpers', v)} />

      <button className="btn-info" style={{ width: '100%', justifyContent: 'center', marginTop: 24 }}
        onClick={() => nav('/admin')}>Admin / Experimental ›</button>

      <div style={{ height: 40 }} />
    </motion.div>
  )
}
