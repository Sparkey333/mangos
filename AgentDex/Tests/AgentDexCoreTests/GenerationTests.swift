import XCTest
@testable import AgentDexCore

final class GenerationTests: XCTestCase {

    private let sample = AgentProfile(
        id: "explore", displayName: "Explore", tier: .specialist,
        role: "researcher", project: "mangos", origin: .used, encounters: 40
    )

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

    func testRoleMapsToAspect() {
        XCTAssertEqual(Aspect.from(role: "researcher"), .aether)
        XCTAssertEqual(Aspect.from(role: "coder implementer"), .forge)
        XCTAssertEqual(Aspect.from(role: "architect"), .order)
        XCTAssertEqual(Aspect.from(role: "review security"), .warden)
        XCTAssertEqual(Aspect.from(role: "log parsing"), .cipher)
        XCTAssertEqual(Aspect.from(role: "general"), .flux)
    }

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

    func testPrimesAlwaysGetSecondaryAspect() {
        var p = sample; p.tier = .prime; p.id = "prime-x"
        let s = DaemonGenerator.generate(from: p)
        XCTAssertNotNil(s.secondaryAspect)
        XCTAssertNotEqual(s.secondaryAspect, s.primaryAspect)
    }

    func testSubsHaveNoSecondaryAspect() {
        var p = sample; p.tier = .sub; p.id = "sub-x"
        let s = DaemonGenerator.generate(from: p)
        XCTAssertNil(s.secondaryAspect)
    }

    func testKnowsUpToFourMoves() {
        let s = DaemonGenerator.generate(from: sample)
        XCTAssertGreaterThan(s.moves.count, 0)
        XCTAssertLessThanOrEqual(s.moves.count, 4)
    }

    func testSigilMatchesTier() {
        for tier in Tier.allCases {
            var p = sample; p.tier = tier; p.id = "sig-\(tier.rawValue)"
            XCTAssertEqual(DaemonGenerator.generate(from: p).sprite.sigil, tier.sigil)
        }
    }

    func testBestiaryRegionsAndSpawns() {
        let bestiary = Bestiary(profiles: SampleData.agents)
        XCTAssertTrue(bestiary.regions.contains("mangos"))
        var rng = SeededRandom("encounter-seed")
        let rolled = bestiary.rollEncounter(inRegion: "mangos", rng: &rng)
        XCTAssertNotNil(rolled)
    }
}
