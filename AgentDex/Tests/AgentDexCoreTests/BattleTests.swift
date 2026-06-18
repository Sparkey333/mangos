import XCTest
@testable import AgentDexCore

final class BattleTests: XCTestCase {

    private func makeDaemon(_ id: String, tier: Tier = .specialist, role: String, level: Int = 25) -> Daemon {
        let p = AgentProfile(id: id, displayName: id, tier: tier, role: role, project: "t")
        return Daemon(species: DaemonGenerator.generate(from: p), level: level)
    }

    func testTypeChartCycle() {
        // Aether > Cipher > Warden > Forge > Order > Flux > Aether
        XCTAssertEqual(TypeChart.multiplier(attacker: .aether, defender: .cipher), TypeChart.superEffective)
        XCTAssertEqual(TypeChart.multiplier(attacker: .cipher, defender: .warden), TypeChart.superEffective)
        XCTAssertEqual(TypeChart.multiplier(attacker: .flux, defender: .aether), TypeChart.superEffective)
        // Reverse direction is resisted.
        XCTAssertEqual(TypeChart.multiplier(attacker: .cipher, defender: .aether), TypeChart.resisted)
        // Non-adjacent is neutral.
        XCTAssertEqual(TypeChart.multiplier(attacker: .aether, defender: .forge), TypeChart.neutral)
    }

    func testDamageIsPositiveAndReducesHP() {
        var atk = makeDaemon("a", role: "coder", level: 30)
        var def = makeDaemon("d", role: "general", level: 30)
        let move = MovePool.moves(for: atk.species.primaryAspect).last!
        var rng = SeededRandom("dmg")
        let before = def.currentHP
        let outcome = BattleEngine.resolveMove(attacker: &atk, defender: &def, move: move, rng: &rng)
        XCTAssertTrue(outcome.hit)
        XCTAssertGreaterThan(outcome.damage, 0)
        XCTAssertLessThan(def.currentHP, before)
    }

    func testHigherLevelHitsHarder() {
        let move = MovePool.basicStrike
        func avgDamage(level: Int) -> Double {
            var total = 0
            for i in 0..<200 {
                var atk = makeDaemon("a", role: "coder", level: level)
                var def = makeDaemon("d", role: "general", level: 30)
                def.currentHP = 100_000 // avoid faint clamping
                var rng = SeededRandom("lvl-\(level)-\(i)")
                let r = BattleEngine.damage(attacker: atk, defender: def, move: move, rng: &rng)
                total += r.amount
                _ = atk
            }
            return Double(total) / 200.0
        }
        XCTAssertGreaterThan(avgDamage(level: 50), avgDamage(level: 10))
    }

    func testStatusMoveAppliesCondition() {
        var atk = makeDaemon("loops", role: "log parsing", level: 30) // cipher → Loop
        var def = makeDaemon("d", role: "general", level: 30)
        let loop = MovePool.moves(for: .cipher).first { $0.effect == .loop }!
        var rng = SeededRandom("status")
        _ = BattleEngine.resolveMove(attacker: &atk, defender: &def, move: loop, rng: &rng)
        XCTAssertEqual(def.status, .looped)
    }

    func testKOClampsToZero() {
        var atk = makeDaemon("a", role: "coder", level: 100)
        var def = makeDaemon("d", tier: .sub, role: "general", level: 2)
        let move = MovePool.moves(for: atk.species.primaryAspect).last!
        var rng = SeededRandom("ko")
        for _ in 0..<10 where !def.isFainted {
            _ = BattleEngine.resolveMove(attacker: &atk, defender: &def, move: move, rng: &rng)
        }
        XCTAssertTrue(def.isFainted)
        XCTAssertGreaterThanOrEqual(def.currentHP, 0)
    }
}
