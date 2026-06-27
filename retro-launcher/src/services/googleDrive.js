// Google Drive integration — lists ROM/BIOS files from a user-selected folder,
// downloads them into IndexedDB for offline play, and syncs save files back up.
//
// Auth: Google Identity Services (GIS) token client — OAuth2 with drive.file +
// drive.readonly scope. No client secret in the browser; uses PKCE implicit flow.
//
// Setup the user must do once (documented in docs/SETUP.md):
//   1. Create a Google Cloud project
//   2. Enable Drive API
//   3. Create an OAuth Client ID (Web) and add the launcher origin
//   4. Paste the Client ID into Settings

const DRIVE_API = 'https://www.googleapis.com/drive/v3'
const SCOPES = 'https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/drive.file'

let tokenClient = null
let accessToken = null

export function initDriveAuth(clientId, onToken) {
  if (!window.google?.accounts?.oauth2) {
    throw new Error('Google Identity Services not loaded')
  }
  tokenClient = window.google.accounts.oauth2.initTokenClient({
    client_id: clientId,
    scope: SCOPES,
    callback: (resp) => {
      accessToken = resp.access_token
      onToken?.(resp)
    },
  })
}

export function requestAccess() {
  if (!tokenClient) throw new Error('Call initDriveAuth first')
  tokenClient.requestAccessToken({ prompt: '' })
}

export function isAuthed() {
  return Boolean(accessToken)
}

async function driveFetch(path, params = {}) {
  const url = new URL(`${DRIVE_API}${path}`)
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v))
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  if (!res.ok) throw new Error(`Drive API ${res.status}: ${await res.text()}`)
  return res.json()
}

// Find the user's "RetroLauncher" folder (or any folder by name)
export async function findFolder(name = 'RetroLauncher') {
  // Escape single quotes in the name so they don't break the Drive query syntax.
  const safe = name.replace(/\\/g, '\\\\').replace(/'/g, "\\'")
  const data = await driveFetch('/files', {
    q: `mimeType='application/vnd.google-apps.folder' and name='${safe}' and trashed=false`,
    fields: 'files(id,name)',
  })
  return data.files[0] || null
}

// List ROM/BIOS files in a folder (recursively one level into system subfolders)
export async function listRoms(folderId) {
  const data = await driveFetch('/files', {
    q: `'${folderId}' in parents and trashed=false`,
    fields: 'files(id,name,size,mimeType,modifiedTime,parents)',
    pageSize: '1000',
    orderBy: 'name',
  })
  return data.files.map(classifyFile).filter(Boolean)
}

function classifyFile(f) {
  const ext = f.name.split('.').pop().toLowerCase()
  const systems = {
    gba: 'GBA', gbc: 'GBC', gb: 'GB',
    bin: 'PSX', cue: 'PSX', img: 'PSX', chd: 'PSX', pbp: 'PSX',
  }
  const system = systems[ext]
  if (!system && f.mimeType !== 'application/vnd.google-apps.folder') return null
  return {
    id: f.id,
    name: f.name,
    cleanName: cleanRomName(f.name),
    size: Number(f.size || 0),
    system,
    ext,
    modifiedTime: f.modifiedTime,
    isFolder: f.mimeType === 'application/vnd.google-apps.folder',
  }
}

export function cleanRomName(filename) {
  return filename
    .replace(/\.[^.]+$/, '')              // strip extension
    .replace(/\([^)]*\)/g, '')            // strip (USA), (Rev 1)
    .replace(/\[[^\]]*\]/g, '')           // strip [!], [b1]
    .replace(/[._]/g, ' ')
    .trim()
}

// Download a file's bytes (with progress callback) for local play
export async function downloadFile(fileId, onProgress) {
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

// Upload / overwrite a save file (.sav / memcard) back to Drive
export async function uploadSave(folderId, name, blob, existingId = null) {
  const metadata = { name, parents: existingId ? undefined : [folderId] }
  const form = new FormData()
  form.append('metadata', new Blob([JSON.stringify(metadata)], { type: 'application/json' }))
  form.append('file', blob)

  const method = existingId ? 'PATCH' : 'POST'
  const url = existingId
    ? `https://www.googleapis.com/upload/drive/v3/files/${existingId}?uploadType=multipart`
    : `https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart`

  const res = await fetch(url, {
    method,
    headers: { Authorization: `Bearer ${accessToken}` },
    body: form,
  })
  if (!res.ok) throw new Error(`Save upload failed: ${res.status}`)
  return res.json()
}
