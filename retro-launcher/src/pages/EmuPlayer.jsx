import React, { useEffect, useRef, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import GBASkin from '../components/GBASkin/GBASkin'
import { db, getBlob, saveBlob, recordPlay } from '../services/localLibrary'
import { downloadFile, isAuthed } from '../services/googleDrive'
import { bootEmulatorJS, sendInput } from '../services/emulatorCore'
import { validateBIOS, validateGBAROM } from '../utils/trust'
import { lockLandscape, unlockOrientation } from '../utils/rotation'
import { useFeatureFlags } from '../components/AdminPanel/FeatureFlags'
import { HapticEngine } from '../components/HapticEngine/HapticEngine'

// Full-screen game player: locks landscape, boots core, wraps screen in GBA skin.
export default function EmuPlayer() {
  const { id } = useParams()
  const nav = useNavigate()
  const screenRef = useRef(null)
  const { flags } = useFeatureFlags()
  const [status, setStatus] = useState('Preparing…')
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    HapticEngine.setEnabled(flags.haptics)
    HapticEngine.setEdgeSlipEnabled(flags.edgeSlipHaptic)
    if (flags.rotationLock) lockLandscape()

    let cancelled = false
    ;(async () => {
      const rom = await db.roms.get(id)
      if (!rom) { setStatus('ROM not found'); return }

      // Resolve ROM bytes: local cache first, else download from Drive
      let romBlob = await getBlob(rom.id)
      if (!romBlob) {
        if (rom.isDemo && rom.demoUrl) {
          // Demo ROMs are free open-source homebrew — fetch directly from their
          // official public release URL, no Drive auth needed.
          setStatus('Fetching demo ROM…')
          const res = await fetch(rom.demoUrl)
          if (!res.ok) { setStatus(`Demo fetch failed: ${res.status}`); return }
          romBlob = await res.blob()
        } else {
          if (!isAuthed()) { setStatus('Connect Google Drive in Settings first'); return }
          setStatus('Downloading from Drive…')
          romBlob = await downloadFile(rom.driveId || rom.id, p => !cancelled && setProgress(p))
        }
        await saveBlob(rom.id, romBlob)
        await db.roms.update(rom.id, { downloaded: true })
      }

      // Trust checks
      if (flags.validateRoms && rom.system === 'GBA') {
        const v = await validateGBAROM(new File([romBlob], rom.name))
        if (!v.valid) { setStatus(`Blocked: ${v.reason}`); return }
      }

      let biosBlob = null
      if (rom.system === 'PSX') {
        biosBlob = await getBlob('BIOS:SCPH5501.BIN')
        if (flags.validateBios && biosBlob) {
          const v = await validateBIOS(new File([biosBlob], 'SCPH5501.BIN'))
          if (!v.valid) { setStatus(`BIOS error: ${v.reason}`); return }
        }
        if (!biosBlob) { setStatus('PSX BIOS missing — add SCPH5501.BIN in Settings'); return }
      }

      if (cancelled) return
      setStatus('Booting…')
      await recordPlay(rom.id)
      await bootEmulatorJS({
        container: screenRef.current,
        system: rom.system,
        romBlob,
        romName: rom.cleanName,
        biosBlob,
        onSave: (kind, data) => saveBlob(`save:${rom.id}`, new Blob([data])),
      })
      setStatus('')
    })().catch(e => setStatus(`Error: ${e.message}`))

    return () => {
      cancelled = true
      if (flags.rotationLock) unlockOrientation()
    }
  }, [id])

  return (
    <div className="page" style={{ background: '#000' }}>
      <GBASkin
        skin={flags.skin}
        adminOverlay={flags.adminMode && flags.showHitZones}
        onInput={sendInput}
      >
        <div ref={screenRef} style={{ width: '100%', height: '100%' }} />
        {status && (
          <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 13, gap: 8 }}>
            <div>{status}</div>
            {progress > 0 && progress < 1 && (
              <div style={{ width: 140, height: 4, background: '#333', borderRadius: 2 }}>
                <div style={{ width: `${progress * 100}%`, height: '100%', background: 'var(--c-accent2)', borderRadius: 2 }} />
              </div>
            )}
          </div>
        )}
      </GBASkin>

      <button onClick={() => nav('/')}
        style={{ position: 'absolute', top: 8, left: 8, zIndex: 10, fontSize: 12,
          background: 'rgba(0,0,0,0.6)', padding: '4px 10px', borderRadius: 6, color: '#fff' }}>
        ‹ Exit
      </button>
    </div>
  )
}
