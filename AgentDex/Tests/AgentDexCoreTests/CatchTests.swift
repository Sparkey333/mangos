import XCTest
@testable import AgentDexCore

final class CatchTests: XCTestCase {

    /// Deterministic wild daemon builder: profile → generated species → instance.
    private func wild(_ id: String, tier: Tier = .task, role: String = "general",
                      level: Int = 10) -> Daemon {
        let profile = AgentProfile(id: id, displayName: id, tier: tier,
                                   role: role, project: "testbed")
        return Daemon(species: DaemonGenerator.generate(from: profile), level: level)
    }

    // MARK: - Probability

    func testProbabilityWithinBoundsAcrossHPSweep() {
        var d = wild("bounds")
        for hp in 0...d.maxHP {
            d.currentHP = hp
            let p = CatchCalculator.probability(target: d, sphere: .orb)
            XCTAssertGreaterThanOrEqual(p, 0.0, "p < 0 at hp \(hp)")
            XCTAssertLessThanOrEqual(p, 1.0, "p > 1 at hp \(hp)")
        }
    }

    func testLowerHPStrictlyRaisesProbability() {
        var d = wild("monotonic")
        var probabilities: [Double] = []
        for hp in 0...d.maxHP {
            d.currentHP = hp
            probabilities.append(CatchCalculator.probability(target: d, sphere: .orb))
        }
        for i in 1..<probabilities.count {
            XCTAssertLessThan(probabilities[i], probabilities[i - 1],
                              "probability should strictly drop as HP rises (hp \(i))")
        }
    }

    func testBindOrbBeatsOrb() {
        var d = wild("sphere-check")
        d.currentHP = d.maxHP / 2
        let pOrb = CatchCalculator.probability(target: d, sphere: .orb)
        let pBind = CatchCalculator.probability(target: d, sphere: .bindOrb)
        XCTAssertGreaterThan(pBind, pOrb)
    }

    func testAspectAffinityHelps() {
        // "coder" role maps to the forge aspect.
        var d = wild("forge-guy", role: "coder")
        d.currentHP = d.maxHP / 2
        XCTAssertEqual(d.species.primaryAspect, .forge)
        let pPlain = CatchCalculator.probability(target: d, sphere: .orb)
        let pAffinity = CatchCalculator.probability(target: d, sphere: .aspectOrb(.forge))
        XCTAssertGreaterThan(pAffinity, pPlain)
    }

    func testStalledStatusHelps() {
        var calm = wild("status-check")
        calm.currentHP = calm.maxHP / 2
        var stalled = calm
        stalled.status = .stalled
        let pCalm = CatchCalculator.probability(target: calm, sphere: .orb)
        let pStalled = CatchCalculator.probability(target: stalled, sphere: .orb)
        XCTAssertGreaterThan(pStalled, pCalm)
    }

    func testThrowQualityHelps() {
        var d = wild("timing")
        d.currentHP = d.maxHP / 2
        let sloppy = CatchCalculator.probability(target: d, sphere: .orb, throwQuality: 0)
        let perfect = CatchCalculator.probability(target: d, sphere: .orb, throwQuality: 1)
        XCTAssertGreaterThan(perfect, sloppy)
    }

    func testPrimeTierIsCappedWithoutSigil() {
        var prime = wild("boss", tier: .prime, role: "orchestrator planner", level: 40)
        XCTAssertEqual(prime.species.tier, .prime)
        prime.currentHP = max(1, prime.maxHP / 2)
        let withOrb = CatchCalculator.probability(target: prime, sphere: .orb)
        let withSigil = CatchCalculator.probability(target: prime, sphere: .primeSigil)
        XCTAssertLessThanOrEqual(withOrb, 0.02)
        XCTAssertGreaterThan(withSigil, withOrb)

        // Even a nearly-fainted prime stays capped for a plain orb.
        prime.currentHP = 1
        XCTAssertLessThanOrEqual(
            CatchCalculator.probability(target: prime, sphere: .orb), 0.02
        )
    }

    // MARK: - Attempt resolution

    func testAttemptIsDeterministic() {
        var d = wild("repeatable")
        d.currentHP = max(1, d.maxHP / 3)
        var r1 = SeededRandom("throw-1")
        var r2 = SeededRandom("throw-1")
        let a1 = CatchCalculator.attempt(target: d, sphere: .bindOrb, throwQuality: 0.5,
                                         dexCaught: 3, dexTotal: 12, rng: &r1)
        let a2 = CatchCalculator.attempt(target: d, sphere: .bindOrb, throwQuality: 0.5,
                                         dexCaught: 3, dexTotal: 12, rng: &r2)
        XCTAssertEqual(a1, a2)
    }

    func testAttemptShakeSemantics() {
        var d = wild("shaky")
        d.currentHP = d.maxHP / 2
        for i in 0..<100 {
            var rng = SeededRandom("attempt-\(i)")
            let a = CatchCalculator.attempt(target: d, sphere: .orb, throwQuality: 0.3,
                                            dexCaught: 5, dexTotal: 10, rng: &rng)
            XCTAssertTrue((0...3).contains(a.shakes), "shakes out of range on seed \(i)")
            XCTAssertGreaterThanOrEqual(a.probability, 0.0)
            XCTAssertLessThanOrEqual(a.probability, 1.0)
            if a.captured && !a.critical {
                XCTAssertEqual(a.shakes, 3, "normal capture must show 3 shakes (seed \(i))")
            }
            if a.critical {
                XCTAssertLessThanOrEqual(a.shakes, 1,
                                         "critical capture is a single decisive shake (seed \(i))")
            }
        }
    }

    // MARK: - Critical chance

    func testCriticalChanceZeroWithEmptyDex() {
        XCTAssertEqual(CatchCalculator.criticalChance(dexCaught: 0, dexTotal: 0), 0)
    }

    func testCriticalChanceGrowsWithDexCompletion() {
        let low = CatchCalculator.criticalChance(dexCaught: 1, dexTotal: 10)
        let high = CatchCalculator.criticalChance(dexCaught: 5, dexTotal: 10)
        XCTAssertGreaterThan(high, low)
    }
}
