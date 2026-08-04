import Foundation

/// A story quest. Quests form a linear chain: quest N unlocks when N-1 is
/// complete. Objectives are *derived* from the save (no fragile counters).
public struct Quest: Equatable, Identifiable, Sendable {
    public enum Objective: Equatable, Sendable {
        case talkTo(npcID: String)
        case catchCount(Int)                 // total catches (stats.catches)
        case catchDistinct(Int)              // distinct species caught (dex)
        case seeDistinct(Int)                // distinct species seen
        case catchAspect(Aspect)             // catch any daemon of this aspect
        case catchTierAtLeast(Tier)          // catch a daemon of tier ≥ this
        case defeatRival(stage: Int)         // rivalStage ≥ stage
        case winBattles(Int)                 // stats.battlesWon
        case earnCycles(Int)                 // stats.cyclesEarned (lifetime)
    }

    public var id: String
    public var order: Int
    public var title: String
    public var giverNPC: String              // npc id, for "talk to X" flavor
    public var brief: String                 // the funny pitch
    public var objective: Objective
    public var objectiveText: String         // player-facing goal line
    public var rewardCycles: Int
    public var rewardSpheres: [String: Int]  // sphere id → count
    public var rewardItems: [String: Int]    // item id → count
    public var completionLine: String        // the payoff joke

    public init(id: String, order: Int, title: String, giverNPC: String, brief: String,
                objective: Objective, objectiveText: String, rewardCycles: Int,
                rewardSpheres: [String: Int] = [:], rewardItems: [String: Int] = [:],
                completionLine: String) {
        self.id = id; self.order = order; self.title = title; self.giverNPC = giverNPC
        self.brief = brief; self.objective = objective; self.objectiveText = objectiveText
        self.rewardCycles = rewardCycles; self.rewardSpheres = rewardSpheres
        self.rewardItems = rewardItems; self.completionLine = completionLine
    }
}

/// Evaluates quest objectives against the save. Pure functions.
public enum QuestEngine {

    /// (met, progress-string) for an objective given the current save.
    public static func evaluate(_ objective: Quest.Objective, save: SaveState) -> (done: Bool, progress: String) {
        switch objective {
        case .talkTo(let npcID):
            let done = save.talkedTo.contains(npcID)
            return (done, done ? "Done" : "Go say hi")
        case .catchCount(let n):
            return (save.stats.catches >= n, "\(min(save.stats.catches, n))/\(n) caught")
        case .catchDistinct(let n):
            let c = save.caughtCount
            return (c >= n, "\(min(c, n))/\(n) species bound")
        case .seeDistinct(let n):
            let s = save.seenCount
            return (s >= n, "\(min(s, n))/\(n) species seen")
        case .catchAspect(let aspect):
            let done = save.party.contains { $0.species.primaryAspect == aspect }
                || save.box.contains { $0.species.primaryAspect == aspect }
            return (done, done ? "Done" : "Catch a \(aspect.rawValue) daemon")
        case .catchTierAtLeast(let tier):
            let done = save.party.contains { $0.species.tier >= tier }
                || save.box.contains { $0.species.tier >= tier }
            return (done, done ? "Done" : "Bind a \(tier.rawValue)-tier or better")
        case .defeatRival(let stage):
            return (save.rivalStage >= stage, save.rivalStage >= stage ? "Done" : "Defeat Rune (bout \(stage))")
        case .winBattles(let n):
            return (save.stats.battlesWon >= n, "\(min(save.stats.battlesWon, n))/\(n) wins")
        case .earnCycles(let n):
            return (save.stats.cyclesEarned >= n, "\(min(save.stats.cyclesEarned, n))/\(n)¢ earned")
        }
    }

    /// The first not-yet-completed quest in the chain, if any.
    public static func currentQuest(save: SaveState) -> Quest? {
        StoryArc.quests.first { !save.completedQuests.contains($0.id) }
    }

    /// Whether the current quest's objective is met (ready to claim).
    public static func isCurrentQuestReady(save: SaveState) -> Bool {
        guard let q = currentQuest(save: save) else { return false }
        return evaluate(q.objective, save: save).done
    }
}

