import Foundation

/// An opposing Conductor with a party — rival fights and story battles.
public struct TrainerProfile: Equatable, Sendable {
    public var id: String
    public var name: String
    public var title: String
    public var introLine: String
    public var defeatLine: String
    public var victoryLine: String       // what they say if THEY win
    public var party: [Daemon]
    public var payout: Int

    public init(id: String, name: String, title: String, introLine: String,
                defeatLine: String, victoryLine: String, party: [Daemon], payout: Int) {
        self.id = id; self.name = name; self.title = title
        self.introLine = introLine; self.defeatLine = defeatLine
        self.victoryLine = victoryLine; self.party = party; self.payout = payout
    }
}

/// Builds the rival's parties for each story stage, deterministically, scaled
/// to the player's progress. The rival is "Rune" — a Conductor who force-pushes.
public enum Rival {
    public static let name = "Rune"

    /// Build the rival for a story stage (1...3) against a bestiary, scaled so
    /// the fight is a real check without being a wall.
    public static func trainer(stage: Int, bestiary: Bestiary, playerMaxLevel: Int) -> TrainerProfile {
        let stage = max(1, min(3, stage))
        var rng = SeededRandom("rival|stage\(stage)")

        // Party size and level scale with the stage.
        let partySize = [1, 2, 3][stage - 1]
        let levelBump = [0, 2, 4][stage - 1]
        let level = max(3, min(Experience.maxLevel, playerMaxLevel + levelBump))

        // Rune favors lower tiers early, stronger later; never primes.
        let allowed: [Tier] = stage == 1 ? [.sub, .task] : stage == 2 ? [.task, .specialist] : [.specialist, .orchestrator]
        var pool = bestiary.species.filter { allowed.contains($0.tier) }
        if pool.isEmpty { pool = bestiary.species.filter { $0.tier != .prime } }
        if pool.isEmpty { pool = bestiary.species }

        var party: [Daemon] = []
        for i in 0..<partySize where !pool.isEmpty {
            let pick = pool[rng.int(in: 0...(pool.count - 1))]
            party.append(Daemon(species: pick, level: max(2, level - i)))
        }

        let intros = [
            "Rune force-pushes to main and doesn't look back. Let's see your test coverage.",
            "Back again? I've refactored since last time. You won't recognize my daemons. Or my commit history.",
            "This is the part where I stop going easy. Spoiler: I was never going easy."
        ]
        let defeats = [
            "Huh. Rolling back. This never happened.",
            "Fine. FINE. I'm bisecting where it all went wrong.",
            "You win. I'm filing this as a known issue."
        ]
        let victories = [
            "Shipped it. That's the difference between us.",
            "Your daemons need a code review. And a hug.",
            "Don't worry, losing builds character. You must be very charactered by now."
        ]

        return TrainerProfile(
            id: "rival_stage\(stage)",
            name: name,
            title: "Rival Conductor",
            introLine: intros[stage - 1],
            defeatLine: defeats[stage - 1],
            victoryLine: victories[stage - 1],
            party: party,
            payout: 150 * stage
        )
    }
}
