import XCTest
@testable import AgentDexCore

final class GenerationTests: XCTestCase {

    /// A fixed baseline profile; individual tests copy and tweak it.
    private let sample = AgentProfile(
        id: "explore", displayName: "Explore", tier: .specialist,
        role: "researcher", project: "mangos", origin: .used, encounters: 40
    )

    // MARK: - Hashing & determinism

    func testStableHashIsDeterministic() {
        XCTAssertEqual(stableHash("explore|mangos"), stableHash("explore|mangos"))
        XCTAssertNotEqual(stableHash("explore|mangos"), stableHash("explore|other"))
    }

    func testSameProfileGeneratesIdenticalSpecies() {
        let a = DaemonGenerator.generate(from: sample)
        let b = DaemonGenerator.generate(from: sample)
        XCTAssertEqual(a, b, "Generation must be deterministic for the same agent")
    }

    func testDifferentProjectsDiverge() {
        var other = sample; other.project = "other-project"
        let a = DaemonGenerator.generate(from: sample)
        let b = DaemonGenerator.generate(from: other)
        XCTAssertNotEqual(a.ivs, b.ivs, "Habitat should perturb the creature")
    }

    // MARK: - Aspect mapping

    func testRoleMapsToAspect() {
        XCTAssertEqual(Aspect.from(role: "researcher"), .aether)
        XCTAssertEqual(Aspect.from(role: "coder implementer"), .forge)
        XCTAssertEqual(Aspect.from(role: "architect"), .order)
        XCTAssertEqual(Aspect.from(role: "review security"), .warden)
        XCTAssertEqual(Aspect.from(role: "log parsing"), .cipher)
        XCTAssertEqual(Aspect.from(role: "general"), .flux)
    }

    // MARK: - Stats

    func testBaseStatTotalRespectsTier() {
        for tier in Tier.allCases {
            var p = sample; p.tier = tier; p.id = "x-\(tier.rawValue)"
            let s = DaemonGenerator.generate(from: p)
            XCTAssertEqual(s.baseStats.total, tier.baseStatTotal,
                           "BST should equal the tier budget for \(tier)")
        }
    }

    func testIVsInRange() {
        let s = DaemonGenerator.generate(from: sample)
        for stat in Stat.allCases {
            XCTAssertTrue((0...31).contains(s.ivs[stat]), "IV out of range for \(stat)")
        }
    }

    // MARK: - Aspects & abilities per tier

    func testPrimesAlwaysGetSecondaryAspectAndCrownAbility() {
        for i in 0..<20 {
            var p = sample; p.tier = .prime; p.id = "prime-\(i)"
            let s = DaemonGenerator.generate(from: p)
            XCTAssertNotNil(s.secondaryAspect, "Primes must always dual-aspect (\(p.id))")
            XCTAssertNotEqual(s.secondaryAspect, s.primaryAspect,
                              "Secondary aspect must differ from primary (\(p.id))")
            let allowed = Ability.pool(for: s.primaryAspect) + [.loadBalancer]
            XCTAssertTrue(allowed.contains(s.ability),
                          "Prime ability must come from the aspect pool or be loadBalancer (\(p.id))")
        }
    }

    func testSubsHaveNoSecondaryAspect() {
        var p = sample; p.tier = .sub; p.id = "sub-x"
        let s = DaemonGenerator.generate(from: p)
        XCTAssertNil(s.secondaryAspect)
    }

    func testSigilMatchesTierAndNonPrimeAbilityFromPool() {
        for tier in Tier.allCases {
            var p = sample; p.tier = tier; p.id = "sig-\(tier.rawValue)"
            let s = DaemonGenerator.generate(from: p)
            XCTAssertEqual(s.sprite.sigil, tier.sigil, "Sigil must read the tier for \(tier)")
            if tier != .prime {
                XCTAssertTrue(Ability.pool(for: s.primaryAspect).contains(s.ability),
                              "Non-prime ability must come from the primary aspect pool (\(tier))")
            }
        }
    }

    // MARK: - Source profile round-trip

    func testSpeciesCarriesSourceProfile() {
        let s = DaemonGenerator.generate(from: sample)
        XCTAssertEqual(s.sourceProfile, sample)
    }

    // MARK: - Moves

    func testKnownMovesAtLevelOne() {
        let s = DaemonGenerator.generate(from: sample)
        let moves = s.knownMoves(at: 1)
        XCTAssertGreaterThanOrEqual(moves.count, 1)
        XCTAssertLessThanOrEqual(moves.count, 4)
        for move in moves {
            XCTAssertLessThanOrEqual(move.unlockLevel, 1,
                                     "\(move.name) should be unlocked at level 1")
        }
    }

    func testKnownMovesAtHighLevelIsFull() {
        let s = DaemonGenerator.generate(from: sample)
        XCTAssertEqual(s.knownMoves(at: 40).count, 4)
    }

    // MARK: - Catch rate

    func testSeenInLogsHalvesCatchRate() {
        for tier in Tier.allCases {
            var usedProfile = sample
            usedProfile.tier = tier; usedProfile.id = "used-\(tier.rawValue)"
            usedProfile.origin = .used
            var ghostProfile = sample
            ghostProfile.tier = tier; ghostProfile.id = "ghost-\(tier.rawValue)"
            ghostProfile.origin = .seenInLogs

            let used = DaemonGenerator.generate(from: usedProfile).catchBaseRate
            let ghost = DaemonGenerator.generate(from: ghostProfile).catchBaseRate
            XCTAssertEqual(ghost, max(1, used / 2),
                           "Log-only ghosts should be twice as slippery for \(tier)")
        }
    }

    // MARK: - Bestiary

    func testBestiaryRegionsSpawnsAndLevels() {
        let bestiary = Bestiary(profiles: SampleData.agents)
        XCTAssertTrue(bestiary.regions.contains("mangos"))

        var rng = SeededRandom("encounter-seed")
        let rolled = bestiary.rollEncounter(inRegion: "mangos", rng: &rng)
        XCTAssertNotNil(rolled)

        XCTAssertGreaterThanOrEqual(bestiary.wildLevel(for: "explore"),
                                    Tier.specialist.baseLevelBand.lowerBound)
    }

    // MARK: - DaemonRecord round-trip

    func testRecordRoundTripPreservesState() {
        let species = DaemonGenerator.generate(from: sample)
        let daemon = Daemon(species: species, level: 20, currentHP: 10,
                            status: .stalled, statusTurns: 2)
        let record = DaemonRecord(from: daemon)
        let hydrated = record.hydrate()

        XCTAssertEqual(hydrated.species.id, daemon.species.id)
        XCTAssertEqual(hydrated.species.name, daemon.species.name)
        XCTAssertEqual(hydrated.level, daemon.level)
        XCTAssertEqual(hydrated.xp, daemon.xp)
        XCTAssertEqual(hydrated.currentHP, daemon.currentHP)
        XCTAssertEqual(hydrated.status, daemon.status)
    }

    func testRecordRoundTripPreservesAscension() {
        let base = DaemonGenerator.generate(from: sample)
        let ascended = Ascension.ascend(base)
        XCTAssertTrue(ascended.isAscended)

        let daemon = Daemon(species: ascended, level: 40)
        let record = DaemonRecord(from: daemon)
        XCTAssertTrue(record.isAscended)

        let hydrated = record.hydrate()
        XCTAssertTrue(hydrated.species.isAscended)
        XCTAssertEqual(hydrated.species.name, ascended.name,
                       "Hydration must regenerate the same ascended form")
    }
}
