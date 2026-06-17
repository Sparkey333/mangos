/* ============================================================
   WANDR — Data layer
   Destinations, the adaptive question bank, segment recommendations,
   and the "Shadow Profile" trait model.
   In production these would be served by your backend + a real LLM;
   here they're a self-contained dataset so the prototype runs offline.
   ============================================================ */

// The dimensions that make up a user's "Shadow Profile" preference vector.
// Each value lives on a 0..1 scale; the agent updates them as it learns.
const TRAITS = [
  { key: "adventure", label: "Adventure",   blurb: "Adrenaline, the unknown, off-trail" },
  { key: "comfort",   label: "Comfort",     blurb: "Ease, rest, low-friction logistics" },
  { key: "culture",   label: "Culture",     blurb: "History, art, local life, museums" },
  { key: "nature",    label: "Nature",      blurb: "Wilderness, landscapes, open air" },
  { key: "social",    label: "Social",      blurb: "Nightlife, crowds, meeting people" },
  { key: "spontaneity",label:"Spontaneity", blurb: "Loose plans, room to wander" },
  { key: "luxury",    label: "Luxury",      blurb: "Premium stays, fine dining" },
  { key: "foodie",    label: "Foodie",      blurb: "Cuisine as the main event" },
];

// Destination catalog. `vec` is each place's affinity across the trait axes.
const DESTINATIONS = [
  { id: "kyoto", name: "Kyoto & the Kansai loop", region: "Japan", emoji: "⛩️",
    cover: "linear-gradient(135deg,#e96443,#904e95)",
    tagline: "Temples at dawn, izakaya at night, and a bullet train spine that makes two weeks feel effortless.",
    bestMonths: [3,4,10,11], dayCost: 180,
    tags: ["culture","food","walkable","temples"],
    vec: { adventure:.4, comfort:.7, culture:.95, nature:.5, social:.55, spontaneity:.5, luxury:.6, foodie:.9 } },

  { id: "patagonia", name: "Patagonia traverse", region: "Chile & Argentina", emoji: "🏔️",
    cover: "linear-gradient(135deg,#2af598,#009efd)",
    tagline: "Glaciers, granite spires, and trekking days that earn their wine. Big country, big silence.",
    bestMonths: [11,12,1,2], dayCost: 160,
    tags: ["hiking","wilderness","epic","remote"],
    vec: { adventure:.95, comfort:.3, culture:.3, nature:.98, social:.25, spontaneity:.6, luxury:.35, foodie:.5 } },

  { id: "lisbon", name: "Lisbon & the Algarve", region: "Portugal", emoji: "🌅",
    cover: "linear-gradient(135deg,#f6d365,#fda085)",
    tagline: "Tiled hills and trams up top, golden cliffs and seafood down south. Easy, warm, unhurried.",
    bestMonths: [5,6,9,10], dayCost: 120,
    tags: ["coast","food","relaxed","value"],
    vec: { adventure:.4, comfort:.75, culture:.7, nature:.6, social:.7, spontaneity:.7, luxury:.5, foodie:.85 } },

  { id: "morocco", name: "Marrakech to the Sahara", region: "Morocco", emoji: "🐫",
    cover: "linear-gradient(135deg,#ff9966,#ff5e62)",
    tagline: "Souk chaos, riad calm, Atlas passes, and a night under more stars than you've ever counted.",
    bestMonths: [3,4,10,11], dayCost: 110,
    tags: ["culture","desert","sensory","adventure"],
    vec: { adventure:.75, comfort:.45, culture:.9, nature:.7, social:.6, spontaneity:.65, luxury:.55, foodie:.8 } },

  { id: "iceland", name: "Iceland ring road", region: "Iceland", emoji: "🌋",
    cover: "linear-gradient(135deg,#4facfe,#00f2fe)",
    tagline: "Waterfalls, black sand, geothermal soaks, and a self-drive loop with no wrong turns.",
    bestMonths: [6,7,8,9], dayCost: 220,
    tags: ["roadtrip","nature","dramatic","selfdrive"],
    vec: { adventure:.8, comfort:.55, culture:.35, nature:.97, social:.3, spontaneity:.8, luxury:.5, foodie:.45 } },

  { id: "bali", name: "Bali & the Gilis", region: "Indonesia", emoji: "🌴",
    cover: "linear-gradient(135deg,#43e97b,#38f9d7)",
    tagline: "Rice terraces, reef snorkels, slow mornings, and villas that cost less than your rent.",
    bestMonths: [5,6,7,8,9], dayCost: 90,
    tags: ["beach","wellness","value","relaxed"],
    vec: { adventure:.55, comfort:.8, culture:.6, nature:.75, social:.6, spontaneity:.65, luxury:.7, foodie:.65 } },

  { id: "italy", name: "Rome, Florence & the coast", region: "Italy", emoji: "🍝",
    cover: "linear-gradient(135deg,#fa709a,#fee140)",
    tagline: "Ruins, Renaissance, and three plates of pasta a day with zero apologies.",
    bestMonths: [4,5,6,9,10], dayCost: 170,
    tags: ["culture","food","classic","romance"],
    vec: { adventure:.35, comfort:.7, culture:.95, nature:.45, social:.7, spontaneity:.5, luxury:.7, foodie:.95 } },

  { id: "vietnam", name: "Vietnam north-to-south", region: "Vietnam", emoji: "🛵",
    cover: "linear-gradient(135deg,#30cfd0,#330867)",
    tagline: "Hanoi buzz, Ha Long karsts, Hoi An lanterns, and street food that ruins you for home.",
    bestMonths: [2,3,4,10,11], dayCost: 70,
    tags: ["food","adventure","value","sensory"],
    vec: { adventure:.7, comfort:.5, culture:.8, nature:.7, social:.7, spontaneity:.75, luxury:.35, foodie:.9 } },

  { id: "newzealand", name: "New Zealand South Island", region: "New Zealand", emoji: "🥾",
    cover: "linear-gradient(135deg,#0ba360,#3cba92)",
    tagline: "Fiords, alpine lakes, and a campervan loop built for people who say 'one more hike'.",
    bestMonths: [12,1,2,3], dayCost: 170,
    tags: ["hiking","roadtrip","nature","adventure"],
    vec: { adventure:.9, comfort:.55, culture:.35, nature:.97, social:.35, spontaneity:.7, luxury:.45, foodie:.55 } },

  { id: "greece", name: "Athens & the Cyclades", region: "Greece", emoji: "🏛️",
    cover: "linear-gradient(135deg,#2193b0,#6dd5ed)",
    tagline: "Marble ruins, island hops, white-and-blue afternoons, and sunsets that feel staged.",
    bestMonths: [5,6,9,10], dayCost: 150,
    tags: ["islands","culture","romance","relaxed"],
    vec: { adventure:.45, comfort:.75, culture:.85, nature:.6, social:.75, spontaneity:.6, luxury:.7, foodie:.8 } },

  { id: "peru", name: "Peru: Cusco & the Andes", region: "Peru", emoji: "🦙",
    cover: "linear-gradient(135deg,#c79081,#dfa579)",
    tagline: "Inca trails, high plateaus, and a food scene that quietly became one of the world's best.",
    bestMonths: [5,6,7,8,9], dayCost: 110,
    tags: ["hiking","culture","food","altitude"],
    vec: { adventure:.85, comfort:.45, culture:.9, nature:.85, social:.45, spontaneity:.6, luxury:.45, foodie:.8 } },

  { id: "thailand", name: "Bangkok & the Andaman", region: "Thailand", emoji: "🐠",
    cover: "linear-gradient(135deg,#f093fb,#f5576c)",
    tagline: "Temples and night markets, then longtail boats to islands that look Photoshopped.",
    bestMonths: [11,12,1,2,3], dayCost: 80,
    tags: ["beach","food","nightlife","value"],
    vec: { adventure:.6, comfort:.7, culture:.65, nature:.7, social:.85, spontaneity:.75, luxury:.55, foodie:.85 } },
];

