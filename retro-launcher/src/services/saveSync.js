// Save-state sync: after every manual save, push the state blob to Drive so
// progress is preserved across devices. On first launch of a new game, pull
// the most recent Drive save if no local save exists yet.

import { getBlob, saveBlob, getSetting } from './localLibrary'
import { findFolder, findSave, uploadSave, downloadFile, isAuthed } from './googleDrive'

let savesFolderId = null

// Resolve (and cache) the Drive saves/ subfolder id.
async function getSavesFolderId() {
  if (savesFolderId) return savesFolderId
  const root = await findFolder('RetroLauncher')
  if (!root) return null
  const saves = await findFolder('saves', root.id)
  savesFolderId = saves?.id || null
  return savesFolderId
}

// Push a local save blob up to Drive. No-op if Drive not connected.
export async function pushSave(romId, romName) {
  if (!isAuthed()) return
  const folderId = await getSavesFolderId()
  if (!folderId) return

  const blob = await getBlob(`save:${romId}`)
  if (!blob) return

  const filename = `${romName}.sav`
  const existing = await findSave(folderId, filename)
  await uploadSave(folderId, filename, blob, existing?.id || null)
}

// Pull a Drive save down to local IndexedDB if the local copy is absent or
// older than the Drive copy. Returns true if a save was pulled.
export async function pullSave(romId, romName) {
  if (!isAuthed()) return false
  const folderId = await getSavesFolderId()
  if (!folderId) return false

  const filename = `${romName}.sav`
  const driveSave = await findSave(folderId, filename)
  if (!driveSave) return false

  // If we already have a local save, compare timestamps
  const localBlob = await getBlob(`save:${romId}`)
  const localModified = Number(await getSetting(`saveTime:${romId}`, '0'))
  const driveModified = new Date(driveSave.modifiedTime).getTime()

  if (localBlob && localModified >= driveModified) return false

  // Drive save is newer — pull it
  const blob = await downloadFile(driveSave.id)
  await saveBlob(`save:${romId}`, blob)
  return true
}
