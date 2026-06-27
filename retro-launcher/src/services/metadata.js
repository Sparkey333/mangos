// Game metadata + box art — the "Netflix/Plex info pull" layer.
//
// Two free sources, no API key needed for the first:
//   1. libretro thumbnail database (cover/title/snap PNGs by exact game name)
//      https://github.com/libretro-thumbnails  — served raw via thumbnails.libretro.com
//   2. (Optional) IGDB for rich synopsis/genre/year/rating — needs a free Twitch
//      dev Client ID + token, configured in Settings.
//
// We try libretro art first (instant, keyless), then enrich with IGDB if configured.

const LIBRETRO_BASE = 'https://thumbnails.libretro.com'

const SYSTEM_DIR = {
  GBA: 'Nintendo - Game Boy Advance',
  GBC: 'Nintendo - Game Boy Color',
  GB:  'Nintendo - Game Boy',
  PSX: 'Sony - PlayStation',
}

// libretro encodes filenames: '&'->'_', and disallows some chars
function libretroName(name) {
  return name.replace(/[&*/:`<>?\\|"]/g, '_').trim()
}

export function getBoxArtUrl(system, gameName) {
  const dir = SYSTEM_DIR[system]
  if (!dir) return null
  const file = encodeURIComponent(libretroName(gameName)) + '.png'
  return `${LIBRETRO_BASE}/${encodeURIComponent(dir)}/Named_Boxarts/${file}`
}

export function getTitleScreenUrl(system, gameName) {
  const dir = SYSTEM_DIR[system]
  if (!dir) return null
  const file = encodeURIComponent(libretroName(gameName)) + '.png'
  return `${LIBRETRO_BASE}/${encodeURIComponent(dir)}/Named_Titles/${file}`
}

export function getSnapUrl(system, gameName) {
  const dir = SYSTEM_DIR[system]
  if (!dir) return null
  const file = encodeURIComponent(libretroName(gameName)) + '.png'
  return `${LIBRETRO_BASE}/${encodeURIComponent(dir)}/Named_Snaps/${file}`
}

// Enrich with IGDB (optional). Returns { summary, year, genres, rating, cover }.
export async function fetchIGDB(gameName, { clientId, token }) {
  if (!clientId || !token) return null
  const body = `search "${gameName.replace(/"/g, '')}"; fields name,summary,first_release_date,genres.name,total_rating,cover.image_id; limit 1;`
  try {
    const res = await fetch('https://api.igdb.com/v4/games', {
      method: 'POST',
      headers: {
        'Client-ID': clientId,
        Authorization: `Bearer ${token}`,
        'Content-Type': 'text/plain',
      },
      body,
    })
    if (!res.ok) return null
    const [game] = await res.json()
    if (!game) return null
    return {
      summary: game.summary || '',
      year: game.first_release_date ? new Date(game.first_release_date * 1000).getFullYear() : null,
      genres: (game.genres || []).map(g => g.name),
      rating: game.total_rating ? Math.round(game.total_rating) : null,
      cover: game.cover?.image_id
        ? `https://images.igdb.com/igdb/image/upload/t_cover_big/${game.cover.image_id}.jpg`
        : null,
    }
  } catch {
    return null
  }
}

// Resolve full metadata for one ROM: art always, synopsis if IGDB configured.
export async function resolveMetadata(rom, igdbCreds) {
  const meta = {
    boxArt: getBoxArtUrl(rom.system, rom.cleanName),
    titleScreen: getTitleScreenUrl(rom.system, rom.cleanName),
    snap: getSnapUrl(rom.system, rom.cleanName),
    summary: '',
    year: null,
    genres: [],
    rating: null,
  }
  if (igdbCreds?.clientId) {
    const igdb = await fetchIGDB(rom.cleanName, igdbCreds)
    if (igdb) {
      Object.assign(meta, {
        summary: igdb.summary,
        year: igdb.year,
        genres: igdb.genres,
        rating: igdb.rating,
        boxArt: igdb.cover || meta.boxArt, // prefer IGDB cover when available
      })
    }
  }
  return meta
}
