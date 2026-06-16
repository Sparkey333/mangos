/* ============================================================================
 * TEMPLE HUNTERS — Prism Ascent
 * data.js  —  The Seven Hunters
 *
 * Each Hunter encodes one strand of the "unified theory" the game is built on:
 *   color  <->  light frequency (THz)  <->  solfeggio sound tone (Hz)
 *          <->  stone / gem  <->  sacred geometry  <->  chakra
 *          <->  a material layer historically carried to the Great Pyramid.
 *
 * This file is pure DATA. The sprite renderer (sprites.js) and the battle
 * engine (game.js) both read from THE_SEVEN. Add an 8th creature here and it
 * shows up everywhere automatically.
 * ========================================================================== */

const THE_SEVEN = [
  {
    id: 0,
    name: "PYROKK",
    title: "Guardian of the Root Layer",
    colorName: "Red",
    base: "#e23b2e", shade: "#9c1f1a", light: "#ff7a5e", gem: "#7a0d12",
    chakra: "Muladhara — Root",
    lightTHz: 430,           // visible red ~430 THz
    toneHz: 396,             // solfeggio: liberating fear / grounding
    note: "C",
    stone: "Garnet / Bloodstone",
    geometry: "Cube (Earth)",
    pyramidLayer: "Aswan Red Granite — hauled ~900 km down the Nile for the King's Chamber",
    ornament: "horns",
    stats: { hp: 130, atk: 26, def: 22, spd: 12 },
    moves: [
      { name: "Stone Fist", power: 22, kind: "phys", text: "slams the bedrock" },
      { name: "396 Tremor", power: 30, kind: "tone", text: "sounds the root tone — the floor shakes" }
    ],
    blurb: "Dense, patient, immovable. Pyrokk is the foundation everything else is stacked upon."
  },
  {
    id: 1,
    name: "EMBYRX",
    title: "Guardian of the Sacral Layer",
    colorName: "Orange",
    base: "#f08a25", shade: "#a8530c", light: "#ffc06a", gem: "#7a3a00",
    chakra: "Svadhisthana — Sacral",
    lightTHz: 490,
    toneHz: 417,             // solfeggio: undoing situations / change
    note: "D",
    stone: "Carnelian / Amber",
    geometry: "Tetrahedron (Fire)",
    pyramidLayer: "Basalt pavement — quarried at Widan el-Faras, dragged from the Fayum",
    ornament: "ears",
    stats: { hp: 112, atk: 24, def: 16, spd: 22 },
    moves: [
      { name: "Ember Dash", power: 20, kind: "phys", text: "darts in trailing sparks" },
      { name: "417 Flux", power: 28, kind: "tone", text: "a tone of change unmakes the moment" }
    ],
    blurb: "Restless heat. Embyrx is motion, appetite, and the first spark of creation."
  },
  {
    id: 2,
    name: "SOLARA",
    title: "Guardian of the Solar Layer",
    colorName: "Yellow",
    base: "#f2cf1b", shade: "#b6900a", light: "#fff27a", gem: "#7a5e00",
    chakra: "Manipura — Solar Plexus",
    lightTHz: 520,
    toneHz: 528,             // solfeggio: the "miracle" / DNA repair tone
    note: "E",
    stone: "Citrine / Tiger's Eye",
    geometry: "Octahedron (Air)",
    pyramidLayer: "Core Limestone — the local Giza bedrock the mass was cut from",
    ornament: "spikes",
    stats: { hp: 118, atk: 25, def: 18, spd: 19 },
    moves: [
      { name: "Sun Lash", power: 21, kind: "phys", text: "a whip of focused light" },
      { name: "528 Bloom", power: 29, kind: "tone", text: "the miracle tone — repairs and burns at once" }
    ],
    blurb: "Will and clarity. Solara is the noon power that drives the whole climb."
  },
  {
    id: 3,
    name: "VERDYN",
    title: "Guardian of the Heart Layer",
    colorName: "Green",
    base: "#3fb24a", shade: "#1f7a2c", light: "#8cf08c", gem: "#0d5a1f",
    chakra: "Anahata — Heart",
    lightTHz: 560,
    toneHz: 639,             // solfeggio: connection / relationships
    note: "F",
    stone: "Emerald / Malachite",
    geometry: "Icosahedron (Water)",
    pyramidLayer: "Copper & Malachite — mined in Sinai for the tools and seals",
    ornament: "leaves",
    stats: { hp: 140, atk: 21, def: 24, spd: 14 },
    moves: [
      { name: "Vine Bind", power: 19, kind: "phys", text: "roots coil and squeeze" },
      { name: "639 Mend", power: 24, kind: "tone", text: "the heart tone — restores and links allies" }
    ],
    blurb: "The hinge of the spectrum. Verdyn heals, binds, and holds the party together."
  },
  {
    id: 4,
    name: "AZULON",
    title: "Guardian of the Throat Layer",
    colorName: "Blue",
    base: "#2f6fe0", shade: "#163f96", light: "#7aa8ff", gem: "#0d245a",
    chakra: "Vishuddha — Throat",
    lightTHz: 640,
    toneHz: 741,             // solfeggio: expression / awakening intuition
    note: "G",
    stone: "Sapphire / Turquoise",
    geometry: "Dodecahedron (Aether)",
    pyramidLayer: "Tura White Limestone & Sinai Turquoise — the casing ferried across the Nile",
    ornament: "fins",
    stats: { hp: 120, atk: 23, def: 19, spd: 20 },
    moves: [
      { name: "Tide Cut", power: 20, kind: "phys", text: "a clean blade of water" },
      { name: "741 Word", power: 28, kind: "tone", text: "the throat tone — sound made into force" }
    ],
    blurb: "Voice and flow. Azulon turns intention into vibration you can feel."
  },
  {
    id: 5,
    name: "INDIGOS",
    title: "Guardian of the Brow Layer",
    colorName: "Indigo",
    base: "#4b32b0", shade: "#2a1a73", light: "#9a7aff", gem: "#16093f",
    chakra: "Ajna — Third Eye",
    lightTHz: 680,
    toneHz: 852,             // solfeggio: returning to spiritual order
    note: "A",
    stone: "Amethyst / Lapis Lazuli",
    geometry: "Merkaba (Star Tetrahedron)",
    pyramidLayer: "Dolerite & Diorite — the hard pounders from the Eastern Desert that shaped the granite",
    ornament: "antennae",
    stats: { hp: 116, atk: 27, def: 17, spd: 21 },
    moves: [
      { name: "Mind Spike", power: 22, kind: "phys", text: "a lance of pure focus" },
      { name: "852 Sight", power: 30, kind: "tone", text: "the brow tone — sees the strike before it lands" }
    ],
    blurb: "Perception and pattern. Indigos reads the lattice connecting every layer below."
  },
  {
    id: 6,
    name: "VIOLETTE",
    title: "Guardian of the Crown Layer",
    colorName: "Violet",
    base: "#9a3fd6", shade: "#5e1f96", light: "#d79aff", gem: "#3a0d5a",
    chakra: "Sahasrara — Crown",
    lightTHz: 750,           // visible violet ~750 THz
    toneHz: 963,             // solfeggio: oneness / the crown tone
    note: "B",
    stone: "Selenite / Sugilite",
    geometry: "Flower of Life (Sphere)",
    pyramidLayer: "Egyptian Alabaster & the Gold Pyramidion — the calcite and capstone that crowned the apex",
    ornament: "halo",
    stats: { hp: 124, atk: 26, def: 20, spd: 18 },
    moves: [
      { name: "Prism Touch", power: 21, kind: "phys", text: "all seven colors in one strike" },
      { name: "963 Crown", power: 31, kind: "tone", text: "the crown tone — the spectrum closes into white" }
    ],
    blurb: "The capstone. Violette is where the seven rays converge back into a single light."
  }
];

