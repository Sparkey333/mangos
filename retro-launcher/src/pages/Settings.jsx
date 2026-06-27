import React, { useEffect, useRef, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import Toggle from '../components/AdminPanel/Toggle'
import { useFeatureFlags } from '../components/AdminPanel/FeatureFlags'
import {
  initDriveAuth, requestAccess, isAuthed,
  ensureRootFolder, ensureSubfolders,
  findFolder, listRoms, uploadRom, cleanRomName,
} from '../services/googleDrive'
import { upsertRom, saveBlob, getBlob, getSetting, setSetting } from '../services/localLibrary'
import { validateBIOS, validateGBAROM } from '../utils/trust'

const SECTION = { fontSize: 15, margin: '28px 0 10px', color: 'var(--c-text)', fontWeight: 700 }
const HINT    = { fontSize: 12, color: 'var(--c-muted)', marginBottom: 10, lineHeight: 1.5 }

// ── Upload queue item ─────────────────────────────────────────────────────────
// status: 'queued' | 'uploading' | 'local' | 'done' | 'error'

function UploadItem({ item }) {
  const colors = { done: '#46d369', error: '#e50914', uploading: 'var(--c-accent2)', queued: 'var(--c-muted)', local: '#46d369' }
  const icons  = { done: '✓', error: '✗', uploading: '↑', queued: '…', local: '✓' }
  return (
    <div style={{ display:'flex', alignItems:'center', gap:8, padding:'6px 0', borderBottom:'1px solid var(--c-border)' }}>
      <span style={{ color: colors[item.status], fontSize:14, width:16 }}>{icons[item.status]}</span>
      <span style={{ flex:1, fontSize:12, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{item.name}</span>
      <span style={{ fontSize:11, color:'var(--c-muted)', minWidth:36 }}>{item.system}</span>
      {item.status === 'uploading' && (
        <div style={{ width:60, height:4, background:'var(--c-border)', borderRadius:2, overflow:'hidden' }}>
          <div style={{ width:`${(item.progress||0)*100}%`, height:'100%', background:'var(--c-accent2)', borderRadius:2, transition:'width .15s' }}/>
        </div>
      )}
      {item.status === 'error' && (
        <span style={{ fontSize:10, color:'#e50914', maxWidth:80, overflow:'hidden', textOverflow:'ellipsis' }}>{item.error}</span>
      )}
    </div>
  )
}

export default function Settings() {
  const nav  = useNavigate()
  const { flags, update } = useFeatureFlags()

  // Drive state
  const [clientId, setClientId] = useState('')
  const [authed, setAuthed]     = useState(isAuthed())
  const [importing, setImporting] = useState('')

  // Upload state
  const [queue, setQueue]         = useState([])
  const [uploading, setUploading] = useState(false)
  const subfolderIdsRef           = useRef(null)
  const fileInputRef              = useRef(null)
  const localInputRef             = useRef(null)

  // BIOS state
  const [biosStatus, setBiosStatus] = useState('')

  useEffect(() => {
    getSetting('googleClientId', '').then(setClientId)
    if (!window.google?.accounts) {
      const s = document.createElement('script')
      s.src = 'https://accounts.google.com/gsi/client'
      s.async = true
      document.body.appendChild(s)
    }
  }, [])

  // ── Drive connect ──────────────────────────────────────────────────────────

  const connect = () => {
    setSetting('googleClientId', clientId)
    initDriveAuth(clientId, () => setAuthed(true))
    requestAccess()
  }

  // ── Import library from Drive ───────────────────────────────────────────────

  const importLibrary = async () => {
    setImporting('Finding RetroLauncher folder…')
    const folder = await findFolder('RetroLauncher')
    if (!folder) { setImporting('No "RetroLauncher" folder found in your Drive. Create it and add sub-folders GBA/ PSX/ GBC/.'); return }
    setImporting('Listing ROMs…')
    const files = await listRoms(folder.id)
    let n = 0
    for (const f of files) {
      await upsertRom({
        id: f.id, driveId: f.id, name: f.name, cleanName: f.cleanName,
        system: f.system, ext: f.ext, size: f.size, downloaded: false, lastPlayed: null,
      })
      n++
    }
    setImporting(`Imported ${n} games.`)
  }

  // ── Upload ROMs to Drive ────────────────────────────────────────────────────

  const classifyLocalFile = useCallback((file) => {
    const ext = file.name.split('.').pop().toLowerCase()
    const map = { gba:'GBA', gbc:'GBC', gb:'GBC', bin:'PSX', cue:'PSX', img:'PSX', chd:'PSX', pbp:'PSX' }
    return map[ext] || null
  }, [])

  const onFilesSelected = useCallback(async (e, mode = 'drive') => {
    const files = Array.from(e.target.files || [])
    e.target.value = ''
    if (!files.length) return

    const items = files.map(f => ({
      file: f, name: f.name,
      system: classifyLocalFile(f) || 'GBA',
      status: 'queued', progress: 0, error: '',
    })).filter(i => classifyLocalFile(i.file))

    if (!items.length) return
    setQueue(prev => [...prev, ...items])

    if (mode === 'local') {
      // Save directly to IndexedDB, no Drive
      for (let i = 0; i < items.length; i++) {
        const item = items[i]
        setQueue(prev => prev.map(q => q.name === item.name ? { ...q, status: 'uploading', progress: 0.5 } : q))
        await saveBlob(item.name, item.file)
        const romId = `local:${item.name}`
        await upsertRom({
          id: romId, driveId: null, name: item.name,
          cleanName: cleanRomName(item.name),
          system: item.system, ext: item.file.name.split('.').pop().toLowerCase(),
          size: item.file.size, downloaded: true, lastPlayed: null,
          localKey: item.name,
        })
        setQueue(prev => prev.map(q => q.name === item.name ? { ...q, status: 'local' } : q))
      }
      return
    }

    // Drive upload
    if (!authed) { alert('Connect Google Drive first'); return }
    setUploading(true)
    try {
      // Ensure folder structure exists
      if (!subfolderIdsRef.current) {
        const rootId = await ensureRootFolder('RetroLauncher')
        subfolderIdsRef.current = await ensureSubfolders(rootId)
      }
      const subfolderIds = subfolderIdsRef.current

      for (let i = 0; i < items.length; i++) {
        const item = items[i]
        setQueue(prev => prev.map(q => q.name === item.name ? { ...q, status: 'uploading' } : q))
        try {
          const result = await uploadRom(
            item.file, item.system, subfolderIds,
            (progress) => setQueue(prev => prev.map(q => q.name === item.name ? { ...q, progress } : q))
          )
          await upsertRom({
            id: result.id, driveId: result.id, name: item.name,
            cleanName: cleanRomName(item.name),
            system: item.system, ext: item.file.name.split('.').pop().toLowerCase(),
            size: item.file.size, downloaded: false, lastPlayed: null,
          })
          setQueue(prev => prev.map(q => q.name === item.name ? { ...q, status: 'done' } : q))
        } catch (err) {
          setQueue(prev => prev.map(q => q.name === item.name ? { ...q, status: 'error', error: err.message } : q))
        }
      }
    } finally {
      setUploading(false)
    }
  }, [authed, classifyLocalFile])

  // ── BIOS ────────────────────────────────────────────────────────────────────

  const onBiosFile = async (e) => {
    const file = e.target.files[0]
    if (!file) return
    const v = await validateBIOS(file)
    if (!v.valid) { setBiosStatus(`✗ ${v.reason}`); return }
    await saveBlob(`BIOS:${v.name}`, file)
    setBiosStatus(`✓ ${v.name} (${v.region}) verified & stored`)
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  const queueDone  = queue.filter(q => q.status === 'done' || q.status === 'local').length
  const queueError = queue.filter(q => q.status === 'error').length

  return (
    <motion.div className="page scroll-y" style={{ padding: 20 }}
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
      <button className="btn-info" style={{ padding:'6px 12px', marginBottom:16 }} onClick={() => nav('/')}>‹ Home</button>
      <h1 style={{ fontSize:24, fontWeight:700, marginBottom:4 }}>Settings</h1>
      <p style={{ ...HINT, marginBottom:24 }}>Your library lives in your own Google Drive. Nothing is uploaded to us.</p>

      {/* ── Google Drive ─────────────────────────────────────────────────── */}
      <h2 style={SECTION}>Google Drive</h2>
      <input
        value={clientId}
        onChange={e => setClientId(e.target.value)}
        placeholder="Google OAuth Client ID (from Google Cloud Console)"
        style={{ width:'100%', padding:12, borderRadius:8, background:'var(--c-surface)',
          border:'1px solid var(--c-border)', color:'#fff', marginBottom:10, boxSizing:'border-box' }}
      />
      {!authed
        ? <button className="btn-play" style={{ width:'100%', justifyContent:'center' }} onClick={connect}>Connect Drive</button>
        : <div style={{ display:'flex', gap:10 }}>
            <button className="btn-play" style={{ flex:1, justifyContent:'center' }} onClick={importLibrary}>
              Import Library
            </button>
            <button className="btn-info" style={{ flex:1, justifyContent:'center' }} onClick={() => setAuthed(false)}>
              Disconnect
            </button>
          </div>
      }
      {importing && <p style={{ ...HINT, marginTop:8 }}>{importing}</p>}

      <p style={{ ...HINT, marginTop:12 }}>
        Don't have a Client ID yet?{' '}
        <a href="https://console.cloud.google.com/" target="_blank" rel="noreferrer"
          style={{ color:'var(--c-accent2)' }}>Google Cloud Console</a>
        {' '}→ APIs & Services → Credentials → Create OAuth Client ID (Web).
        Add your launcher origin as an authorised origin.
      </p>

      {/* ── Upload ROMs to Drive ─────────────────────────────────────────── */}
      <h2 style={SECTION}>Upload ROMs to Drive</h2>
      <p style={HINT}>
        Pick your .gba / .gbc / .bin / .cue files directly — they'll be uploaded to the correct
        system subfolder in Drive and added to your library. On Mac, find ROMs from OpenEmu at{' '}
        <code style={{ fontSize:11 }}>~/Library/Application Support/OpenEmu/Game Library/roms/</code>.
        Run <code style={{ fontSize:11 }}>tools/find-roms-mac.sh</code> to scan all emulators at once.
      </p>
      <div style={{ display:'flex', gap:10, marginBottom:12 }}>
        <button
          className={authed ? 'btn-play' : 'btn-info'}
          style={{ flex:1, justifyContent:'center' }}
          disabled={uploading}
          onClick={() => fileInputRef.current?.click()}
        >
          {uploading ? 'Uploading…' : '↑ Upload to Drive'}
        </button>
        <button
          className="btn-info"
          style={{ flex:1, justifyContent:'center' }}
          onClick={() => localInputRef.current?.click()}
        >
          ↓ Import Local (no Drive)
        </button>
      </div>

      {/* hidden file pickers */}
      <input ref={fileInputRef} type="file" multiple
        accept=".gba,.gbc,.gb,.bin,.cue,.img,.chd,.pbp"
        style={{ display:'none' }}
        onChange={(e) => onFilesSelected(e, 'drive')} />
      <input ref={localInputRef} type="file" multiple
        accept=".gba,.gbc,.gb,.bin,.cue,.img,.chd,.pbp"
        style={{ display:'none' }}
        onChange={(e) => onFilesSelected(e, 'local')} />

      {/* Upload queue */}
      {queue.length > 0 && (
        <div style={{ background:'var(--c-surface)', borderRadius:10, padding:'8px 12px', marginBottom:12 }}>
          {queue.map((item, i) => <UploadItem key={`${item.name}-${i}`} item={item} />)}
          {queue.length > 0 && (
            <div style={{ fontSize:11, color:'var(--c-muted)', paddingTop:6 }}>
              {queueDone}/{queue.length} done{queueError ? ` · ${queueError} errors` : ''}
              {' — '}
              <button style={{ background:'none', color:'var(--c-accent2)', fontSize:11, padding:0 }}
                onClick={() => setQueue([])}>Clear</button>
            </div>
          )}
        </div>
      )}

      {/* Mac tip */}
      <div style={{ background:'var(--c-surface)', borderRadius:10, padding:12, marginBottom:4, fontSize:12, lineHeight:1.6 }}>
        <strong style={{ color:'var(--c-accent2)' }}>Mac tip</strong><br/>
        Run in Terminal to find all ROMs from OpenEmu, mGBA, RetroArch, DuckStation:
        <pre style={{ margin:'6px 0 0', padding:'6px 10px', background:'var(--c-surface2)',
          borderRadius:6, fontSize:11, overflowX:'auto', color:'#ccc' }}>
          {`cd ~/path/to/mangos/retro-launcher\n./tools/find-roms-mac.sh\n# Then:\n./tools/find-roms-mac.sh upload    # via rclone\n./tools/find-roms-mac.sh copy ~/Desktop/ROMs  # manual drag-drop`}
        </pre>
        Other cloud options: Dropbox or OneDrive work identically with rclone — swap <code>gdrive</code> for your remote name.
      </div>

      {/* ── PlayStation BIOS ─────────────────────────────────────────────── */}
      <h2 style={SECTION}>PlayStation BIOS</h2>
      <p style={HINT}>
        Required for PSX games. Use SCPH5501.BIN (US v3.0, most compatible with PCSX-ReARMed).
        Dump from your own console or use a verified copy. Hash-checked against the known-good MD5.
      </p>
      <input type="file" accept=".bin,.BIN" onChange={onBiosFile} style={{ fontSize:12 }} />
      {biosStatus && (
        <p style={{ fontSize:12, marginTop:6, color: biosStatus.startsWith('✓') ? '#46d369' : '#e50914' }}>
          {biosStatus}
        </p>
      )}

      {/* ── Feel & Comfort ───────────────────────────────────────────────── */}
      <h2 style={SECTION}>Feel & Comfort</h2>
      <Toggle label="Haptics" desc="Tactile button feedback" checked={flags.haptics} onChange={v => update('haptics', v)} />
      <Toggle label="Edge-slip buzz" desc="Subtle buzz as finger skids toward a button edge" checked={flags.edgeSlipHaptic} onChange={v => update('edgeSlipHaptic', v)} />
      <Toggle label="Edge pop" desc="Sharp pop when finger fully slides off a button" checked={flags.edgePopHaptic} onChange={v => update('edgePopHaptic', v)} />
      <Toggle label="Auto-landscape in game" desc="Rotate to GBA landscape automatically" checked={flags.rotationLock} onChange={v => update('rotationLock', v)} />
      <Toggle label="Pixel-perfect scaling" desc="Crisp integer upscale — no blurring" checked={flags.pixelPerfect} onChange={v => update('pixelPerfect', v)} />

      {/* ── Trust & Safety ───────────────────────────────────────────────── */}
      <h2 style={SECTION}>Trust & Safety</h2>
      <Toggle label="Verify PSX BIOS" desc="Hash-check BIOS before boot" checked={flags.validateBios} onChange={v => update('validateBios', v)} />
      <Toggle label="Validate ROMs" desc="Sanity-check ROM headers before launch" checked={flags.validateRoms} onChange={v => update('validateRoms', v)} />
      <Toggle label="Offline-first" desc="Download ROM to device before first launch" checked={flags.offlineFirst} onChange={v => update('offlineFirst', v)} />

      {/* ── Promos ───────────────────────────────────────────────────────── */}
      <h2 style={SECTION}>Promos</h2>
      <Toggle label="First-party banner" desc="Own shows / products only · never interrupts gameplay" checked={flags.showPromoBanner} onChange={v => update('showPromoBanner', v)} />
      <Toggle label="Between-session bumpers" desc="Own clips on exit (opt-in, skippable)" checked={flags.betweenSessionBumpers} onChange={v => update('betweenSessionBumpers', v)} />

      <button className="btn-info" style={{ width:'100%', justifyContent:'center', marginTop:28 }}
        onClick={() => nav('/admin')}>Admin / Experimental ›</button>

      <div style={{ height: 40 }} />
    </motion.div>
  )
}
