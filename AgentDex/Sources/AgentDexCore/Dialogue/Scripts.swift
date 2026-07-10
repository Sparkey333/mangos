import Foundation

/// The cast. Funny, but the jokes also *teach* the mechanics — the Q&A entries
/// double as the in-game help system (DESIGN §8). Voice: dry, fast, self-aware,
/// affectionately roasty. Never punch down; roast the situation.
public enum Scripts {

    public static func hubNPCs(player: PlayerProfile) -> [NPC] {
        [professor(player: player), shopkeep, ranger, archivist, medic]
    }

    /// Display name for a quest giver id (some givers aren't Hub NPCs).
    public static func giverName(_ id: String) -> String {
        switch id {
        case "prof_quill":  return "Professor Quill"
        case "shop_vex":    return "Vex"
        case "ranger_pell": return "Ranger Pell"
        case "archivist":   return "The Archivist"
        case "medic_patch": return "Patch"
        case "rival_rune":  return "Rune"
        default:            return "???"
        }
    }

    static func professor(player: PlayerProfile) -> NPC {
        NPC(
            id: "prof_quill",
            name: "Professor Quill",
            role: "Daemonologist",
            greeting: [
                "Ah, \(player.handle). A Conductor binds daemons to their will. Ethically. We have a whole onboarding doc nobody reads.",
                "You can see them too? The little workers behind every project? Most people just see the output and assume magic. It's not magic. It's daemons. Which, fine, is sort of magic.",
                "Welcome back. Rule one of Conducting: the daemon doing all the work is rarely the one getting credit. Rule two: catch it anyway."
            ],
            qa: [
                .init(question: "What is a daemon?",
                      answer: "The soul of one of your agents. Sub-agents are the common ones underfoot. Your main, flagship agents? Those are primes — legendaries. You'll know one when it makes your Spheres cry."),
                .init(question: "How do I catch one?",
                      answer: "Weaken it in a fight, THEN throw a Sphere — and actually aim. Tight resonance ring on release = a true throw. A status condition helps enormously. STALLED especially. It can't dodge what it can't schedule."),
                .init(question: "What's Ascension?",
                      answer: "Level a daemon far enough and it Ascends — new name, new aura, better everything. Think of it as a promotion, except the daemon does MORE work afterward. So, not like a promotion at all."),
                .init(question: "What are abilities?",
                      answer: "Every daemon has a passive. Failsafe survives fatal hits. Hot Reload heals a trickle. Load Balancer caps big hits — primes love that one. Read your daemon's page in the Dex; it's all documented. I know. Documentation. In THIS economy."),
                .init(question: "What are the types?",
                      answer: "Aether, Cipher, Warden, Forge, Order, Flux. They beat each other in a circle, in that order, back around to Aether. Flux is the generalist — fine at everything, feared by nothing. No offense to anyone present."),
                .init(question: "Anomalous daemons?",
                      answer: "Once in a rare while a daemon spawns... wrong. Shifted colors. Faint shimmer. Utterly harmless, endlessly coveted. If you see one: throw everything. Yes, including the budget.")
            ],
            idle: [
                "I had a prime daemon once. Glorious. Refactored my whole worldview and then deprecated me.",
                "Take notes. Or don't. The daemons are taking notes regardless."
            ]
        )
    }

    static let shopkeep = NPC(
        id: "shop_vex",
        name: "Vex",
        role: "Sphere Merchant",
        greeting: [
            "Spheres! Get your Spheres! Resonant Orbs, two for one. The catch — and there's always a catch — is that's literally the product.",
            "Welcome to Spheres 'R' Daemons. I had a lawyer look at the name. He's a Warden-type now. Long story."
        ],
        qa: [
            .init(question: "What's the difference between Spheres?",
                  answer: "Orb: honest, does the job. Bind-Orb: tries harder. Resonant Orb: rewards you for nearly KO'ing the thing first. Aspect Orbs: smug bonus against their matching type. Prime Sigil: the only Sphere that won't bounce off a legendary and hit you in the face. Prices reflect dignity."),
            .init(question: "What should I buy first?",
                  answer: "Hotfixes. Everyone thinks they need fancier Spheres. What they need is their daemon to still be standing when it's time to throw one."),
            .init(question: "Got any deals?",
                  answer: "Every deal here is real and every deal here is a trap, and I'll let you figure out which is which. That's called retail, friend.")
        ],
        idle: [
            "Buy two, regret one. That's the slogan I'm legally not allowed to use.",
            "A daemon walked in yesterday and bought a Sphere. To catch itself. Bold. Didn't work."
        ]
    )