/* Type chart — the color wheel as a balanced cycle.
 * Each Hunter is strong against the color 3 steps ahead and weak to 3 behind. */
function effectiveness(attackerId, defenderId) {
  if (attackerId === defenderId) return 1.0;
  const fwd = ((defenderId - attackerId) + 7) % 7; // 1..6
  return (fwd >= 1 && fwd <= 3) ? 1.5 : 0.75;
}

/* ============================================================================
 * THE HIDDEN TIERS — 8, 9, and the Void.
 *
 * The seven are the visible spectrum. Beyond them the structure keeps going,
 * hidden yet always there to be researched, measured, and held loosely toward
 * the truth. These are NOT in the roster. They surface only as whispers (for
 * now) — the design space the whole game eventually grows into.
 *
 *   8 — UNITY      : all seven held as one. White light. The octave. ∞ upright.
 *   9 — OUROBOROS  : the dragon eating its tail. The dark cycle, eternal return,
 *                    the shadow that must rise to be seen by the light.
 *   0 — THE VOID   : the Nothing. Outside polarity entirely. Forgetting,
 *                    un-creation — and the single grain that rebuilds it all.
 * ========================================================================== */
const THE_HIDDEN = [
  {
    glyph: "8", key: "unity",
    name: "AUREON", title: "The Eighth — Unity",
    base: "#ffffff", shade: "#cfc4ff", light: "#ffffff", gem: "#bfa8ff",
    chakra: "Soul Star — the 8th center, above the crown",
    light_: "Full-spectrum white — all seven rays converged",
    toneHz: 792,            // octave of the 396 root: the spiral returns home, higher
    note: "G (octave)",
    stone: "Clear Quartz / Diamond / Pearl (the stone that holds all stones)",
    geometry: "The completed Flower of Life — the pyramid whole, base rejoined to capstone",
    meaning:
      "Not an eighth creature but the seven remembered as one organism — the " +
      "collective consciousness, magnetism in the bone, the prism reassembled " +
      "into a single living light. The polar opposite of the Ninth.",
    blurb: "When the seven stop holding the weight separately and become one, the spectrum closes to white."
  },
  {
    glyph: "9", key: "ouroboros",
    name: "OUROBOS", title: "The Ninth — The Tail-Eater",
    base: "#0c0a14", shade: "#1a1530", light: "#3a2f5e", gem: "#5e1f96",
    chakra: "Earth Star — below the feet, the root of the root",
    light_: "No light returned — the swallowing dark that defines the edge of all light",
    toneHz: 198,            // sub-octave below the 396 root: the drone beneath
    note: "G (sub-octave)",
    stone: "Obsidian / Onyx / Black Tourmaline / Shungite",
    geometry: "The Ouroboros ring — the torus, the lemniscate ∞ laid down, the spiral that returns",
    meaning:
      "The dragon eating its tail. Not evil — the necessary dark, the cocoon, " +
      "the night before dawn, eternal return. The turbulence you ride before " +
      "the resync. All shadow either rises into the light or is blinded by it.",
    blurb: "The cycle that must be ridden. Darkness that exists so the night can finally see the Light."
  },
  {
    glyph: "0", key: "void",
    name: "THE NOTHING", title: "The Void — Null",
    base: "#000000", shade: "#000000", light: "#0a0a0a", gem: "#101010",
    chakra: "None — the absence of center",
    light_: "Neither light nor dark — the un-being that erases the question itself",
    toneHz: 0,             // silence. the tone that is no tone.
    note: "— (silence)",
    stone: "None — the stone that was never quarried",
    geometry: "Null — outside the spiral, outside the ring, outside the seven",
    meaning:
      "Not the Ninth's productive darkness but the absence of story itself — " +
      "forgetting, despair, the un-creation. It spreads where dreaming stops; " +
      "selfish wishes feed it by trading away memory. (The Nothing, of the " +
      "Neverending tale.) Its only answer is a single grain of imagination — " +
      "one name, one remembered thing — from which all of it is rebuilt.",
    blurb: "The Emptiness that forgets. A single grain of sand, named and remembered, undoes it."
  }
];

if (typeof module !== "undefined") module.exports = { THE_SEVEN, THE_HIDDEN, effectiveness };
if (typeof window !== "undefined") { window.THE_SEVEN = THE_SEVEN; window.THE_HIDDEN = THE_HIDDEN; }

