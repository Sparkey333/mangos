// IndexedDB-backed local library via Dexie.
// Stores ROM blobs, BIOS blobs, save files, metadata, and play history.

import Dexie from 'dexie'

export const db = new Dexie('RetroLauncher')

db.version(1).stores({
  roms:    'id, name, system, lastPlayed, downloaded',
  blobs:   'id',                 // id -> { data: Blob } large ROM/BIOS bytes
  saves:   'romId, driveId, modifiedTime',
  meta:    'romId',              // scraped metadata (cover, synopsis, year...)
  history: '++id, romId, ts',    // play sessions for "Continue Playing"
  settings:'key',                // app + admin flags
})

export async function upsertRom(rom) {
  await db.roms.put(rom)
}

export async function getRoms(system = null) {
  if (system) return db.roms.where('system').equals(system).toArray()
  return db.roms.toArray()
}

export async function saveBlob(id, data) {
  await db.blobs.put({ id, data })
}

export async function getBlob(id) {
  const row = await db.blobs.get(id)
  return row?.data || null
}

export async function setMeta(romId, meta) {
  await db.meta.put({ romId, ...meta })
}

export async function getMeta(romId) {
  return db.meta.get(romId)
}

export async function recordPlay(romId) {
  await db.history.add({ romId, ts: Date.now() })
  await db.roms.update(romId, { lastPlayed: Date.now() })
}

export async function getContinuePlaying(limit = 10) {
  const roms = await db.roms.orderBy('lastPlayed').reverse().limit(limit).toArray()
  return roms.filter(r => r.lastPlayed)
}

export async function getSetting(key, fallback = null) {
  const row = await db.settings.get(key)
  return row ? row.value : fallback
}

export async function setSetting(key, value) {
  await db.settings.put({ key, value })
}
