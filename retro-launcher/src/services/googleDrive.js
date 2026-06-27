// Google Drive integration — lists ROM/BIOS files from a user-selected folder,
// downloads them into IndexedDB for offline play, uploads new ROMs, and syncs
// save files back up.
//
// Auth: Google Identity Services (GIS) token client — OAuth2 with drive.file +
// drive.readonly scope. No client secret in the browser; uses PKCE implicit flow.
//
// Folder layout expected in Drive:
//   RetroLauncher/
//     GBA/    ← .gba files
//     GBC/    ← .gbc / .gb files
//     PSX/    ← .bin + .cue pairs (or .chd)
//     saves/  ← save states synced back up automatically

const DRIVE_API  = 'https://www.googleapis.com/drive/v3'
const UPLOAD_API = 'https://www.googleapis.com/upload/drive/v3'
const SCOPES = [
  'https://www.googleapis.com/auth/drive.readonly',
  'https://www.googleapis.com/auth/drive.file',
].join(' ')

let tokenClient  = null
let accessToken  = null
let tokenExpiry  = 0   // epoch ms; tokens last ~1 hour

// ── Auth ─────────────────────────────────────────────────────────────────────

export function initDriveAuth(clientId, onToken) {
  if (!window.google?.accounts?.oauth2) {
    throw new Error('Google Identity Services not loaded')
  }
  tokenClient = window.google.accounts.oauth2.initTokenClient({
    client_id: clientId,
    scope: SCOPES,
    callback: (resp) => {
      accessToken = resp.access_token
      tokenExpiry = Date.now() + ((resp.expires_in || 3600) - 60) * 1000
      onToken?.(resp)
    },
  })
}

export function requestAccess() {
  if (!tokenClient) throw new Error('Call initDriveAuth first')
  tokenClient.requestAccessToken({ prompt: '' })
}

export function isAuthed() {
  return Boolean(accessToken) && Date.now() < tokenExpiry
}

// Re-request token silently if expired; resolves once a fresh token is in hand.
export function ensureToken() {
  if (isAuthed()) return Promise.resolve()
  if (!tokenClient) return Promise.reject(new Error('Drive not initialised — go to Settings'))
  return new Promise((resolve, reject) => {
    const orig = tokenClient.callback
    tokenClient.callback = (resp) => {
      if (resp.error) { tokenClient.callback = orig; reject(new Error(resp.error)); return }
      accessToken = resp.access_token
      tokenExpiry = Date.now() + ((resp.expires_in || 3600) - 60) * 1000
      tokenClient.callback = orig
      resolve()
    }
    tokenClient.requestAccessToken({ prompt: '' })
  })
}

// ── Core fetch helper ─────────────────────────────────────────────────────────

async function driveFetch(path, params = {}) {
  await ensureToken()
  const url = new URL(`${DRIVE_API}${path}`)
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v))
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  if (!res.ok) throw new Error(`Drive API ${res.status}: ${await res.text()}`)
  return res.json()
}

