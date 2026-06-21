/* ============================================================================
 * TRACK: GAME DEV THROUGH THE AGES
 * From 80s arcade cabinets to your own nostalgia console line.
 * Each section = an era. Subsections carry the three pillars:
 *   Coursework (learn it) - Career (get paid for it) - Sidegigz (ship small, earn now)
 * "reinforce" = practice that loops back on THIS + EARLIER sections (spaced repetition),
 *   with little/none borrowed from sections that come later.
 * ==========================================================================*/
window.TRACKS = window.TRACKS || [];
window.TRACKS.push({
  id: "gamedev",
  title: "Game Dev Through the Ages",
  tagline: "80s cabinets → 8-bit → 16-bit → early 2000s → your own console",
  accent: "#ff4d6d",
  intro:
    "Build games the way they were built in the golden ages, then carry that craft onto modern phones and PCs. " +
    "The end of the road is your own nostalgia hardware + a 90s-YMCA-style 'third place' where people hang out, " +
    "play, and learn. Every era teaches a real, reusable skill — and points at a way to make money this month.",
  sections: [
    /* ---------------------------------------------------------------- */
    {
      id: "gd-foundations",
      era: "Level 0",
      title: "Foundations: How Games Actually Work",
      summary:
        "Before any era: the game loop, input → update → render, sprites, tiles, collision, and one real " +
        "programming language. Skip this and every later era is quicksand.",
      sub: [
        {
          id: "gd-found-loop",
          title: "The Game Loop & Core Programming",
          objective:
            "Understand input→update→render running 60 times a second, and get fluent in one language (start with " +
            "JavaScript or Python, then C/C++ for the retro hardware later).",
          pillars: {
            coursework: [
              "Harvard CS50x — free, the single best CS foundation (cs50.harvard.edu)",
              "freeCodeCamp JavaScript Algorithms & Data Structures (free certificate)",
              "Pikuma 'How to make your first 2D game from scratch' philosophy: loop, state, render"
            ],
            career: [
              "Target role title to learn toward: 'Junior Gameplay Programmer' / 'Game Developer I'",
              "Skill keywords recruiters search: 'game loop', 'OOP', 'state machine', 'fixed timestep'"
            ],
            sidegigz: [
              "Sell nothing yet — instead post your daily build to a devlog (itch.io blog / X) to build an audience",
              "Tutoring: once you finish CS50, tutor intro programming on Wyzant/Preply ($20–40/hr)"
            ]
          },
          tasks: [
            "Write a bare game loop in JS on an HTML <canvas>: a square you move with arrow keys",
            "Add a fixed timestep so movement speed is the same on every machine",
            "Add a second entity and AABB collision (two rectangles overlapping)",
            "Read 'Game Programming Patterns' (free online) — at minimum the Game Loop + Update Method chapters"
          ],
          resources: [
            { label: "CS50x (Harvard, free)", url: "https://cs50.harvard.edu/x/", cost: "Free", tag: "course" },
            { label: "Game Programming Patterns (free book)", url: "https://gameprogrammingpatterns.com/", cost: "Free", tag: "book" },
            { label: "freeCodeCamp JS cert", url: "https://www.freecodecamp.org/learn/", cost: "Free + cert", tag: "cert" },
            { label: "Pikuma courses (retro-focused)", url: "https://pikuma.com/courses", cost: "$ paid", tag: "course" }
          ],
          reinforce: [
            "THIS: rebuild the loop from a blank file without looking — twice this week",
            "THIS: explain 'fixed timestep' out loud in 3 sentences (Feynman it into your journal)"
          ]
        },
        {
          id: "gd-found-math",
          title: "The Only Math You Need (at first)",
          objective:
            "Vectors, coordinates, and basic trig — enough to move, aim, and bounce things. Not a math degree.",
          pillars: {
            coursework: [
              "Khan Academy: Vectors + Basic trigonometry (free)",
              "3Blue1Brown 'Essence of Linear Algebra' (free, intuition gold)"
            ],
            career: ["Keywords: '2D vector math', 'collision detection', 'trajectory'"],
            sidegigz: ["Make + sell a tiny 'juice/feel' code snippet pack on itch.io ($1–5)"]
          },
          tasks: [
            "Make a projectile that flies toward where you click (vector normalize + scale)",
            "Make a ball bounce off the 4 walls (flip velocity components)",
            "Add simple gravity and a jump (Mario-style)"
          ],
          resources: [
            { label: "Khan Academy Vectors", url: "https://www.khanacademy.org/math/precalculus/x9e81a4f98389efdf:vectors", cost: "Free", tag: "course" },
            { label: "3Blue1Brown Linear Algebra", url: "https://www.3blue1brown.com/topics/linear-algebra", cost: "Free", tag: "video" }
          ],
          reinforce: [
            "THIS: re-derive vector normalize from memory",
            "EARLIER (loop): put your projectile inside last section's game loop, not a new file"
          ]
        }
      ]
    },
    /* ---------------------------------------------------------------- */
    {
      id: "gd-80s",
      era: "The 80s",
      title: "Arcade & Atari Era — Single Screen, Pure Mechanics",
      summary:
        "Pong, Breakout, Space Invaders, Pac-Man, Asteroids. One screen, one perfect mechanic, instant feedback. " +
        "This era teaches game FEEL better than anything modern.",
      sub: [
        {
          id: "gd-80s-clones",
          title: "Clone the Classics (the right of passage)",
          objective: "Ship 4 finished arcade clones. Finishing is the skill being trained, not originality.",
          pillars: {
            coursework: [
              "Pikuma '2D Game Engine in C++' or any 'make Pong/Breakout' tutorial",
              "MIT OCW intro to C (for understanding the real hardware mindset)"
            ],
            career: [
              "Portfolio piece #1: a polished arcade pack shows you can FINISH — what studios actually screen for",
              "Indeed search to run: 'gameplay programmer entry level remote'"
            ],
            sidegigz: [
              "Release the arcade pack on itch.io as 'pay what you want'",
              "Make a 'how I cloned Pac-Man' YouTube/short — devlogs are the cheapest marketing that exists"
            ]
          },
          tasks: [
            "Pong (paddles, score, AI opponent)",
            "Breakout (brick grid, power-ups)",
            "Space Invaders (enemy waves, shields, increasing speed)",
            "Asteroids (vector rotation, screen wrap, momentum)",
            "Write a 1-page post-mortem for each in the Book tab"
          ],
          resources: [
            { label: "itch.io (publish free)", url: "https://itch.io/", cost: "Free", tag: "publish" },
            { label: "The Coding Train (p5.js arcade)", url: "https://thecodingtrain.com/", cost: "Free", tag: "video" }
          ],
          reinforce: [
            "THIS: speed-clone Pong in under 2 hours from scratch (proves it's internalized)",
            "EARLIER (loop+vectors): Asteroids forces last section's vector math — do it without notes"
          ]
        },
        {
          id: "gd-80s-pixel",
          title: "Pixel Art & Chiptune 101",
          objective: "Make your own 8x8 / 16x16 sprites and a looping chiptune so your games stop using placeholder art.",
          pillars: {
            coursework: [
              "Aseprite tutorials (or free Piskel/LibreSprite) for pixel art",
              "Bosca Ceoil / BeepBox for chiptune (free, browser)"
            ],
            career: ["Secondary skill that makes you a 'one-person studio' — huge for indie hiring/contracts"],
            sidegigz: [
              "Sell sprite packs / chiptune loops on itch.io & GameDev Market",
              "Fiverr/Upwork gig: 'I will make retro pixel sprites'"
            ]
          },
          tasks: [
            "Draw a 16x16 hero with a 2-frame walk cycle",
            "Make a 30-second looping level theme in BeepBox",
            "Replace ALL placeholder art/sound in your Pong + Breakout"
          ],
          resources: [
            { label: "Piskel (free pixel art)", url: "https://www.piskelapp.com/", cost: "Free", tag: "tool" },
            { label: "BeepBox (free chiptune)", url: "https://www.beepbox.co/", cost: "Free", tag: "tool" },
            { label: "Aseprite", url: "https://www.aseprite.org/", cost: "$ ~20", tag: "tool" }
          ],
          reinforce: [
            "THIS: animate a 4-frame run cycle",
            "EARLIER (clones): your sprites must go INTO the 80s clones, not a fresh canvas"
          ]
        }
      ]
    },
    /* ---------------------------------------------------------------- */
    {
      id: "gd-8bit",
      era: "Mid 80s–Early 90s",
      title: "8-bit / NES Era — Scrolling Worlds & State",
      summary:
        "Super Mario Bros, Mega Man, Zelda, Castlevania. Now we get scrolling levels, tile maps, enemies with " +
        "behavior, menus, save state, and the platformer 'feel' that defines this whole track.",
      sub: [
        {
          id: "gd-8bit-platformer",
          title: "Build a Real Platformer",
          objective:
            "Tile-based level, scrolling camera, coyote-time jumps, enemies, collectibles, win/lose. The crown jewel of retro 2D.",
          pillars: {
            coursework: [
              "Pikuma / GDQuest platformer courses",
              "Pick an engine: Godot (free, ideal) or GameMaker (classic 2D)"
            ],
            career: [
              "Portfolio piece #2 — a finished platformer is the #1 indie calling card",
              "Indeed: 'Godot developer', 'GameMaker developer', '2D game programmer'"
            ],
            sidegigz: [
              "Launch a small premium platformer on itch.io ($3–7) and a free demo",
              "Steam page next era — but list the wishlist mechanic now"
            ]
          },
          tasks: [
            "Tilemap level + scrolling camera that follows the player",
            "Jump feel: variable height, coyote time, jump buffering",
            "2 enemy types with simple AI (patrol + shoot)",
            "Title screen, pause menu, and a save/continue using local storage"
          ],
          resources: [
            { label: "Godot Engine (free, open source)", url: "https://godotengine.org/", cost: "Free", tag: "engine" },
            { label: "GDQuest (Godot courses)", url: "https://www.gdquest.com/", cost: "Free + paid", tag: "course" },
            { label: "GameMaker", url: "https://gamemaker.io/", cost: "Free tier", tag: "engine" }
          ],
          reinforce: [
            "THIS: tune jump feel until a stranger says it 'feels good' — iterate 5x",
            "EARLIER (collision/vectors): platformer collision IS your foundation math under pressure",
            "EARLIER (pixel/chiptune): reuse YOUR assets from the 80s section"
          ]
        },
        {
          id: "gd-8bit-design",
          title: "Game Design & Level Design Fundamentals",
          objective: "Learn WHY Mario 1-1 teaches you to play without words. Designed difficulty curves, telegraphing, reward loops.",
          pillars: {
            coursework: [
              "GMTK (Game Maker's Toolkit) YouTube — design literacy",
              "'The Art of Game Design' by Jesse Schell (book of 'lenses')"
            ],
            career: ["Path: 'Level Designer' / 'Game Designer' — keep a design doc portfolio"],
            sidegigz: ["Write design breakdowns as a blog/Substack; some convert to paid consulting"]
          },
          tasks: [
            "Design your platformer's level 1-1 to teach all mechanics with ZERO text",
            "Map a 30-minute difficulty curve on paper before building",
            "Write a one-page Game Design Doc (GDD) for the platformer"
          ],
          resources: [
            { label: "Game Maker's Toolkit (YouTube)", url: "https://www.youtube.com/@GMTK", cost: "Free", tag: "video" },
            { label: "The Art of Game Design (book)", url: "https://schellgames.com/art-of-game-design", cost: "$ book", tag: "book" }
          ],
          reinforce: [
            "THIS: redo your level 1-1 after watching the Mario 1-1 GMTK video",
            "EARLIER (clones): re-balance Space Invaders' difficulty curve with what you now know"
          ]
        }
      ]
    },
    /* ---------------------------------------------------------------- */
    {
      id: "gd-16bit",
      era: "Early–Mid 90s",
      title: "16-bit / SNES + Genesis — The Nostalgia Core",
      summary:
        "Yoshi's Island, Chrono Trigger, Sonic, Zelda: A Link to the Past, Mode-7. THIS is the YMCA-after-school, " +
        "no-sleep, Neverending-Story feeling you're chasing. Richer systems: RPG stats, world maps, dialogue, polish.",
      sub: [
        {
          id: "gd-16bit-systems",
          title: "Bigger Systems: RPG/Inventory/Dialogue",
          objective: "Move past single-screen mechanics into SYSTEMS: stats, inventory, branching dialogue, saving a whole world.",
          pillars: {
            coursework: [
              "Harvard CS50's Intro to Game Development (free, builds Mario/Zelda/etc. clones in Lua/LÖVE)",
              "Godot RPG tutorials (HeartBeast, GDQuest)"
            ],
            career: [
              "Portfolio piece #3 — a small but COMPLETE RPG/adventure vertical slice",
              "Indeed: 'systems designer', 'gameplay engineer', 'narrative tools'"
            ],
            sidegigz: [
              "RPG asset/tooling packs (dialogue system, inventory) sell well to other devs",
              "Start a YouTube series 'making a SNES-style RPG' — evergreen content"
            ]
          },
          tasks: [
            "Inventory + equipment system with a working menu",
            "Branching dialogue with a simple data format (JSON)",
            "Overworld map + at least 2 connected areas with transitions",
            "A boss fight with phases"
          ],
          resources: [
            { label: "CS50 Intro to Game Dev (free)", url: "https://cs50.harvard.edu/games/", cost: "Free", tag: "course" },
            { label: "LÖVE (Lua 2D framework)", url: "https://love2d.org/", cost: "Free", tag: "engine" }
          ],
          reinforce: [
            "THIS: add a second boss reusing the phase system",
            "EARLIER (platformer): drop your platformer movement into an RPG town for traversal",
            "EARLIER (design doc): expand your one-page GDD into the RPG's systems doc"
          ]
        },
        {
          id: "gd-16bit-feel",
          title: "Juice, Polish & 'Game Feel'",
          objective: "Screen shake, hit-stop, particles, easing, sound layering — the difference between a demo and a magic moment.",
          pillars: {
            coursework: [
              "'Juice it or lose it' (classic talk)",
              "Steve Swink 'Game Feel' (book)"
            ],
            career: ["This is what 'Technical/Combat Designer' roles actually test for"],
            sidegigz: ["A 'game feel toolkit' (camera shake, hit-stop, tween lib) is a sellable asset"]
          },
          tasks: [
            "Add hit-stop + screen shake + particles to your platformer's combat",
            "Layer 3 sound effects so a single hit feels chunky",
            "A/B test: record before/after clips, post the comparison"
          ],
          resources: [
            { label: "'Juice it or lose it' (talk)", url: "https://www.youtube.com/watch?v=Fy0aCDmgnxg", cost: "Free", tag: "video" },
            { label: "Game Feel (book)", url: "http://www.game-feel.com/", cost: "$ book", tag: "book" }
          ],
          reinforce: [
            "THIS: juice ONE old 80s clone until it feels modern",
            "EARLIER (chiptune): re-score a moment with layered audio you made"
          ]
        }
      ]
    },
    /* ---------------------------------------------------------------- */
    {
      id: "gd-2000s",
      era: "Late 90s–Early 2000s",
      title: "Early 2000s — 3D, Engines & 'Real' Production",
      summary:
        "PS1/PS2/N64, GBA, early PC indie. Optional 3D, but mostly: real engines, source control, builds, shipping " +
        "to actual stores. This era turns a hobbyist into someone who can be hired or self-publish for money.",
      sub: [
        {
          id: "gd-2000s-engine",
          title: "Engine Mastery + Shipping a Real Title",
          objective: "Go deep on ONE engine (Godot recommended; Unity if chasing studio jobs) and SHIP to Steam + mobile stores.",
          pillars: {
            coursework: [
              "Full Godot or Unity Learn pathway (Unity Learn is free, job-relevant)",
              "Learn Git/GitHub properly (you're literally in a git repo right now)"
            ],
            career: [
              "This is where you become hireable: 'Unity Developer' / 'Godot Developer' are real, posted jobs",
              "Build a portfolio site + itch + Steam page; link from your résumé"
            ],
            sidegigz: [
              "Premium game on Steam (the $99 one-time Steamworks fee)",
              "Mobile F2P or paid on Google Play / App Store",
              "Contract gigs on Upwork: 'Unity developer', 'game prototyper'"
            ]
          },
          tasks: [
            "Take your 16-bit RPG slice to a FULL small game (1–3 hrs of content)",
            "Set up Git + branches + a proper README (model it on this repo)",
            "Make a Steam page + wishlist campaign, or publish a mobile build",
            "Write the launch post-mortem in the Book tab"
          ],
          resources: [
            { label: "Unity Learn (free)", url: "https://learn.unity.com/", cost: "Free", tag: "course" },
            { label: "Steamworks (publish, $100/game)", url: "https://partner.steamgames.com/", cost: "$100", tag: "publish" },
            { label: "Google Play Console", url: "https://play.google.com/console/", cost: "$25 once", tag: "publish" }
          ],
          reinforce: [
            "THIS: ship a 2nd, smaller title faster using your now-built pipeline",
            "EARLIER (everything): the shipped game should reuse your assets, systems, and feel toolkit"
          ]
        },
        {
          id: "gd-2000s-business",
          title: "The Business of Indie (so it pays the bills)",
          objective:
            "Wishlists, marketing, pricing, taxes, an LLC, store algorithms, and the brutal math of indie income. " +
            "This is the 'sure to make money so I can do this full-time' part — handled honestly.",
          pillars: {
            coursework: [
              "Chris Zukowski 'How to Market a Game' (blog/newsletter, free)",
              "GDC marketing & business talks (YouTube)"
            ],
            career: [
              "Alt path: 'Producer', 'Indie Studio Founder', or game-adjacent (QA, community, tools) while you build",
              "Realistic: keep a day job / electrician income (your other track!) funding game dev until revenue is stable"
            ],
            sidegigz: [
              "Bundle your asset packs + game on itch & Steam",
              "Teach it: a Udemy course 'make a retro platformer' (recorded as you learn) is recurring income",
              "Patreon/ko-fi devlog supporters"
            ]
          },
          tasks: [
            "Write a one-page business plan + realistic 12-month income projection",
            "Set up a wishlist funnel and track conversion",
            "Decide entity (sole prop vs LLC) and bookmark your state's filing page",
            "Record your FIRST teaching module for Udemy/YouTube from an earlier section"
          ],
          resources: [
            { label: "How To Market A Game (Zukowski)", url: "https://howtomarketagame.com/", cost: "Free", tag: "blog" },
            { label: "GDC Vault (YouTube talks)", url: "https://www.youtube.com/@Gdconf", cost: "Free", tag: "video" },
            { label: "Udemy (teach a course)", url: "https://www.udemy.com/teaching/", cost: "Free to publish", tag: "publish" }
          ],
          reinforce: [
            "THIS: rewrite your income projection after real wishlist data",
            "EARLIER (devlogs): turn 6 months of devlogs into the Udemy course outline"
          ]
        }
      ]
    },
    /* ---------------------------------------------------------------- */
    {
      id: "gd-console",
      era: "The Vision",
      title: "Your Console + the Nostalgia 'Third Place'",
      summary:
        "The endgame: a small nostalgia console line and a physical/virtual hangout — the 90s YMCA-on-base feeling. " +
        "Smash, kickball, Yoshi on SNES, Neverending Story, no sleep. A homeschool-feel community where the curriculum " +
        "you're building IS the programming. Long-horizon, but mapped so it's real, not a daydream.",
      sub: [
        {
          id: "gd-console-hw",
          title: "Handheld/Console Hardware (Raspberry Pi → custom)",
          objective:
            "Learn enough embedded/hardware to make a real retro handheld, then graduate toward a branded console kit.",
          pillars: {
            coursework: [
              "Raspberry Pi + RetroPie / EmulationStation (start cheap & real)",
              "Arduino/Pi GPIO basics — and YES this overlaps your Electrical track (shared win)",
              "PCB design intro (KiCad, free)"
            ],
            career: [
              "Hybrid identity: 'maker / hardware-software product builder'",
              "Crowdfunding-ready hardware is a portfolio unlike anyone else's"
            ],
            sidegigz: [
              "Sell built/modded handhelds locally and on Etsy/eBay",
              "Kickstarter for a small-batch console kit once a prototype exists"
            ]
          },
          tasks: [
            "Build a Raspberry Pi handheld that boots straight into YOUR games",
            "Design a simple custom controller PCB in KiCad",
            "Prototype a branded boot screen + curated 'nostalgia OS' launcher",
            "Cost out a 10-unit small batch (BOM, assembly, margin)"
          ],
          resources: [
            { label: "RetroPie", url: "https://retropie.org.uk/", cost: "Free", tag: "tool" },
            { label: "KiCad (free PCB design)", url: "https://www.kicad.org/", cost: "Free", tag: "tool" },
            { label: "Raspberry Pi", url: "https://www.raspberrypi.com/", cost: "$ hardware", tag: "hardware" }
          ],
          reinforce: [
            "THIS: load your OWN shipped game as the flagship title on the handheld",
            "CROSS-TRACK (Electrical): soldering + circuits here are graded in BOTH tracks — do them once, count twice"
          ]
        },
        {
          id: "gd-console-place",
          title: "The Hangout: a Modern 'Third Place'",
          objective:
            "Design the community space/business — homeschool-co-op energy, an hour-plus hangout, events, and curriculum-as-programming.",
          pillars: {
            coursework: [
              "Ray Oldenburg 'The Great Good Place' (the 'third place' concept)",
              "Small-business / nonprofit basics (SBA learning center, free)",
              "Event & community ops basics"
            ],
            career: ["You as 'founder / community builder / educator' — the synthesis of everything"],
            sidegigz: [
              "Run a small recurring 'retro game-making club' for kids/teens (paid sessions) NOW, before any building exists",
              "Birthday parties, tournaments, summer camps using your curriculum"
            ]
          },
          tasks: [
            "Write a one-page vision + values doc for the space (put it in the Book tab)",
            "Pilot ONE event: a 2-hour retro game jam at a library/community center",
            "Sketch the business model (membership? camps? café?) and a tiny budget",
            "Map how this curriculum becomes the class schedule"
          ],
          resources: [
            { label: "SBA Learning Center (free)", url: "https://www.sba.gov/business-guide", cost: "Free", tag: "course" },
            { label: "The Great Good Place (book)", url: "https://en.wikipedia.org/wiki/The_Great_Good_Place_(book)", cost: "$ book", tag: "book" }
          ],
          reinforce: [
            "THIS: after the pilot event, rewrite the vision doc with what you learned",
            "EARLIER (teaching/Udemy): your recorded modules become the club's lesson plans"
          ]
        }
      ]
    }
  ]
});