// Per-segment recommendation pools. The agent scores these against the
// Shadow Profile, so the same destination surfaces different options per user.
function segmentRecs(dest) {
  return {
    stay: {
      icon: "🏨", title: "Where you sleep", searchNote: "scanned 240+ stays",
      options: [
        { id:"boutique", name:"Design-led boutique hotel", price:"$$$", desc:"Small, characterful, walkable to the good stuff.", vec:{ luxury:.8, culture:.6, comfort:.7, social:.5 } },
        { id:"local", name:"Local guesthouse / riad / ryokan", price:"$$", desc:"Hosted, authentic, a little rough at the edges in the best way.", vec:{ culture:.9, adventure:.6, comfort:.4, foodie:.6 } },
        { id:"resort", name:"Full-service resort + spa", price:"$$$$", desc:"You don't lift a finger. Pool, spa, room service, repeat.", vec:{ comfort:.95, luxury:.9, social:.4, adventure:.1 } },
        { id:"basecamp", name:"Adventure base camp / lodge", price:"$$", desc:"Gear room, early breakfasts, trailheads out the door.", vec:{ adventure:.95, nature:.9, comfort:.3, social:.4 } },
      ],
    },
    experiences: {
      icon: "🎒", title: "What you do", searchNote: "ranked by your profile",
      options: [
        { id:"guided", name:"Small-group signature day", price:"$$", desc:"A vetted guide takes the logistics; you take the photos.", vec:{ comfort:.7, culture:.7, social:.6, adventure:.4 } },
        { id:"wild", name:"Self-guided trek / paddle", price:"$", desc:"Just you, a route, and a packed lunch. Big payoff.", vec:{ adventure:.95, nature:.9, spontaneity:.7, social:.2 } },
        { id:"deepdive", name:"Cultural deep-dive workshop", price:"$$", desc:"Cook, craft, or learn with locals. Hands dirty, brain on.", vec:{ culture:.95, foodie:.7, social:.6, adventure:.3 } },
        { id:"slow", name:"Unscheduled wander days", price:"free", desc:"No itinerary. Coffee, side streets, whatever you find.", vec:{ spontaneity:.95, comfort:.5, social:.5, culture:.5 } },
      ],
    },
    food: {
      icon: "🍷", title: "How you eat", searchNote: "matched to your palate",
      options: [
        { id:"tasting", name:"A standout tasting menu", price:"$$$$", desc:"One unforgettable, book-ahead dinner per trip.", vec:{ luxury:.9, foodie:.95, culture:.5, social:.4 } },
        { id:"street", name:"Street food crawl", price:"$", desc:"Plastic stools, no menus, the best meal of the week.", vec:{ foodie:.9, adventure:.7, social:.8, spontaneity:.7 } },
        { id:"market", name:"Market + cook-it-yourself", price:"$$", desc:"Shop the morning market, learn a dish, eat your work.", vec:{ foodie:.85, culture:.8, social:.6, adventure:.4 } },
        { id:"easy", name:"Reliable neighborhood gems", price:"$$", desc:"No drama, consistently great, walkable from your stay.", vec:{ comfort:.8, foodie:.6, social:.5, spontaneity:.4 } },
      ],
    },
    pace: {
      icon: "⏱️", title: "Your daily rhythm", searchNote: "calibrated to your energy",
      options: [
        { id:"packed", name:"Dawn-to-dusk, see it all", price:"high energy", desc:"Maximize the days; rest when you're home.", vec:{ adventure:.7, culture:.7, social:.6, comfort:.2 } },
        { id:"balanced", name:"Two anchors a day, then free", price:"balanced", desc:"One morning thing, one evening thing, slack in between.", vec:{ comfort:.6, spontaneity:.6, culture:.5, social:.5 } },
        { id:"languid", name:"Slow, long, lingering", price:"easy", desc:"Late starts, long lunches, nowhere to be.", vec:{ comfort:.85, spontaneity:.8, luxury:.6, social:.4 } },
      ],
    },
  };
}