async function drivePost(path, body) {
  await ensureToken()
  const res = await fetch(`${DRIVE_API}${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error(`Drive POST ${res.status}: ${await res.text()}`)
  return res.json()
}

// ── Folder helpers ────────────────────────────────────────────────────────────

function escapeName(name) {
  return name.replace(/\\/g, '\\\\').replace(/'/g, "\\'")
}

// Find a folder by name. Optional parentId scopes the search.
export async function findFolder(name = 'RetroLauncher', parentId = null) {
  const safe = escapeName(name)
  let q = `mimeType='application/vnd.google-apps.folder' and name='${safe}' and trashed=false`
  if (parentId) q += ` and '${parentId}' in parents`
  const data = await driveFetch('/files', { q, fields: 'files(id,name)' })
  return data.files[0] || null
}

// Create a Drive folder under an optional parent.
export async function createFolder(name, parentId = null) {
  const meta = { name, mimeType: 'application/vnd.google-apps.folder' }
  if (parentId) meta.parents = [parentId]
  const data = await drivePost('/files', meta)
  return data.id
}

// Get or create the root RetroLauncher folder.
export async function ensureRootFolder(folderName = 'RetroLauncher') {
  const existing = await findFolder(folderName)
  if (existing) return existing.id
  return createFolder(folderName)
}

// Get or create GBA/, GBC/, PSX/, saves/ subfolders inside rootId.
// Returns { GBA, GBC, PSX, saves } map of folder IDs.
export async function ensureSubfolders(rootId) {
  const systems = ['GBA', 'GBC', 'PSX', 'saves']
  const result = {}
  await Promise.all(systems.map(async (sys) => {
    const found = await findFolder(sys, rootId)
    result[sys] = found ? found.id : await createFolder(sys, rootId)
  }))
  return result
}

// ── ROM listing ───────────────────────────────────────────────────────────────

// List ROM/BIOS files — walks the root folder AND one level of system subfolders.
export async function listRoms(folderId) {
  // First pass: everything directly in root
  const root = await listFolderContents(folderId)
  const roms = root.files.filter(f => !f.isFolder).map(classifyFile).filter(Boolean)

  // Walk into any subfolder (GBA/, PSX/, GBC/, etc.)
  const subs = root.files.filter(f => f.isFolder)
  await Promise.all(subs.map(async sub => {
    const inner = await listFolderContents(sub.id)
    inner.files.forEach(f => {
      if (f.isFolder) return
      const classified = classifyFile(f, sub.name.toUpperCase())
      if (classified) roms.push(classified)
    })
  }))

  return roms
}

async function listFolderContents(folderId) {
  const data = await driveFetch('/files', {
    q: `'${folderId}' in parents and trashed=false`,
    fields: 'files(id,name,size,mimeType,modifiedTime)',
    pageSize: '1000',
    orderBy: 'name',
  })
  return {
    files: data.files.map(f => ({
      ...f,
      isFolder: f.mimeType === 'application/vnd.google-apps.folder',
    })),
  }
}

function classifyFile(f, folderHint = null) {
  if (f.isFolder) return null
  const ext = f.name.split('.').pop().toLowerCase()
  const EXT_SYS = {
    gba: 'GBA', gbc: 'GBC', gb: 'GBC',
    bin: 'PSX', cue: 'PSX', img: 'PSX', chd: 'PSX', pbp: 'PSX',
  }
  // Use folder name as hint when extension is ambiguous (.bin can be anything)
  let system = EXT_SYS[ext]
  if (!system && folderHint && ['GBA','GBC','PSX'].includes(folderHint)) {
    system = folderHint
  }
  if (!system) return null
  return {
    id: f.id,
    name: f.name,
    cleanName: cleanRomName(f.name),
    size: Number(f.size || 0),
    system,
    ext,
    modifiedTime: f.modifiedTime,
    isFolder: false,
  }
}

export function cleanRomName(filename) {
  return filename
    .replace(/\.[^.]+$/, '')
    .replace(/\([^)]*\)/g, '')
    .replace(/\[[^\]]*\]/g, '')
    .replace(/[._]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

// ── Download ─────────────────────────────────────────────────────────────────

export async function downloadFile(fileId, onProgress) {
  await ensureToken()
  const res = await fetch(`${DRIVE_API}/files/${fileId}?alt=media`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  if (!res.ok) throw new Error(`Download failed: ${res.status}`)

  const total = Number(res.headers.get('content-length') || 0)
  const reader = res.body.getReader()
  const chunks = []
  let received = 0
  for (;;) {
    const { done, value } = await reader.read()
    if (done) break
    chunks.push(value)
    received += value.length
    if (total) onProgress?.(received / total)
  }
  return new Blob(chunks)
}

// ── Upload ────────────────────────────────────────────────────────────────────

// Upload a File or Blob to Drive with progress reporting.
// Returns the created Drive file object.
export async function uploadFile(file, folderId, onProgress) {
  await ensureToken()

  // 1. Initiate resumable upload session
  const initRes = await fetch(`${UPLOAD_API}/files?uploadType=resumable`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      'X-Upload-Content-Type': file.type || 'application/octet-stream',
      'X-Upload-Content-Length': String(file.size),
    },
    body: JSON.stringify({
      name: file.name,
      parents: [folderId],
    }),
  })
  if (!initRes.ok) throw new Error(`Upload init failed: ${initRes.status}`)
  const uploadUrl = initRes.headers.get('Location')

  // 2. PUT the file bytes with XHR so we get upload progress events
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest()
    xhr.open('PUT', uploadUrl)
    xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream')
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) onProgress?.(e.loaded / e.total)
    }
    xhr.onload = () => {
      if (xhr.status === 200 || xhr.status === 201) {
        try { resolve(JSON.parse(xhr.responseText)) }
        catch { resolve({}) }
      } else {
        reject(new Error(`Upload failed: ${xhr.status}`))
      }
    }
    xhr.onerror = () => reject(new Error('Upload network error'))
    xhr.send(file instanceof File ? file : new File([file], file.name || 'file'))
  })
}

// Upload a ROM File to the correct system subfolder.
// subfolderIds = { GBA, GBC, PSX } returned by ensureSubfolders().
export async function uploadRom(file, system, subfolderIds, onProgress) {
  const folderId = subfolderIds[system] || subfolderIds.GBA
  return uploadFile(file, folderId, onProgress)
}

// ── Save sync ─────────────────────────────────────────────────────────────────

// Upload or overwrite a save file in Drive's saves/ subfolder.
export async function uploadSave(savesFolderId, name, blob, existingId = null) {
  await ensureToken()
  const metadata = { name }
  if (!existingId) metadata.parents = [savesFolderId]

  const form = new FormData()
  form.append('metadata', new Blob([JSON.stringify(metadata)], { type: 'application/json' }))
  form.append('file', blob, name)

  const method = existingId ? 'PATCH' : 'POST'
  const url = existingId
    ? `${UPLOAD_API}/files/${existingId}?uploadType=multipart`
    : `${UPLOAD_API}/files?uploadType=multipart`

  const res = await fetch(url, {
    method,
    headers: { Authorization: `Bearer ${accessToken}` },
    body: form,
  })
  if (!res.ok) throw new Error(`Save upload failed: ${res.status}`)
  return res.json()
}

// Find a save file in Drive by name in savesFolderId
export async function findSave(savesFolderId, name) {
  const safe = escapeName(name)
  const data = await driveFetch('/files', {
    q: `'${savesFolderId}' in parents and name='${safe}' and trashed=false`,
    fields: 'files(id,name,modifiedTime)',
  })
  return data.files[0] || null
}
