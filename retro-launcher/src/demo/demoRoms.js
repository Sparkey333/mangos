// Demo mode — loads freely-distributable open-source homebrew ROMs so the
// launcher can be tested end-to-end without a Google Drive connection or
// any commercial ROMs.
//
// Homebrew sources used here are MIT/public domain licensed:
//   • 2048-gba by Jeroen Vloothuis (MIT) — a complete, playable GBA port of 2048
//     https://github.com/jvloothuis/2048-gba / releases as 2048.gba
//
//   • Tyrian for GBA (open-source port) — kept as runner-up
//
// The ROM bytes are NOT bundled in this repo (they're binary blobs).
// Instead, demoMode() fetches them from their official public release URLs.
// These are first-party releases by the original open-source authors.

const DEMO_ROMS = [
  {
    id: 'demo-2048-gba',
    name: '2048.gba',
    cleanName: '2048',
    system: 'GBA',
    ext: 'gba',
    size: 0,      // filled after fetch
    downloaded: false,
    lastPlayed: null,
    isDemo: true,
    // Primary: official GitHub release of the open-source 2048 GBA port
    url: 'https://github.com/jvloothuis/2048-gba/releases/latest/download/2048.gba',
    boxArt: null,   // will fall back to libretro thumbnails via cleanName
    summary: 'The classic 2048 sliding-tile puzzle, ported to GBA. MIT licensed. Use A to start, D-pad to slide tiles.',
    year: 2014,
    genres: ['Puzzle'],
  },
  {
    id: 'demo-pong-gba',
    name: 'pong.gba',
    cleanName: 'Pong (Demo)',
    system: 'GBA',
    ext: 'gba',
    size: 0,
    downloaded: false,
    lastPlayed: null,
    isDemo: true,
    // devkitPro TONC demo ROM — public domain tutorial ROM widely used for testing
    url: 'https://www.coranac.com/files/tonc/bin/brin_demo.zip',
    summary: 'Public domain TONC tutorial demo. Good for testing the boot pipeline.',
    year: 2005,
    genres: ['Demo'],
  },
]

export default DEMO_ROMS

// Seed the local library with demo ROMs (metadata only; blobs fetched on play).
// Call this from Settings or a first-launch screen when Drive is not connected.
export async function seedDemoLibrary(upsertRom) {
  for (const rom of DEMO_ROMS) {
    await upsertRom({
      id:          rom.id,
      name:        rom.name,
      cleanName:   rom.cleanName,
      system:      rom.system,
      ext:         rom.ext,
      size:        rom.size,
      downloaded:  false,
      lastPlayed:  null,
      isDemo:      true,
      demoUrl:     rom.url,
    })
  }
  return DEMO_ROMS.length
}
