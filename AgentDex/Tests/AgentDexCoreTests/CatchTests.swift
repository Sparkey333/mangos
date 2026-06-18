import XCTest
@testable import AgentDexCore

final class CatchTests: XCTestCase {

    private func wild(_ id: String, tier: Tier = .task, role: String = "general", level: Int = 10) -> Daemon {
        let p = AgentProfile(id: id, displayName: id, tier: tier, role: role, project: "t")
        return Daemon(species: DaemonGenerator.generate(from: p), level: level)
    }

    func testProbabilityWithinBounds() {
        var d = wild("a")
        for hp in stride(from: 0, through: d.maxHP, by: max(1, d.maxHP / 10)) {
            d.currentHP = hp
            let p = CatchCalculator.probability(target: d, sphere: .orb)
            XCTAssertTrue((0...1).contains(p))
        }
    }

    func testLowerHPRaisesCatchRate() {
        var full = wild("a"); full.currentHP = full.maxHP
        var hurt = wild("a"); hurt.currentHP = max(1, hurt.maxHP / 10)
        let pFull = CatchCalculator.probability(target: full, sphere: .orb)
        let pHurt = CatchCalculator.probability(target: hurt, sphere: .orb)
        XCTAssertGreaterThan(pHurt, pFull)
    }

    func testBetterSphereRaisesCatchRate() {
        var d = wild("a"); d.currentHP = d.maxHP / 2
        let pOrb = CatchCalculator.probability(target: d, sphere: .orb)
        let pBind = CatchCalculator.probability(target: d, sphere: .bindOrb)
        XCTAssertGreaterThan(pBind, pOrb)
    }

    func testAspectAffinityHelps() {
        // Build a known-aspect target (coder → forge).
        var d = wild("forge-guy", role: "coder"); d.currentHP = d.maxHP / 2
        XCTAssertEqual(d.species.primaryAspect, .forge)
        let pPlain = CatchCalculator.probability(target: d, sphere: .orb)
        let pAffinity = CatchCalculator.probability(target: d, sphere: .aspectOrb(.forge))
        XCTAssertGreaterThan(pAffinity, pPlain)
    }

    func testStatusHelps() {
        var calm = wild("a"); calm.currentHP = calm.maxHP / 2
        var looped = calm; looped.status = .looped
        XCTAssertGreaterThan(
            CatchCalculator.probability(target: looped, sphere: .orb),
            CatchCalculator.probability(target: calm, sphere: .orb)
        )
    }

    func testThrowQualityHelps() {
        var d = wild("a"); d.currentHP = d.maxHP / 2
        let bad = CatchCalculator.probability(target: d, sphere: .orb, throwQuality: 0)
        let good = CatchCalculator.probability(target: d, sphere: .orb, throwQuality: 1)
        XCTAssertGreaterThan(good, bad)
    }

    func testPrimeNeedsPrimeSigil() {
        var prime = wild("boss", tier: .prime, role: "orchestrator", level: 40)
        prime.currentHP = 1 // basically fainted
        let withOrb = CatchCalculator.probability(target: prime, sphere: .orb)
        let withSigil = CatchCalculator.probability(target: prime, sphere: .primeSigil)
        XCTAssertLessThanOrEqual(withOrb, 0.02)
        XCTAssertGreaterThan(withSigil, withOrb)
    }

    func testAttemptIsDeterministic() {
        var d = wild("a"); d.currentHP = 1
        var r1 = SeededRandom("throw-1")
        var r2 = SeededRandom("throw-1")
        XCTAssertEqual(
            CatchCalculator.attempt(target: d, sphere: .bindOrb, throwQuality: 0.5, rng: &r1),
            CatchCalculator.attempt(target: d, sphere: .bindOrb, throwQuality: 0.5, rng: &r2)
        )
    }

    func testSaveStateCaptureFlow() {
        var save = SaveState.newGame(player: .placeholder)
        let d = wild("explore", role: "researcher")
        save.markSeen(d.species.id)
        XCTAssertEqual(save.dex[d.species.id], .seen)
        XCTAssertTrue(save.consumeSphere(.orb))
        save.capture(d)
        XCTAssertEqual(save.dex[d.species.id], .caught)
        XCTAssertEqual(save.party.count, 1)
    }
}