/* ---------- The adaptive question bank ----------
   Each question is tagged with the traits it informs (`reads`) and each
   option carries weight deltas the agent applies to the Shadow Profile.
   `phase` controls when it can surface: "intake" (up front) or
   "crucial" (at a decision point during narrowing).                       */
const QUESTION_BANK = [
  { id:"q_motive", phase:"intake", reads:["adventure","culture","comfort"],
    q:"When this trip is over, what do you want to have felt?",
    why:"Your core motive shapes everything downstream — I anchor on it first.",
    options:[
      { label:"Pushed, alive, a little scared", emoji:"⚡", sub:"Adventure-led", w:{ adventure:.9, comfort:.1, spontaneity:.6 } },
      { label:"Curious and a bit wiser", emoji:"📜", sub:"Culture-led", w:{ culture:.9, foodie:.5, adventure:.3 } },
      { label:"Truly rested for once", emoji:"🌊", sub:"Restoration-led", w:{ comfort:.9, luxury:.5, spontaneity:.4 } },
      { label:"Full — of food and place", emoji:"🍽️", sub:"Sensory-led", w:{ foodie:.9, culture:.6, social:.5 } },
    ]},
  { id:"q_pace", phase:"intake", reads:["comfort","spontaneity","adventure"],
    q:"Picture your ideal day on the road. Which is closer?",
    why:"Pace is the single best predictor of trip satisfaction — and the most personal.",
    options:[
      { label:"Up at 6, three things before lunch", emoji:"🌄", sub:"High tempo", w:{ adventure:.7, comfort:.1, spontaneity:.3 } },
      { label:"One plan, then see where it goes", emoji:"🧭", sub:"Loose", w:{ spontaneity:.9, comfort:.4 } },
      { label:"Slow mornings, no alarms", emoji:"☕", sub:"Languid", w:{ comfort:.9, luxury:.4, spontaneity:.5 } },
    ]},
  { id:"q_spend", phase:"intake", reads:["luxury","comfort"],
    q:"Where would you rather the money go?",
    why:"Tells me how to weight the splurge-vs-stretch tradeoff in recommendations.",
    options:[
      { label:"One incredible room", emoji:"🛏️", sub:"Stay-first", w:{ luxury:.8, comfort:.8 } },
      { label:"Once-in-a-lifetime experiences", emoji:"🎟️", sub:"Do-first", w:{ adventure:.7, culture:.6, luxury:.4 } },
      { label:"Eat like royalty", emoji:"🍷", sub:"Eat-first", w:{ foodie:.9, luxury:.5 } },
      { label:"Stretch it — go longer, go further", emoji:"🎒", sub:"Value-first", w:{ adventure:.5, comfort:.2, luxury:.05, spontaneity:.5 } },
    ]},
  { id:"q_people", phase:"intake", reads:["social","spontaneity"],
    q:"How much do you want other people in the frame?",
    why:"Calibrates how social vs. solitary I make the recommendations.",
    options:[
      { label:"Buzz, bars, meeting strangers", emoji:"🍻", sub:"Social", w:{ social:.95, spontaneity:.6 } },
      { label:"A mix — lively, then quiet", emoji:"🌗", sub:"Balanced", w:{ social:.5, comfort:.5 } },
      { label:"Space, silence, fewer people", emoji:"🏞️", sub:"Solitary", w:{ social:.1, nature:.7, comfort:.5 } },
    ]},
  { id:"q_terrain", phase:"intake", reads:["nature","adventure","culture"],
    q:"Which landscape pulls you hardest right now?",
    why:"Maps you to the right kind of place before I name any destinations.",
    options:[
      { label:"Mountains & big wilderness", emoji:"🏔️", sub:"", w:{ nature:.95, adventure:.7 } },
      { label:"Old cities & narrow streets", emoji:"🏛️", sub:"", w:{ culture:.9, foodie:.6 } },
      { label:"Coast, islands & water", emoji:"🏝️", sub:"", w:{ comfort:.6, social:.5, nature:.6 } },
      { label:"Somewhere genuinely foreign", emoji:"🌍", sub:"", w:{ adventure:.8, culture:.7, spontaneity:.6 } },
    ]},
  // ---- Crucial-point questions (surface during narrowing) ----
  { id:"q_risk", phase:"crucial", reads:["adventure","comfort"],
    q:"Quick gut check before I lock the plan: how do you feel about the unplanned going sideways?",
    why:"A crucial fork — it decides how much buffer and backup I build in.",
    options:[
      { label:"That's half the story", emoji:"🎲", sub:"Embrace it", w:{ adventure:.7, spontaneity:.8, comfort:.1 } },
      { label:"A little, with a safety net", emoji:"🪢", sub:"Hedge it", w:{ adventure:.4, comfort:.5 } },
      { label:"I'd rather it just work", emoji:"✅", sub:"Avoid it", w:{ comfort:.9, luxury:.4, spontaneity:.2 } },
    ]},
  { id:"q_evenings", phase:"crucial", reads:["social","foodie","comfort"],
    q:"It's 9pm on a good night, mid-trip. Where are you?",
    why:"Evenings reveal the real you — I use this to tune nightlife vs. wind-down.",
    options:[
      { label:"A loud table that grew by four", emoji:"🍾", sub:"", w:{ social:.9, foodie:.6 } },
      { label:"A long dinner, then a walk", emoji:"🌙", sub:"", w:{ foodie:.7, comfort:.6, culture:.5 } },
      { label:"In bed, wrecked from the day", emoji:"😴", sub:"", w:{ adventure:.6, comfort:.5, social:.1 } },
    ]},
  { id:"q_souvenir", phase:"crucial", reads:["culture","foodie","luxury"],
    q:"One thing you'd hate to come home without?",
    why:"The keepsake instinct exposes what you secretly value most.",
    options:[
      { label:"A story no one will believe", emoji:"📖", sub:"", w:{ adventure:.7, spontaneity:.6 } },
      { label:"A flavor I'll chase forever", emoji:"🌶️", sub:"", w:{ foodie:.9, culture:.5 } },
      { label:"Something beautiful I'll keep", emoji:"🪞", sub:"", w:{ luxury:.7, culture:.6 } },
    ]},
];
