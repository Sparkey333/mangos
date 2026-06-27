// Demo mode — loads freely-distributable open-source homebrew ROMs so the
// launcher can be tested end-to-end without a Google Drive connection.
//
// ROM bytes are NOT bundled in this repo — demoUrl is fetched on first play
// and cached in IndexedDB; subsequent launches are fully offline.
//
// MIT licensed by original authors:
//   2048-GBA  — Jeroen Vloothuis  https://github.com/jvloothuis/2048-gba
//   libbet    — Damian Yerrick    https://github.com/pinobatch/libbet

const DEMO_ROMS = [
  {
    id:         'demo-2048-gba',
    name:       '2048.gba',
    cleanName:  '2048',
    system:     'GBA',
    ext:        'gba',
    size:       0,
    downloaded: false,
    lastPlayed: null,
    isDemo:     true,
    url:        'https://github.com/jvloothuis/2048-gba/releases/latest/download/2048.gba',
    summary:    'Classic 2048 sliding-tile puzzle ported to GBA. MIT licensed. D-pad to slide tiles, A to start.',
    year:       2014,
    genres:     ['Puzzle'],
  },
  {
    id:         'demo-libbet-gba',
    name:       'libbet.gba',
    cleanName:  'Libbet',
    system:     'GBA',
    ext:        'gba',
    size:       0,
    downloaded: false,
    lastPlayed: null,
    isDemo:     true,
    // pinobatch shuffleboard game — direct binary release, no ZIP wrapping
    url:        'https://github.com/pinobatch/libbet/releases/latest/download/libbet.gba',
    summary:    'Shuffleboard / bowling GBA homebrew by pinobatch. MIT licensed. Tests audio, sprites, and background scrolling.',
    year:       2019,
    genres:     ['Demo'],
  },
]

export default DEMO_ROMS

// Seed the local library with demo ROM metadata (blobs fetched on play).
export async function seedDemoLibrary(upsertRom) {
  for (const rom of DEMO_ROMS) {
    await upsertRom({
      id:         rom.id,
      name:       rom.name,
      cleanName:  rom.cleanName,
      system:     rom.system,
      ext:        rom.ext,
      size:       rom.size,
      downloaded: false,
      lastPlayed: null,
      isDemo:     true,
      demoUrl:    rom.url,
    })
  }
  return DEMO_ROMS.length
}