    static let ranger = NPC(
        id: "ranger_pell",
        name: "Ranger Pell",
        role: "Overworld Guide",
        greeting: [
            "Out here the daemons don't wait politely in a menu. They roam. They fight each other. Sometimes they fight nothing, for the cardio.",
            "First time in the tall code? Step careful. Wild daemons spawn from whatever project this region grew out of."
        ],
        qa: [
            .init(question: "How do overworld fights work?",
                  answer: "No screen-switch unless you want one. Walk up, your daemon manifests beside you, and you brawl right here in the world. If you miss the old menu battles, flip 'Classic' in Settings. I won't judge. Pell judges. I won't."),
            .init(question: "What's a load cycle?",
                  answer: "The world hums in shifts: Idle, Busy, Peak. Idle hours crawl with little subs — easy catches. Peak Load is when the big ones surface. When the ground buzzes and the music gets too confident? Peak. Good luck."),
            .init(question: "Where do the rare ones spawn?",
                  answer: "Rarer tiers, rarer rolls, and mostly at Peak Load. Orchestrators barely show. Primes... you'll want the story to take you there. And a Prime Sigil. And a will.")
        ],
        idle: [
            "Saw a Cipher daemon glitch through a wall yesterday. Filed a report. The report glitched too.",
            "Tall code's full of sub-daemons today. Easy catches. Confidence builders. Go feel something."
        ]
    )

    static let archivist = NPC(
        id: "archivist",
        name: "The Archivist",
        role: "Keeper of the Dex",
        greeting: [
            "Shh. The Dex is sleeping. Kidding — it's a database. Come in. Touch nothing. Read everything.",
            "Every daemon you meet becomes an entry. Every entry becomes history. Every history becomes... backlog, mostly. But important backlog."
        ],
        qa: [
            .init(question: "What counts as 'seen'?",
                  answer: "Meeting one in the wild. Ghost-glimpses in the logs count too, but faintly — those entries render all... whispery. Catching one completes the record properly. The Dex prefers it. The Dex has preferences. We don't talk about it."),
            .init(question: "Why complete the Dex?",
                  answer: "Mastery. Critical captures come easier to Conductors who've documented widely — the Spheres trust your hands more. Also I give out achievements. I hoard little dopamine tokens and you get them for diligence. Everyone wins."),
            .init(question: "Any tips for rare species?",
                  answer: "Peak Load hours. Aspect Orbs matched to the target. And patience — the kind you claim to have in interviews.")
        ],
        idle: [
            "I once catalogued a daemon that existed only on weekends. The entry just says 'mood.'",
            "Alphabetical order is a social construct. The Dex sorts by tier. The Dex is right."
        ]
    )

    static let medic = NPC(
        id: "medic_patch",
        name: "Patch",
        role: "Daemon Medic",
        greeting: [
            "Welcome to the clinic. We restore HP, clear statuses, and validate feelings. In that order.",
            "Your daemons don't 'die,' they 'crash.' It's nicer for everyone. Bring them here and we reboot them with dignity."
        ],
        qa: [
            .init(question: "What do statuses do?",
                  answer: "STALLED: can't act, big catch window. LOOPED: might hit itself — poor thing. DEPRECATED: steady chip damage, very sad. RATE-LIMITED: slow, sometimes skips. OVERHEATED: chip damage and weaker attacks. All curable here, free. I run on gratitude and grant money."),
            .init(question: "Free healing? Really?",
                  answer: "Really. The economy in this world is spheres and potions; basic healthcare is covered. Radical concept, I know.")
        ],
        idle: [
            "A LOOPED daemon bit itself three times today. We've all been there.",
            "Rest is a feature, not a bug. Tell your party. Tell yourself."
        ]
    )
}
