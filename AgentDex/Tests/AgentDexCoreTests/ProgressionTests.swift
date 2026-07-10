import XCTest
@testable import AgentDexCore

final class ProgressionTests: XCTestCase {

    private func species(_ id: String, tier: Tier = .task,
                         role: String = "general") -> DaemonSpecies {
        let profile = AgentProfile(id: id, displayName: id, tier: tier,
                                   role: role, project: "testbed")
        return DaemonGenerator.generate(from: profile)
    }

    // MARK: - XP curve

    func testTotalXPCurve() {
        XCTAssertEqual(Experience.totalXP(forLevel: 1), 1)
        XCTAssertEqual(Experience.totalXP(forLevel: 2), 8)
        XCTAssertEqual(Experience.totalXP(forLevel: 10), 1000)
    }

    func testLevelForXPRoundTrip() {
        for n in [1, 2, 10, 37, 99, 100] {
            XCTAssertEqual(Experience.level(forXP: Experience.totalXP(forLevel: n)), n,
                           "level(totalXP(\(n))) should be \(n)")
        }
    }

    func testLevelJustAboveThresholdStaysBelowNext() {
        for n in [1, 2, 10, 37, 99] {
            XCTAssertEqual(Experience.level(forXP: Experience.totalXP(forLevel: n) + 1), n,
                           "one XP past level \(n) is still level \(n)")
        }
    }

    func testXPToNextLevelAtMax() {
        XCTAssertEqual(
            Experience.xpToNextLevel(currentXP: Experience.totalXP(forLevel: 100)), 0
        )
    }

    func testLevelProgressBounded() {
        let samples = [0, 1, 2, 5, 8, 9, 500, 999, 1000, 123_456,
                       Experience.totalXP(forLevel: 100),
                       Experience.totalXP(forLevel: 100) + 5]
        for xp in samples {
            let progress = Experience.levelProgress(currentXP: xp)
            XCTAssertGreaterThanOrEqual(progress, 0.0, "progress < 0 at xp \(xp)")
            XCTAssertLessThanOrEqual(progress, 1.0, "progress > 1 at xp \(xp)")
        }
    }

    // MARK: - XP gain

    func testGainScalesWithDefeatedLevel() {
        let sp = species("victim")
        let weak = Daemon(species: sp, level: 8)
        let strong = Daemon(species: sp, level: 24)
        let gainWeak = Experience.gain(defeating: weak, winnerLevel: 30, isTrainer: false)
        let gainStrong = Experience.gain(defeating: strong, winnerLevel: 30, isTrainer: false)
        XCTAssertGreaterThan(gainStrong, gainWeak)
    }

    func testTrainerBattlesPayAtLeastAsMuch() {
        let defeated = Daemon(species: species("opponent"), level: 15)
        let wildGain = Experience.gain(defeating: defeated, winnerLevel: 15, isTrainer: false)
        let trainerGain = Experience.gain(defeating: defeated, winnerLevel: 15, isTrainer: true)
        XCTAssertGreaterThanOrEqual(trainerGain, wildGain)
    }

    // MARK: - Ascension

    func testCanAscendThresholdsPerTier() {
        let thresholds: [(Tier, Int)] = [
            (.sub, 18), (.task, 28), (.specialist, 36),
            (.orchestrator, 45), (.prime, 60)
        ]
        for (tier, threshold) in thresholds {
            let sp = species("asc-\(tier.rawValue)", tier: tier)
            XCTAssertTrue(Ascension.canAscend(sp, at: threshold),
                          "\(tier) should ascend at \(threshold)")
            XCTAssertFalse(Ascension.canAscend(sp, at: threshold - 1),
                           "\(tier) should NOT ascend at \(threshold - 1)")
        }
    }

    func testAscendTransformsSpecies() {
        let base = species("riser", tier: .specialist, role: "researcher")
        let ascended = Ascension.ascend(base)

        XCTAssertTrue(ascended.isAscended)
        XCTAssertNotEqual(ascended.name, base.name)

        // Every base stat strictly increases.
        XCTAssertGreaterThan(ascended.baseStats.hp, base.baseStats.hp)
        XCTAssertGreaterThan(ascended.baseStats.atk, base.baseStats.atk)
        XCTAssertGreaterThan(ascended.baseStats.def, base.baseStats.def)
        XCTAssertGreaterThan(ascended.baseStats.spa, base.baseStats.spa)
        XCTAssertGreaterThan(ascended.baseStats.spd, base.baseStats.spd)
        XCTAssertGreaterThan(ascended.baseStats.spe, base.baseStats.spe)

        XCTAssertEqual(ascended.catchBaseRate, max(1, base.catchBaseRate / 2))
        XCTAssertEqual(ascended.sprite.segments, base.sprite.segments + 2)
        XCTAssertGreaterThanOrEqual(ascended.sprite.auraIntensity,
                                    base.sprite.auraIntensity)
    }

    func testAscendIsIdempotent() {
        let base = species("stable", tier: .task, role: "coder")
        let once = Ascension.ascend(base)
        let twice = Ascension.ascend(once)
        XCTAssertEqual(twice, once)
    }

    // MARK: - Move learning

    func testFreshLevelOneDaemonMovesRespectUnlockLevel() {
        let d = Daemon(species: species("rookie", role: "coder"), level: 1)
        XCTAssertLessThanOrEqual(d.moves.count, 4)
        XCTAssertFalse(d.moves.isEmpty)
        for move in d.moves {
            XCTAssertLessThanOrEqual(move.unlockLevel, 1,
                                     "\(move.id) unlocks past level 1")
        }
    }

    func testKnownMovesAtLevelTwelveAreUnlocked() {
        let sp = species("midgame", tier: .specialist, role: "researcher")
        let moves = sp.knownMoves(at: 12)
        XCTAssertLessThanOrEqual(moves.count, 4)
        for move in moves {
            XCTAssertLessThanOrEqual(move.unlockLevel, 12,
                                     "\(move.id) unlocks past level 12")
        }
    }

    func testNewlyUnlockedForgeMovesBetweenLevels() {
        let unlocked = MovePool.newlyUnlocked(for: .forge, from: 1, to: 18)
        XCTAssertFalse(unlocked.isEmpty)
        for move in unlocked {
            XCTAssertTrue((2...18).contains(move.unlockLevel),
                          "\(move.id) unlockLevel \(move.unlockLevel) outside 2...18")
        }
    }
}
