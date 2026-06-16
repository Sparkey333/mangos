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
 * Each Hunter is strong against the three colors that follow it around the
 * rainbow, and weak to the three behind it. Mirror match is neutral. */
function effectiveness(attackerId, defenderId) {
  if (attackerId === defenderId) return 1.0;
  const fwd = ((defenderId - attackerId) + 7) % 7; // 1..6
  return (fwd >= 1 && fwd <= 3) ? 1.5 : 0.75;
}

if (typeof module !== "undefined") module.exports = { THE_SEVEN, effectiveness };
