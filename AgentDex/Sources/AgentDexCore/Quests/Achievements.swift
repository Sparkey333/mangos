import Foundation

/// Achievements: checked against the save after meaningful actions. The
/// registry is static; the save stores earned IDs.
public struct Achievement: Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var blurb: String
    public var secret: Bool

    public init(id: String, title: String, blurb: String, secret: Bool = false) {
        self.id = id; self.title = title; self.blurb = blurb; self.secret = secret
    }
}

public enum AchievementEngine {

    public static let all: [Achievement] = [
        Achievement(id: "first_catch", title: "Hello, Daemon",
                    blurb: "Bind your first daemon. It's been waiting its whole runtime for this."),
        Achievement(id: "party_of_six", title: "Full Stack",
                    blurb: "Fill your party with six daemons."),
        Achievement(id: "ten_catches", title: "Collector's Edition",
                    blurb: "Make 10 total catches."),
        Achievement(id: "all_aspects", title: "Well-Rounded",
                    blurb: "Own daemons of all six aspects."),
        Achievement(id: "prime_bound", title: "Orchestrated",
                    blurb: "Bind a prime-tier daemon. The legendary tier. The big one."),
        Achievement(id: "anomalous", title: "Off By One",
                    blurb: "Catch an anomalous daemon.", secret: true),
        Achievement(id: "rich", title: "Venture Funded",
                    blurb: "Hold 5,000¢ at once."),
        Achievement(id: "ascended", title: "Promoted to Production",
                    blurb: "Ascend a daemon."),
        Achievement(id: "rival_beaten", title: "LGTM",
                    blurb: "Win your first duel against Rune."),
        Achievement(id: "story_done", title: "Ship It",
                    blurb: "Complete the main story arc."),
        Achievement(id: "fifty_wins", title: "Battle Tested",
                    blurb: "Win 50 battles."),
        Achievement(id: "dex_half", title: "Halfway Documented",
                    blurb: "Bind half of all known species."),
        Achievement(id: "dex_full", title: "Fully Documented",
                    blurb: "Bind every known species. The Dex weeps with joy."),
        Achievement(id: "hundred_throws", title: "Warmed Up",
                    blurb: "Throw 100 Spheres. Your elbow files a complaint.")
    ]

    public static func byID(_ id: String) -> Achievement? { all.first { $0.id == id } }

    /// Check every achievement against the save; return the NEWLY earned ones
    /// (caller adds them to `save.earnedAchievements`).
    public static func newlyEarned(save: SaveState, dexTotal: Int) -> [Achievement] {
        var earned: [Achievement] = []
        func check(_ id: String, _ condition: Bool) {
            if condition && !save.earnedAchievements.contains(id),
               let a = byID(id) { earned.append(a) }
        }

        let owned = save.party + save.box
        let aspects = Set(owned.map { $0.species.primaryAspect })

        check("first_catch", save.stats.catches >= 1)
        check("party_of_six", save.party.count >= 6)
        check("ten_catches", save.stats.catches >= 10)
        check("all_aspects", aspects.count >= Aspect.allCases.count)
        check("prime_bound", owned.contains { $0.species.tier == .prime })
        check("anomalous", save.stats.anomalousCatches >= 1)
        check("rich", save.cycles >= 5000)
        check("ascended", owned.contains { $0.species.isAscended })
        check("rival_beaten", save.rivalStage >= 1)
        check("story_done", save.completedQuests.count >= StoryArc.quests.count)
        check("fifty_wins", save.stats.battlesWon >= 50)
        if dexTotal > 0 {
            check("dex_half", save.caughtCount * 2 >= dexTotal)
            check("dex_full", save.caughtCount >= dexTotal)
        }
        check("hundred_throws", save.stats.throwsCount >= 100)
        return earned
    }
}
