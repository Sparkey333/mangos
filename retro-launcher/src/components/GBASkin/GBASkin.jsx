import React, { useRef, useCallback, useEffect } from 'react'
import { HapticEngine } from '../HapticEngine/HapticEngine'
import './GBASkin.css'

// GBASkin renders the device shell as an overlay around the emulator canvas.
// Each button has a hit-zone and an inner "safe" zone. The gap between them is
// the edge band — when a pointer is in the band we fire edgeSlip haptics, and
// when it crosses fully out we fire edgePop. This recreates the physical feel
// of a finger skidding off a real GBA button.

const EDGE_BAND_PX = 9

const BUTTONS = [
  { id: 'up',    label: '▲', cls: 'dpad dpad--up' },
  { id: 'down',  label: '▼', cls: 'dpad dpad--down' },
  { id: 'left',  label: '◀', cls: 'dpad dpad--left' },
  { id: 'right', label: '▶', cls: 'dpad dpad--right' },
  { id: 'a',     label: 'A', cls: 'face face--a' },
  { id: 'b',     label: 'B', cls: 'face face--b' },
  { id: 'l',     label: 'L', cls: 'shoulder shoulder--l' },
  { id: 'r',     label: 'R', cls: 'shoulder shoulder--r' },
  { id: 'start', label: 'START',  cls: 'sys sys--start' },
  { id: 'select',label: 'SELECT', cls: 'sys sys--select' },
]

export default function GBASkin({ children, onInput, adminOverlay = false, skin = 'gba-classic' }) {
  const activePointers = useRef(new Map()) // pointerId -> { buttonId, inEdge }

  const handlePointerDown = useCallback((e, buttonId) => {
    e.currentTarget.setPointerCapture(e.pointerId)
    activePointers.current.set(e.pointerId, { buttonId, inEdge: false })
    HapticEngine.buttonPress(buttonId)
    onInput?.(buttonId, true)
  }, [onInput])

  const handlePointerMove = useCallback((e, buttonId) => {
    const state = activePointers.current.get(e.pointerId)
    if (!state) return
    const rect = e.currentTarget.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top
    const nearEdge =
      x < EDGE_BAND_PX || y < EDGE_BAND_PX ||
      x > rect.width - EDGE_BAND_PX || y > rect.height - EDGE_BAND_PX
    const outside = x < 0 || y < 0 || x > rect.width || y > rect.height

    if (outside && !state.popped) {
      // Finger fully slid off the button
      HapticEngine.stopEdgeSlip(buttonId, true)
      state.popped = true
      onInput?.(buttonId, false)
    } else if (nearEdge && !state.inEdge && !outside) {
      state.inEdge = true
      HapticEngine.startEdgeSlip(buttonId)
    } else if (!nearEdge && state.inEdge) {
      state.inEdge = false
      HapticEngine.stopEdgeSlip(buttonId, false)
    }
  }, [onInput])

  const handlePointerUp = useCallback((e, buttonId) => {
    const state = activePointers.current.get(e.pointerId)
    if (state && !state.popped) {
      HapticEngine.stopEdgeSlip(buttonId, false)
      HapticEngine.buttonRelease()
      onInput?.(buttonId, false)
    }
    activePointers.current.delete(e.pointerId)
  }, [onInput])

  return (
    <div className={`gba-shell gba-shell--${skin} ${adminOverlay ? 'gba-shell--admin' : ''}`}>
      <div className="gba-shoulders">
        {BUTTONS.filter(b => b.cls.startsWith('shoulder')).map(b => (
          <GButton key={b.id} btn={b}
            onDown={handlePointerDown} onMove={handlePointerMove} onUp={handlePointerUp} />
        ))}
      </div>

      <div className="gba-body">
        <div className="gba-dpad-cluster">
          {BUTTONS.filter(b => b.cls.startsWith('dpad')).map(b => (
            <GButton key={b.id} btn={b}
              onDown={handlePointerDown} onMove={handlePointerMove} onUp={handlePointerUp} />
          ))}
        </div>

        <div className="gba-screen-frame">
          <div className="gba-screen">{children}</div>
          <div className="gba-screen-brand">RetroLauncher</div>
        </div>

        <div className="gba-face-cluster">
          {BUTTONS.filter(b => b.cls.startsWith('face')).map(b => (
            <GButton key={b.id} btn={b}
              onDown={handlePointerDown} onMove={handlePointerMove} onUp={handlePointerUp} />
          ))}
        </div>
      </div>

      <div className="gba-sys-row">
        {BUTTONS.filter(b => b.cls.startsWith('sys')).map(b => (
          <GButton key={b.id} btn={b}
            onDown={handlePointerDown} onMove={handlePointerMove} onUp={handlePointerUp} />
        ))}
      </div>

      {adminOverlay && <div className="gba-admin-hud">EDGE BAND: {EDGE_BAND_PX}px · HAPTIC DEBUG</div>}
    </div>
  )
}

function GButton({ btn, onDown, onMove, onUp }) {
  return (
    <button
      className={`gba-btn gba-btn--${btn.cls.split(' ').join(' gba-btn--')}`}
      data-button={btn.id}
      onPointerDown={(e) => onDown(e, btn.id)}
      onPointerMove={(e) => onMove(e, btn.id)}
      onPointerUp={(e) => onUp(e, btn.id)}
      onPointerCancel={(e) => onUp(e, btn.id)}
      aria-label={btn.id}
    >
      <span className="gba-btn__label">{btn.label}</span>
    </button>
  )
}
