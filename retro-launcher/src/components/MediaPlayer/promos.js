// First-party promo manifest. Owner-controlled. No third-party ad networks.
// Drop your own bumpers / show trailers / product cards here. These are the
// ONLY things that can ever appear in the AdBanner.
//
// Each promo: { id, title, kicker, thumb, href, clip? }
//   clip — optional local/own video used for between-session bumpers (Toonami /
//          Adult-Swim style), never an interrupt mid-game.

export const PROMOS = [
  {
    id: 'bumper-toonami-style',
    kicker: 'NEXT UP',
    title: 'Late Night Block — own bumpers reel',
    thumb: '/icons/promo-bumper.png',
    href: '#',
    clip: '/clips/block-bumper.mp4',
  },
  {
    id: 'own-show-1',
    kicker: 'NOW SHOWING',
    title: 'Your Original Series — Ep. 1',
    thumb: '/icons/promo-show.png',
    href: '#',
  },
  {
    id: 'own-product-1',
    kicker: 'FROM THE STUDIO',
    title: 'Merch drop — limited skins pack',
    thumb: '/icons/promo-merch.png',
    href: '#',
  },
]

// Bumpers played between game sessions (on exit-to-library), opt-in, skippable.
export const BUMPERS = [
  { id: 'b1', clip: '/clips/block-bumper.mp4', maxSeconds: 6, skippable: true },
]
