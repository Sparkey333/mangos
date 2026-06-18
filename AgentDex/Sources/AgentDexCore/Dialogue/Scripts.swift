import Foundation

/// The tiny-test-build cast. Funny, but the jokes also *teach* the mechanics —
/// the Q&A entries double as the in-game help system (DESIGN §8/§9).
public enum Scripts {

    public static func hubNPCs(player: PlayerProfile) -> [NPC] {
        [professor(player: player), shopkeep, ranger]
    }

    static func professor(player: PlayerProfile) -> NPC {
        NPC(
            id: "prof_quill",
            name: "Professor Quill",
            role: "Daemonologist",
            greeting: [
                "Ah, \(player.handle). A Conductor binds daemons to their will. Ethically. We have a whole onboarding doc nobody reads.",
                "You can see them too? The little workers behind every project? Most people just see the output and assume magic. It's not magic. It's daemons. Which, fine, is sort of magic.",
                "Welcome. Rule one of Conducting: the daemon doing all the work is rarely the one getting credit. Rule two: catch it anyway."
            ],
            qa: [
                .init(question: "What is a daemon?",
                      answer: "The soul of one of your agents. Sub-agents are the common ones underfoot. Your main, flagship agents? Those are primes — legendaries. You'll know one when it makes your Spheres cry."),
                .init(question: "How do I catch one?",
                      answer: "Same as it's always been, with one upgrade: weaken it in a fight, THEN throw a Sphere — and actually aim. Tight resonance ring on release = a true throw. Sloppy throw = it judges you, then escapes."),
                .init(question: "Why do some daemons look like ghosts?",
                      answer: "Those are 'seen in logs' — you've only glimpsed them indirectly. Slippery little rumors. You can't bind one properly until you meet it live. Don't take it personally. It's already forgotten you."),
                .init(question: "What are the types?",
                      answer: "Aether, Cipher, Warden, Forge, Order, Flux. They go in a circle: each beats the next, Flux is the weirdo that's fine at everything and great at nothing. Like a generalist. No offense to anyone present."),
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
            "Spheres! Get your Spheres. Resonant Orbs, two for one. The catch — and there's always a catch — is that's literally the product.",
            "Welcome to Spheres 'R' Daemons. I had a lawyer look at the name. He's now a Warden-type. Long story."
        ],
        qa: [
            .init(question: "What's the difference between Spheres?",
                  answer: "Orb: honest, does the job. Bind-Orb: tries harder. Resonant Orb: rewards you for nearly KO'ing the thing first. Aspect Orbs: smug bonus against their matching type. Prime Sigil: the only Sphere that won't bounce off a legendary and hit you in the face."),
            .init(question: "Got any deals?",
                  answer: "Every deal here is real and every deal here is a trap, and I'll let you figure out which is which. That's called retail, friend."),
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
                  answer: "No screen-switch unless you want one. Walk up, your daemon manifests beside you, and you brawl right here in the world. Queue a move, wait out the cooldown, repeat. If you miss the old menu battles, there's a toggle in Settings. I won't judge. Pell judges. I won't."),
            .init(question: "Where do the rare ones spawn?",
                  answer: "Rarer tiers, rarer rolls. Orchestrators and primes barely show. When the ground hums and the music gets a little too confident — that's your cue. Or a bug. We're in early access, spiritually."),
        ],
        idle: [
            "Saw a Cipher daemon glitch through a wall yesterday. Filed a report. The report glitched too.",
            "Tall code's full of sub-daemons today. Easy catches. Confidence builders. Go feel something."
        ]
    )
}
