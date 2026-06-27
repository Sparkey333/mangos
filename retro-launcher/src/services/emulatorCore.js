// Emulator core bridge. The launcher itself doesn't emulate — it hands ROM bytes
// to a proven WASM core. Default: EmulatorJS (RetroArch cores compiled to WASM),
// which supports GBA (mGBA), GBC (Gambatte), and PSX (Beetle/PCSX-ReArmed).
//
// On native iOS this same screen can instead deep-link into Delta or RetroArch
// via URL scheme — see launchExternal(). That gives best-in-class speed; the
// in-app WASM path gives a seamless no-app-switch experience.

export const CORE_MAP = {
  GBA: 'mgba',
  GBC: 'gambatte',
  GB:  'gambatte',
  PSX: 'pcsx_rearmed', // good balance of speed/compat on mobile
}

// Mount ROM (and BIOS for PSX) then boot EmulatorJS inside a container element.
export async function bootEmulatorJS({ container, system, romBlob, romName, biosBlob, onSave }) {
  const core = CORE_MAP[system]
  if (!core) throw new Error(`No core mapped for system ${system}`)

  const romUrl = URL.createObjectURL(romBlob)
  const biosUrl = (system === 'PSX' && biosBlob) ? URL.createObjectURL(biosBlob) : null

  // Revoke object URLs once the emulator has loaded its data — they persist in
  // memory otherwise and accumulate across game launches.
  const revokeUrls = () => {
    URL.revokeObjectURL(romUrl)
    if (biosUrl) URL.revokeObjectURL(biosUrl)
  }

  // EmulatorJS reads these globals before its loader script runs
  window.EJS_player = '#ejs-screen'
  window.EJS_core = core
  window.EJS_gameUrl = romUrl
  window.EJS_gameName = romName
  window.EJS_startOnLoaded = true
  window.EJS_pathtodata = 'https://cdn.emulatorjs.org/stable/data/'

  if (biosUrl) window.EJS_biosUrl = biosUrl

  // Hide EmulatorJS's own on-screen controls — we render our own GBA skin
  window.EJS_Buttons = {
    playPause: false, restart: false, mute: false,
    settings: true, fullscreen: false, saveState: true, loadState: true,
    gamepad: false, cheat: false,
  }

  window.EJS_onSaveState = (e) => onSave?.('state', e.state)
  window.EJS_onGameStart = () => {
    console.info('[emu] game started:', romName)
    revokeUrls()
  }

  container.innerHTML = '<div id="ejs-screen" style="width:100%;height:100%"></div>'

  await loadScriptOnce('https://cdn.emulatorjs.org/stable/data/loader.js')
  return { romUrl }
}

// Map our GBA skin button ids to EmulatorJS / RetroArch input events.
const KEY_MAP = {
  up: 'UP', down: 'DOWN', left: 'LEFT', right: 'RIGHT',
  a: 'A', b: 'B', l: 'L', r: 'R', start: 'START', select: 'SELECT',
}

export function sendInput(buttonId, pressed) {
  const key = KEY_MAP[buttonId]
  if (!key) return
  // EmulatorJS exposes a gameManager once booted
  if (window.EJS_emulator?.gameManager) {
    window.EJS_emulator.gameManager.simulateInput(0, key, pressed ? 1 : 0)
  }
}

// Native iOS deep-link fallback — open the ROM in Delta or RetroArch.
export function launchExternal(app, system, romName) {
  const schemes = {
    delta: `delta://launch?game=${encodeURIComponent(romName)}`,
    retroarch: `retroarch://`,
  }
  const url = schemes[app]
  if (url) window.location.href = url
}

const loaded = new Set()
function loadScriptOnce(src) {
  if (loaded.has(src)) return Promise.resolve()
  return new Promise((resolve, reject) => {
    const s = document.createElement('script')
    s.src = src
    s.onload = () => { loaded.add(src); resolve() }
    s.onerror = reject
    document.body.appendChild(s)
  })
}
