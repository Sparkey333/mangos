// "1 chosen + 2 runners-up" download policy.
//
// When the user picks a game we commit it to device storage immediately, then
// quietly pre-stage the two most-likely next plays so they're instant too.
// Everything else stays in Drive until tapped — keeps storage lean, keeps the
// next taps instant.

import { db, getBlob, saveBlob, getContinuePlaying, getRoms } from './localLibrary'
import { downloadFile, isAuthed } from './googleDrive'

// Pick the 2 runners-up: next in Continue Playing, then same-system siblings.
export async function pickRunnersUp(chosenRom, limit = 2) {
  const recent = await getContinuePlaying(8)
  const all = await getRoms()
  const pool = []

  for (const r of recent) {
    if (r.id !== chosenRom.id) pool.push(r)
  }
  // Fill with same-system titles not already queued
  for (const r of all) {
    if (pool.length >= limit + 4) break
    if (r.id === chosenRom.id) continue
    if (r.system === chosenRom.system && !pool.find(p => p.id === r.id)) pool.push(r)
  }
  return pool.slice(0, limit)
}

// Commit chosen + prefetch runners-up in the background (non-blocking).
export async function commitAndPrefetch(chosenRom) {
  if (!isAuthed()) return { committed: false, reason: 'not-authed' }

  // 1. Commit the chosen game (await — user is about to play it)
  let blob = await getBlob(chosenRom.id)
  if (!blob) {
    blob = await downloadFile(chosenRom.driveId || chosenRom.id)
    await saveBlob(chosenRom.id, blob)
    await db.roms.update(chosenRom.id, { downloaded: true })
  }

  // 2. Prefetch runners-up without blocking
  const runners = await pickRunnersUp(chosenRom, 2)
  runners.forEach(async (r) => {
    const existing = await getBlob(r.id)
    if (existing) return
    try {
      const b = await downloadFile(r.driveId || r.id)
      await saveBlob(r.id, b)
      await db.roms.update(r.id, { downloaded: true })
    } catch {
      /* runner-up prefetch is best-effort; ignore failures */
    }
  })

  return { committed: true, runnersUp: runners.map(r => r.cleanName) }
}