/// The 10-quest main arc: "The Silent Orchestrator". Rune is your rival; the
/// prime daemon is the endgame legendary.
public enum StoryArc {
    public static let quests: [Quest] = [
        Quest(id: "q01_hello_world", order: 1, title: "Hello, World",
              giverNPC: "prof_quill",
              brief: "Professor Quill wants a word. Several words. There will be a lecture embedded in them.",
              objective: .talkTo(npcID: "prof_quill"),
              objectiveText: "Talk to Professor Quill in the Hub",
              rewardCycles: 50, rewardSpheres: ["orb": 3],
              completionLine: "\"You listened to the whole onboarding! Statistically remarkable.\""),

        Quest(id: "q02_first_contact", order: 2, title: "First Contact",
              giverNPC: "prof_quill",
              brief: "Bind your first wild daemon. Weaken it first — Spheres bounce off confidence.",
              objective: .catchCount(1),
              objectiveText: "Catch any wild daemon",
              rewardCycles: 100, rewardItems: ["hotfix": 2],
              completionLine: "\"A bond! Or a binding. Legally distinct, spiritually identical.\""),

        Quest(id: "q03_dependency_check", order: 3, title: "Dependency Check",
              giverNPC: "ranger_pell",
              brief: "Pell says a party of one is a single point of failure. Diversify.",
              objective: .catchDistinct(3),
              objectiveText: "Bind 3 different species",
              rewardCycles: 150, rewardSpheres: ["bind_orb": 2],
              completionLine: "\"Three daemons. That's a stack. You're officially full-stack.\""),

        Quest(id: "q04_code_review", order: 4, title: "Code Review",
              giverNPC: "rival_rune",
              brief: "Rune has opinions about your team and would like to express them via violence.",
              objective: .defeatRival(stage: 1),
              objectiveText: "Defeat Rune in your first duel",
              rewardCycles: 250, rewardItems: ["debugger": 2],
              completionLine: "Rune: \"Approved with comments. So many comments.\""),

        Quest(id: "q05_coverage", order: 5, title: "Coverage",
              giverNPC: "archivist",
              brief: "The Archivist wants field data. See more daemons. Observation counts; catching is extra credit.",
              objective: .seeDistinct(5),
              objectiveText: "Encounter 5 different species",
              rewardCycles: 200, rewardSpheres: ["resonant_orb": 2],
              completionLine: "\"Five entries. My archive grows. My chairs remain uncomfortable. Balance.\""),

        Quest(id: "q06_aspect_oriented", order: 6, title: "Aspect-Oriented",
              giverNPC: "prof_quill",
              brief: "Quill needs a Cipher-aspect specimen. Something that speaks fluent log.",
              objective: .catchAspect(.cipher),
              objectiveText: "Catch a Cipher-aspect daemon",
              rewardCycles: 250, rewardSpheres: ["cipher_orb": 3],
              completionLine: "\"Marvelous. It's already redacted half my notes. Half my WHAT, you ask? Exactly.\""),

        Quest(id: "q07_merge_conflict", order: 7, title: "Merge Conflict",
              giverNPC: "rival_rune",
              brief: "Rune again. Something about 'settling whose branch is main.' It's a metaphor. Mostly.",
              objective: .defeatRival(stage: 2),
              objectiveText: "Defeat Rune's upgraded team",
              rewardCycles: 400, rewardItems: ["full_patch": 2],
              completionLine: "Rune: \"Conflict resolved. In your favor. This time. Ugh.\""),

        Quest(id: "q08_scaling_up", order: 8, title: "Scaling Up",
              giverNPC: "ranger_pell",
              brief: "The little ones are sweet, but Pell says the specialists roam the deep code. Go bind one.",
              objective: .catchTierAtLeast(.specialist),
              objectiveText: "Bind a specialist-tier daemon or better",
              rewardCycles: 500, rewardSpheres: ["bind_orb": 3],
              completionLine: "\"A specialist! Watch it refuse to do anything outside its job description.\""),

        Quest(id: "q09_silent_orchestrator", order: 9, title: "The Silent Orchestrator",
              giverNPC: "rival_rune",
              brief: "The prime daemon has gone quiet. Rune wants to reach it first. Rude. Beat Rune to the door.",
              objective: .defeatRival(stage: 3),
              objectiveText: "Defeat Rune's final team",
              rewardCycles: 800, rewardSpheres: ["prime_sigil": 1],
              completionLine: "Rune: \"Fine. Go. It was never about winning. (It was entirely about winning.)\""),

        Quest(id: "q10_prime_directive", order: 10, title: "Prime Directive",
              giverNPC: "prof_quill",
              brief: "It's out there — the flagship, the one that runs the others. Bring a Prime Sigil and your whole heart.",
              objective: .catchTierAtLeast(.prime),
              objectiveText: "Bind a prime-tier daemon",
              rewardCycles: 2000, rewardItems: ["training_data": 3],
              completionLine: "\"You bound a prime. The orchestra has a Conductor again. Try not to think about the metaphor too hard.\"")
    ]
}
