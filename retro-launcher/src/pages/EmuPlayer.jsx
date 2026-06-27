import React, { useEffect, useRef, useState, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import GBASkin from '../components/GBASkin/GBASkin'
import { db, getBlob, saveBlob, recordPlay, setSetting } from '../services/localLibrary'
import { downloadFile, isAuthed } from '../services/googleDrive'
import { bootEmulatorJS, sendInput } from '../services/emulatorCore'
import { validateBIOS, validateGBAROM } from '../utils/trust'
import { lockLandscape, unlockOrientation } from '../utils/rotation'
import { useFeatureFlags } from '../components/AdminPanel/FeatureFlags'
import { HapticEngine } from '../components/HapticEngine/HapticEngine'
import { pushSave, pullSave } from '../services/saveSync'

// Full-screen game player: locks landscape, boots core, wraps screen in GBA skin.
export default function EmuPlayer() {
  const { id }    = useParams()
  const nav       = useNavigate()
  const screenRef = useRef(null)
  const { flags } = useFeatureFlags()

  const [status, setStatus]     = useState('Preparing…')
  const [progress, setProgress] = useState(0)
  const [booted, setBooted]     = useState(false)
  const [ff, setFf]             = useState(false)
  const [showMenu, setShowMenu] = useState(false)

  // Boot sequence
  useEffect(() => {
    HapticEngine.setEnabled(flags.haptics)
    HapticEngine.setEdgeSlipEnabled(flags.edgeSlipHaptic)
    if (flags.rotationLock) lockLandscape()

    let cancelled = false
    ;(async () => {
      const rom = await db.roms.get(id)
      if (!rom) { setStatus('ROM not found'); return }

      let romBlob = await getBlob(rom.id)
      if (!romBlob && rom.localKey) romBlob = await getBlob(rom.localKey)

      if (!romBlob) {
        if (rom.isDemo && rom.demoUrl) {
          setStatus('Fetching demo ROM…')
          const res = await fetch(rom.demoUrl)
          if (!res.ok) { setStatus('Demo fetch failed: ' + res.status); return }
          romBlob = await res.blob()
        } else {
          if (!isAuthed()) { setStatus('Connect Google Drive in Settings first'); return }
          setStatus('Downloading from Drive…')
          romBlob = await downloadFile(rom.driveId || rom.id, p => !cancelled && setProgress(p))
        }
        await saveBlob(rom.id, romBlob)
        await db.roms.update(rom.id, { downloaded: true })
      }

      if (flags.validateRoms && rom.system === 'GBA') {
        const v = await validateGBAROM(new File([romBlob], rom.name))
        if (!v.valid) { setStatus('Blocked: ' + v.reason); return }
      }

      let biosBlob = null
      if (rom.system === 'PSX') {
        biosBlob = await getBlob('BIOS:SCPH5501.BIN')
        if (flags.validateBios && biosBlob) {
          const v = await validateBIOS(new File([biosBlob], 'SCPH5501.BIN'))
          if (!v.valid) { setStatus('BIOS error: ' + v.reason); return }
        }
        if (!biosBlob) { setStatus('PSX BIOS missing — add SCPH5501.BIN in Settings'); return }
      }

      if (cancelled) return

      if (isAuthed()) await pullSave(rom.id, rom.cleanName).catch(() => {})

      setStatus('Booting…')
      await recordPlay(rom.id)
      await bootEmulatorJS({
        container: screenRef.current,
        system:    rom.system,
        romBlob,
        romName:   rom.cleanName,
        biosBlob,
        onSave: async (kind, data) => {
          await saveBlob('save:' + rom.id, new Blob([data]))
          await setSetting('saveTime:' + rom.id, String(Date.now()))
          pushSave(rom.id, rom.cleanName).catch(() => {})
        },
      })
      setStatus('')
      setBooted(true)
    })().catch(e => setStatus('Error: ' + e.message))

    return () => {
      cancelled = true
      if (flags.rotationLock) unlockOrientation()
    }
  }, [id])

  const saveState = useCallback(() => {
    window.EJS_emulator?.gameManager?.saveState?.()
    HapticEngine.fire('buttonPress')
  }, [])

  const loadState = useCallback(() => {
    window.EJS_emulator?.gameManager?.loadState?.()
    HapticEngine.fire('buttonPress')
  }, [])

  const toggleFF = useCallback(() => {
    setFf(prev => {
      const next = !prev
      window.EJS_emulator?.gameManager?.functions?.setSpeed?.(next ? 3 : 1)
      HapticEngine.fire('buttonPress')
      return next
    })
  }, [])

  return (
    <div className="page" style={{ background: '#000', position: 'relative' }}>
      <GBASkin
        skin={flags.skin}
        adminOverlay={flags.adminMode && flags.showHitZones}
        onInput={sendInput}
      >
        <div ref={screenRef} style={{ width: '100%', height: '100%' }} />

        {status && (
          <div style={{ position:'absolute', inset:0, display:'flex', flexDirection:'column',
            alignItems:'center', justifyContent:'center', color:'#fff', fontSize:13, gap:8,
            background:'rgba(0,0,0,0.6)' }}>
            <div>{status}</div>
            {progress > 0 && progress < 1 && (
              <div style={{ width:140, height:4, background:'#333', borderRadius:2 }}>
                <div style={{ width:(progress*100)+'%', height:'100%', background:'var(--c-accent2)', borderRadius:2 }} />
              </div>
            )}
          </div>
        )}
      </GBASkin>

      {booted && (
        <div style={{ position:'absolute', top:8, right:8, zIndex:20, display:'flex', gap:6 }}>
          <HudBtn onClick={toggleFF} active={ff} label={ff ? '⏩ 3\xd7' : '⏩'} title="Fast-forward" />
          <HudBtn onClick={saveState} label="💾" title="Save state" />
          <HudBtn onClick={loadState} label="↩" title="Load state" />
          <HudBtn onClick={() => setShowMenu(m => !m)} label="⋯" title="Menu" />
        </div>
      )}

      <button onClick={() => nav('/')}
        style={{ position:'absolute', top:8, left:8, zIndex:20, fontSize:12,
          background:'rgba(0,0,0,0.55)', padding:'5px 10px', borderRadius:6, color:'#fff' }}>
        ‹ Exit
      </button>

      {ff && (
        <div style={{ position:'absolute', bottom:60, left:'50%', transform:'translateX(-50%)',
          zIndex:20, fontSize:11, color:'#fff', background:'rgba(0,0,0,0.5)',
          padding:'2px 8px', borderRadius:4, letterSpacing:1, pointerEvents:'none' }}>
          3\xd7 SPEED
        </div>
      )}

      {showMenu && (
        <div style={{ position:'absolute', inset:0, zIndex:30, background:'rgba(0,0,0,0.75)',
          display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:12 }}
          onClick={() => setShowMenu(false)}>
          <div onClick={e => e.stopPropagation()} style={{
            background:'var(--c-surface)', borderRadius:16, padding:'20px 28px',
            minWidth:220, display:'flex', flexDirection:'column', gap:10 }}>
            <div style={{ fontWeight:700, fontSize:15, marginBottom:4 }}>Game Menu</div>
            <MenuBtn onClick={() => { saveState(); setShowMenu(false) }} label="💾 Save State" />
            <MenuBtn onClick={() => { loadState(); setShowMenu(false) }} label="↩ Load State" />
            <MenuBtn onClick={() => { toggleFF(); setShowMenu(false) }}
              label={ff ? '⏩ Speed: 3\xd7 (tap to reset)' : '⏩ Fast-Forward (3\xd7)'} />
            <div style={{ height:1, background:'var(--c-border)', margin:'4px 0' }} />
            <MenuBtn onClick={() => nav('/settings')} label="⚙ Settings" />
            <MenuBtn onClick={() => nav('/')} label="‹ Exit to Home" danger />
          </div>
        </div>
      )}
    </div>
  )
}

function HudBtn({ onClick, label, title, active }) {
  return (
    <button onClick={onClick} title={title}
      style={{
        background: active ? 'var(--c-accent2)' : 'rgba(0,0,0,0.55)',
        color: active ? '#000' : '#fff',
        border: 'none', borderRadius: 6, padding: '5px 9px',
        fontSize: 13, cursor: 'pointer', fontWeight: 600,
      }}>
      {label}
    </button>
  )
}

function MenuBtn({ onClick, label, danger }) {
  return (
    <button onClick={onClick}
      style={{
        width: '100%', padding: '11px 14px', borderRadius: 10, textAlign: 'left',
        background: danger ? 'rgba(229,9,20,0.12)' : 'var(--c-surface2)',
        color: danger ? '#e50914' : 'var(--c-text)', fontSize: 14, fontWeight: 500,
      }}>
      {label}
    </button>
  )
}
