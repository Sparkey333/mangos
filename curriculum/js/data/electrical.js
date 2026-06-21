/* ============================================================================
 * TRACK: ELECTRICAL — THEORY TO TRADE
 * Full history of electrical thought (including the "forgotten"/fringe ideas,
 * framed as history-of-science you can verify), down to a licensed electrician
 * making money in Colorado Springs, CO — with real money ranges & timeframes.
 * Same three pillars: Coursework - Career - Sidegigz.
 * NOTE: This is education, not a substitute for code, permits, or a licensed
 *       master electrician. Never work on live circuits untrained.
 * ==========================================================================*/
window.TRACKS = window.TRACKS || [];
window.TRACKS.push({
  id: "electrical",
  title: "Electrical — Theory to Trade",
  tagline: "Ancient sparks → Maxwell → the panel in your hand → a paid license",
  accent: "#ffd23f",
  intro:
    "Two ladders at once. The LEFT ladder is understanding — the real history of how humans figured out " +
    "electricity, including the weird, buried, and over-hyped ideas (handled with a skeptic's flashlight, not " +
    "blind faith). The RIGHT ladder is money — a concrete, accredited, Colorado-Springs-specific path to being a " +
    "paid electrician, with dollar ranges and timelines. They reinforce each other: theory makes you a better " +
    "tradesman; the trade pays for the theory.",
  sections: [
    /* ---------------------------------------------------------------- */
    {
      id: "el-history",
      era: "Origins",
      title: "The History of the Spark (incl. the 'Forgotten' Stuff)",
      summary:
        "From amber and lodestone to Franklin's kite to Tesla's coil. Plus an honest look at the ancient/occult/" +
        "'suppressed' claims (Baghdad battery, pyramid power, Tesla 'free energy') — what's real, what's myth, and " +
        "how to tell. Curiosity ON, critical thinking ON.",
      sub: [
        {
          id: "el-hist-classical",
          title: "Ancient → Enlightenment: Amber, Lodestones, Leyden Jars",
          objective:
            "Trace the actual recorded history: Thales & amber (static), lodestone/magnetism, Gilbert's 'De Magnete' " +
            "(1600), the Leyden jar, Galvani vs Volta (the first battery, 1800).",
          pillars: {
            coursework: [
              "Khan Academy: Electric charge & static electricity (free)",
              "Read about William Gilbert 'De Magnete' and Volta's pile (primary-source history)"
            ],
            career: ["Builds the 'why' that separates a thinking electrician from a wire-monkey"],
            sidegigz: ["A clear 'history of electricity' explainer video/series is great YouTube/podcast fodder"]
          },
          tasks: [
            "Make static cling/charge separation experiments (balloon, wool) and explain WHY",
            "Build a lemon/potato battery and measure its voltage with a multimeter",
            "Write a 1-page timeline: amber → lodestone → Leyden jar → Volta's pile"
          ],
          resources: [
            { label: "Khan Academy: Electric charge", url: "https://www.khanacademy.org/science/physics/electric-charge-electric-force-and-voltage", cost: "Free", tag: "course" },
            { label: "Volta & the first battery (history)", url: "https://en.wikipedia.org/wiki/Voltaic_pile", cost: "Free", tag: "reading" }
          ],
          reinforce: [
            "THIS: re-explain Galvani vs Volta in your journal without notes",
            "THIS: relate your lemon battery back to Volta's pile chemistry"
          ]
        },
        {
          id: "el-hist-giants",
          title: "Faraday, Maxwell, Edison vs Tesla (AC/DC War)",
          objective:
            "The era that built the modern grid: Faraday's induction, Maxwell's equations (the math of all of it), " +
            "and the Edison(DC) vs Tesla/Westinghouse(AC) war that decided how power reaches your house.",
          pillars: {
            coursework: [
              "Faraday's law & electromagnetic induction (Khan/HyperPhysics)",
              "MIT OCW 8.02 Electricity & Magnetism (free, the serious version)",
              "Tesla's polyphase AC system — the reason wall outlets are AC"
            ],
            career: ["Understanding AC is literally the job — homes & the grid are AC"],
            sidegigz: ["'AC/DC War' is endlessly popular content — book chapter, video, podcast episode"]
          },
          tasks: [
            "Build a simple electromagnet and a basic motor from a battery, magnet, and wire",
            "Explain induction by making a coil light an LED with a moving magnet",
            "Write the AC vs DC tradeoffs in plain English (and why AC won for distribution)"
          ],
          resources: [
            { label: "MIT OCW 8.02 E&M (free)", url: "https://ocw.mit.edu/courses/8-02-physics-ii-electricity-and-magnetism-spring-2007/", cost: "Free", tag: "course" },
            { label: "HyperPhysics (reference)", url: "http://hyperphysics.phy-astr.gsu.edu/hbase/emcon.html", cost: "Free", tag: "reference" }
          ],
          reinforce: [
            "THIS: your homemade motor must demonstrate Faraday's law — explain the link",
            "EARLIER (Volta): contrast Volta's DC pile with Tesla's AC — why each mattered"
          ]
        },
        {
          id: "el-hist-fringe",
          title: "The 'Forgotten' & Occult Files — Skeptic's Edition",
          objective:
            "Catalog the ancient/occult/'suppressed' electrical claims and grade each: SOLID, DISPUTED, or MYTH. " +
            "Real history (Tesla's real unfinished projects) lives next to debunked pop-myths — learn to tell them apart.",
          pillars: {
            coursework: [
              "Primary sources first: Tesla's own patents & papers (real) vs YouTube claims (verify)",
              "Learn the scientific method & how to spot pseudoscience (energy can't be 'free', conservation laws)",
              "Carl Sagan 'The Demon-Haunted World' — your baloney-detection kit"
            ],
            career: ["Critical thinking protects you from scams AND makes you a trustworthy expert"],
            sidegigz: [
              "A respectful, well-sourced 'myth vs fact' series builds a loyal audience",
              "Companion book chapter: 'The Spark They Said Was Forgotten'"
            ]
          },
          tasks: [
            "Research the Baghdad Battery — log evidence FOR and AGAINST it being a real cell",
            "Separate Tesla's REAL work (Wardenclyffe, AC, radio) from 'free energy' myths",
            "Write your own grading rubric for any 'suppressed tech' claim and apply it to 3 claims",
            "Note any claim that's genuinely under-explored vs simply debunked"
          ],
          resources: [
            { label: "Tesla patents (real primary sources)", url: "https://patents.google.com/?inventor=Nikola+Tesla", cost: "Free", tag: "primary" },
            { label: "Demon-Haunted World (book)", url: "https://en.wikipedia.org/wiki/The_Demon-Haunted_World", cost: "$ book", tag: "book" },
            { label: "Conservation of energy (why 'free energy' fails)", url: "https://en.wikipedia.org/wiki/Conservation_of_energy", cost: "Free", tag: "reading" }
          ],
          reinforce: [
            "THIS: apply your rubric to a new claim every week and log the verdict",
            "EARLIER (Maxwell): use real physics to evaluate each fringe claim, not vibes"
          ]
        }
      ]
    },
    /* ---------------------------------------------------------------- */
    {
      id: "el-theory",
      era: "Fundamentals",
      title: "Circuit Theory You Can Actually Use",
      summary:
        "Ohm's law, series/parallel, AC, power, and safety — the load-bearing math for both the trade and the deeper " +
        "physics. This is where 'I like electricity' becomes 'I can calculate it.'",
      sub: [
        {
          id: "el-theory-dc",
          title: "Ohm's Law, Series/Parallel, the Multimeter",
          objective: "V=IR in your bones. Read a multimeter. Calculate current, voltage drop, and power for real circuits.",
          pillars: {
            coursework: [
              "All About Circuits (free textbook + worked examples)",
              "Khan Academy: Circuits with resistors",
              "Build on a breadboard alongside the reading"
            ],
            career: ["Pre-apprenticeship knowledge that makes you stand out on day one"],
            sidegigz: ["Tutor/help intro-electronics students; sell beginner breadboard kits + guides"]
          },
          tasks: [
            "Breadboard an LED + resistor; CALCULATE the resistor before placing it",
            "Measure V, I, and R across series and parallel resistor networks; verify your math",
            "Compute voltage drop over a long wire run (why wire gauge matters)"
          ],
          resources: [
            { label: "All About Circuits (free book)", url: "https://www.allaboutcircuits.com/textbook/", cost: "Free", tag: "book" },
            { label: "Khan Academy: Circuits", url: "https://www.khanacademy.org/science/physics/circuits-topic", cost: "Free", tag: "course" },
            { label: "Multimeter + breadboard kit", url: "https://www.sparkfun.com/", cost: "$ ~30-60", tag: "hardware" }
          ],
          reinforce: [
            "THIS: re-solve 5 Ohm's-law problems cold each week",
            "EARLIER (lemon battery): re-measure it and predict the current with Ohm's law first"
          ]
        },
        {
          id: "el-theory-ac",
          title: "AC, Power, 3-Phase & Residential Wiring Concepts",
          objective:
            "AC waveforms, RMS, real vs reactive power, single-phase 120/240V split-phase (US homes), grounding/bonding basics.",
          pillars: {
            coursework: [
              "Mike Holt free resources (residential/code-aligned theory)",
              "All About Circuits AC chapters",
              "Understand the US split-phase 120/240V service"
            ],
            career: ["This IS residential electrician knowledge — directly billable understanding"],
            sidegigz: ["Energy-audit / 'understand your panel' explainer content for homeowners"]
          },
          tasks: [
            "Diagram a home's service: meter → main panel → 120V & 240V circuits",
            "Explain hot/neutral/ground and WHY grounding saves lives",
            "Calculate a circuit's load and why a 15A circuit trips (without burning the house down — on paper!)"
          ],
          resources: [
            { label: "Mike Holt (free resources)", url: "https://www.mikeholt.com/", cost: "Free + paid", tag: "course" },
            { label: "All About Circuits: AC", url: "https://www.allaboutcircuits.com/textbook/alternating-current/", cost: "Free", tag: "book" }
          ],
          reinforce: [
            "THIS: re-draw the service diagram from memory",
            "EARLIER (AC/DC war): connect split-phase back to WHY we use AC at all"
          ]
        }
      ]
    },
    /* ---------------------------------------------------------------- */
    {
      id: "el-safety",
      era: "Non-Negotiable",
      title: "Safety, Tools & the NEC (do this before touching a panel)",
      summary:
        "Electricity kills the careless. Lock-out/tag-out, PPE, the National Electrical Code (NEC), and reading a " +
        "wiring diagram. This gates everything hands-on.",
      sub: [
        {
          id: "el-safety-core",
          title: "LOTO, PPE, Code Literacy & Hand Tools",
          objective: "Work safely, read the NEC, and use the trade's hand tools correctly. No live work untrained — ever.",
          pillars: {
            coursework: [
              "OSHA-10 (electrical safety) — often free/cheap, employer-valued",
              "Ugly's Electrical References (the pocket bible)",
              "NFPA 70 (NEC) overview — learn to LOOK THINGS UP, not memorize all of it"
            ],
            career: [
              "OSHA-10 + safety habits = hireable as an apprentice/helper immediately",
              "Indeed: 'electrician apprentice', 'electrician helper', 'low voltage technician'"
            ],
            sidegigz: [
              "Legal, no-license-needed gigs NOW: assemble/mount fixtures (unpowered), run low-voltage (doorbell, " +
              "thermostat, network) where local rules allow, handyman tasks — always within the law/permits"
            ]
          },
          tasks: [
            "Complete OSHA-10 (or equivalent electrical safety course)",
            "Buy & learn: multimeter, wire strippers, lineman's pliers, voltage tester, screwdrivers",
            "Practice LOTO procedure (write the steps; rehearse on a de-energized setup)",
            "Look up 3 NEC requirements (e.g., outlet spacing, GFCI locations) and cite the article"
          ],
          resources: [
            { label: "OSHA Outreach / OSHA-10", url: "https://www.osha.gov/training/outreach", cost: "$ low", tag: "cert" },
            { label: "Ugly's Electrical References", url: "https://www.jblearning.com/catalog/productdetails/9781284194074", cost: "$ ~15", tag: "book" },
            { label: "NFPA 70 (NEC)", url: "https://www.nfpa.org/codes-and-standards/nfpa-70-standard-development/70", cost: "Free read / $ buy", tag: "code" }
          ],
          reinforce: [
            "THIS: quiz yourself on PPE & LOTO weekly until automatic",
            "EARLIER (grounding): tie every safety rule back to the physics of why it works"
          ]
        }
      ]
    },
    /* ---------------------------------------------------------------- */
    {
      id: "el-career-co",
      era: "Get Paid — Colorado Springs",
      title: "The Colorado Springs Path: Apprentice → Journeyman → Master",
      summary:
        "The concrete, money-making plan in YOUR city. Colorado licenses electricians at the STATE level (CO DORA " +
        "Electrical Board). You earn WHILE you learn through a registered apprenticeship — get paid from day one. " +
        "Numbers below are ballpark ranges; always verify current figures with the sources linked.",
      sub: [
        {
          id: "el-co-apprentice",
          title: "Step 1 — Register as an Apprentice & Get Hired (earn now)",
          objective:
            "Register with Colorado DORA as an electrical apprentice, then get hired by a licensed contractor or " +
            "join an apprenticeship program. You start earning immediately; school is paid for or low-cost.",
          pillars: {
            coursework: [
              "Apprenticeship class hours come WITH the program (you don't pre-pay a degree)",
              "Options: IEC Rocky Mountain (merit/open-shop) or IBEW Local 113 / JATC (union) — both in the Springs area",
              "Pikes Peak State College (Colorado Springs) electrician/electrical courses as a feeder/supplement"
            ],
            career: [
              "Register as an apprentice with the CO State Electrical Board (DORA) — required to work legally",
              "Apply to electrical contractors as 'apprentice/helper'; apply to IEC & IBEW programs",
              "Indeed search to run: 'electrician apprentice Colorado Springs'",
              "MONEY (ballpark): apprentices commonly start ~$17–22/hr, rising each year toward journeyman pay",
              "TIME: ~4 years / ~8,000 supervised hours + ~600 classroom hours to qualify for the journeyman exam"
            ],
            sidegigz: [
              "While apprenticing: legal helper/handyman + low-voltage work (verify local permit rules)",
              "Document everything for your future Udemy/YouTube 'how I became an electrician' series"
            ]
          },
          tasks: [
            "Create/verify your registration on the CO DORA Electrical Board site",
            "Apply to IEC Rocky Mountain AND IBEW Local 113 apprenticeship programs",
            "Apply to 5 local contractors as apprentice/helper this week",
            "Track every supervised hour in a logbook (you'll need ~8,000)"
          ],
          resources: [
            { label: "CO DORA Electrical Board (license/register)", url: "https://dpo.colorado.gov/Electrical", cost: "Gov fees", tag: "license" },
            { label: "IEC Rocky Mountain (apprenticeship)", url: "https://iecrm.org/", cost: "Earn while learn", tag: "apprenticeship" },
            { label: "IBEW Local 113 (Colorado Springs)", url: "https://www.ibew113.org/", cost: "Earn while learn", tag: "apprenticeship" },
            { label: "Pikes Peak State College", url: "https://www.pikespeak.edu/", cost: "$ community-college", tag: "college" },
            { label: "Indeed: apprentice (Colo. Springs)", url: "https://www.indeed.com/q-electrician-apprentice-l-colorado-springs-co-jobs.html", cost: "Free", tag: "jobs" }
          ],
          reinforce: [
            "THIS: keep your hour logbook current weekly — it's literally your license progress bar",
            "EARLIER (theory + safety): every job site is a live exam of Ohm's law, AC, and LOTO"
          ]
        },
        {
          id: "el-co-journeyman",
          title: "Step 2 — Journeyman License (real money)",
          objective:
            "Hit your hours + schooling, pass the Colorado Journeyman exam, get licensed, and earn full journeyman wages.",
          pillars: {
            coursework: [
              "Journeyman exam prep (NEC-based) — Mike Holt / IEC / IBEW exam-prep courses",
              "Master the NEC code-lookup speed needed for the timed exam"
            ],
            career: [
              "Pass the CO Journeyman Electrician exam (apply through DORA/PSI)",
              "MONEY (ballpark): journeyman electricians in the Colorado Springs area commonly earn ~$28–40/hr " +
              "(~$58k–$85k/yr) depending on overtime/specialty — verify current local rates",
              "Indeed: 'journeyman electrician Colorado Springs'"
            ],
            sidegigz: [
              "Licensed journeyman opens side service-call work (within your contractor's license/permits)",
              "Specialize for more pay: solar/PV, EV chargers, low-voltage/controls, industrial"
            ]
          },
          tasks: [
            "Confirm you've logged the required supervised hours + classroom hours",
            "Complete a journeyman exam-prep course and pass practice exams",
            "Apply for and schedule the CO Journeyman exam",
            "After passing: negotiate your journeyman wage with documented skills"
          ],
          resources: [
            { label: "CO DORA: license types & exams", url: "https://dpo.colorado.gov/Electrical", cost: "Gov fees", tag: "license" },
            { label: "Mike Holt exam prep", url: "https://www.mikeholt.com/", cost: "$ paid", tag: "course" },
            { label: "Indeed: journeyman (Colo. Springs)", url: "https://www.indeed.com/q-journeyman-electrician-l-colorado-springs-co-jobs.html", cost: "Free", tag: "jobs" }
          ],
          reinforce: [
            "THIS: do timed NEC look-up drills until you're fast",
            "EARLIER (apprentice hours): your logbook is the gate to even sitting the exam"
          ]
        },
        {
          id: "el-co-master",
          title: "Step 3 — Master Electrician & Your Own Business",
          objective:
            "After journeyman experience, earn the Master license, then optionally a contractor registration to run " +
            "your own shop — the highest-earning, most independent rung.",
          pillars: {
            coursework: [
              "Master exam prep (advanced NEC, calculations, theory)",
              "Small-business basics: SBA, bookkeeping, estimating, insurance, bonding"
            ],
            career: [
              "Pass the CO Master Electrician exam (needs journeyman experience)",
              "MONEY (ballpark): masters ~$40–55+/hr employed; OWNING a contracting business can earn well into " +
              "six figures depending on size/risk — verify and plan conservatively",
              "Register a contracting business + pull permits legally"
            ],
            sidegigz: [
              "This IS the business: service calls, panel upgrades, EV chargers, solar, remodels",
              "Teach the path: paid course + YouTube — your journey becomes a second income stream"
            ]
          },
          tasks: [
            "Confirm journeyman experience requirement for the Master exam",
            "Complete Master exam prep and pass practice exams",
            "Draft a one-page business plan (in the Book tab) for your future shop",
            "Research insurance/bonding/LLC steps for a CO electrical contractor"
          ],
          resources: [
            { label: "CO DORA: Master license", url: "https://dpo.colorado.gov/Electrical", cost: "Gov fees", tag: "license" },
            { label: "SBA business guide", url: "https://www.sba.gov/business-guide", cost: "Free", tag: "course" },
            { label: "CO Sec. of State (register a business)", url: "https://www.sos.state.co.us/biz/", cost: "$ low filing", tag: "gov" }
          ],
          reinforce: [
            "THIS: re-run a sample job estimate until your pricing is confident",
            "EARLIER (everything): the Master exam tests theory + code + safety from ALL prior sections at once"
          ]
        }
      ]
    },
    /* ---------------------------------------------------------------- */
    {
      id: "el-degrees",
      era: "Optional Higher Ed",
      title: "Degrees, Masters & PhD Pathways (accredited, online-leaning)",
      summary:
        "If you want the academic ladder too: associate/bachelor's in electrical/EET, then Master's, then PhD — " +
        "leaning online + accredited + affordable, but NOT chasing fake mills. These pair with the trade for " +
        "engineering, R&D, teaching, or your hardware/console ambitions.",
      sub: [
        {
          id: "el-deg-undergrad",
          title: "Associate → Bachelor's (EET / Electrical Engineering)",
          objective:
            "Accredited, affordable, online-friendly undergrad. Electrical Engineering Technology (EET) is more " +
            "hands-on/affordable; Electrical Engineering (EE) is more theory/higher-ceiling (often needs on-campus labs).",
          pillars: {
            coursework: [
              "Start cheap: community college (Pikes Peak State College) → transfer",
              "ABET-accredited online options: ASU, Arizona (some), Old Dominion, Thomas Edison State (verify ABET)",
              "Free-to-learn parallel: MIT OCW EE courses (no credit, full knowledge)"
            ],
            career: [
              "Opens 'electrical engineer', 'controls engineer', 'hardware engineer' roles",
              "Stacks with your trade license for a rare engineer-who-can-also-wire profile"
            ],
            sidegigz: ["Freelance circuit/PCB design once skilled (ties into the console hardware track!)"]
          },
          tasks: [
            "List 3 ABET-accredited, online-friendly EE/EET programs + their per-credit cost",
            "Map a transfer plan: Pikes Peak State credits → 4-year degree",
            "Decide EET (hands-on/cheaper) vs EE (theory/higher ceiling) for YOUR goals"
          ],
          resources: [
            { label: "ABET (verify accreditation — do this!)", url: "https://www.abet.org/accreditation/find-programs/", cost: "Free", tag: "verify" },
            { label: "MIT OpenCourseWare EECS", url: "https://ocw.mit.edu/search/?d=Electrical%20Engineering%20and%20Computer%20Science", cost: "Free", tag: "course" },
            { label: "Pikes Peak State College", url: "https://www.pikespeak.edu/", cost: "$ low", tag: "college" }
          ],
          reinforce: [
            "THIS: re-verify each program on ABET before paying anyone a cent",
            "EARLIER (circuit theory): your trade-side Ohm's law IS first-year EE — you're ahead"
          ]
        },
        {
          id: "el-deg-grad",
          title: "Master's & PhD (and how to fund them)",
          objective:
            "If pursuing research/teaching/advanced engineering: an accredited online MS, then a (usually funded) PhD. " +
            "Key truth: reputable PhDs are typically FUNDED (stipend + tuition waiver) — you generally shouldn't pay.",
          pillars: {
            coursework: [
              "Online MSEE options (verify accreditation): Georgia Tech OMS programs, ASU, Purdue, USC, CU Boulder",
              "GRE/portfolio prep as needed; strong undergrad GPA matters",
              "For a 2nd master's: pick one that complements game-tech/hardware (e.g., CS, HCI, or EE/embedded)"
            ],
            career: [
              "MS → senior/specialist engineer, R&D; PhD → research scientist, professor, deep R&D",
              "Realistic note: for the trade-money goal, a Master/PhD is OPTIONAL — pursue for love or specific roles"
            ],
            sidegigz: ["Grad research + teaching assistantships are themselves paid; consulting follows expertise"]
          },
          tasks: [
            "Shortlist 3 accredited online MS programs + total cost + admission requirements",
            "Confirm the 'PhDs should be funded' rule for any program you consider",
            "Write WHY you'd want grad school (career? curiosity? a specific job?) — be honest in the Book tab"
          ],
          resources: [
            { label: "Georgia Tech online MS (model of legit+affordable)", url: "https://pe.gatech.edu/degrees", cost: "$ moderate", tag: "degree" },
            { label: "CU Boulder online (in CO)", url: "https://www.colorado.edu/online/", cost: "$ moderate", tag: "degree" },
            { label: "ABET program finder", url: "https://www.abet.org/accreditation/find-programs/", cost: "Free", tag: "verify" }
          ],
          reinforce: [
            "THIS: pressure-test each program's accreditation + funding before applying",
            "EARLIER (undergrad map): grad plans must build on the verified undergrad path, not replace it"
          ]
        }
      ]
    }
  ]
});
