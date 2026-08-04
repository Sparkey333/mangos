import XCTest
@testable import AgentDexCore

/// Pure combat-math tests: TypeChart, computeHit, stat stages, statuses,
/// abilities, accuracy and turn order. Every RNG is seeded with a fixed
/// string and every loop is bounded, so these are fully deterministic.
final class BattleTests: XCTestCase {

    // MARK: - Helpers

    /// Builds a daemon with a controlled ability and no secondary aspect so
    /// engine tests are not polluted by generation randomness.
    /// `.cleanCode` is inert for damage math (it only gates status infliction).
    private func makeDaemon(_ id: String, tier: Tier = .specialist, role: String,
                            level: Int, ability: Ability = .cleanCode) -> Daemon {
        let profile = AgentProfile(id: id, displayName: id, tier: tier, role: role, project: "t")
        var species = DaemonGenerator.generate(from: profile)
        species.ability = ability
        species.secondaryAspect = nil
        return Daemon(species: species, level: level)
    }

    // MARK: - Type chart

    func testTypeChartCycleAndDualDefenders() {
        // Aether > Cipher (super-effective)
        XCTAssertEqual(TypeChart.multiplier(attacker: .aether, defender: .cipher),
                       TypeChart.superEffective)
        // Cipher attacking back into Aether is resisted.
        XCTAssertEqual(TypeChart.multiplier(attacker: .cipher, defender: .aether),
                       TypeChart.resisted)
        // Non-adjacent pair is neutral.
        XCTAssertEqual(TypeChart.multiplier(attacker: .aether, defender: .forge),
                       TypeChart.neutral)

        // Dual-defender multiplier is the product of the singles.
        let defenders: [Aspect] = [.cipher, .flux]
        let combined = TypeChart.multiplier(attacker: .aether, defenders: defenders)
        let product = TypeChart.multiplier(attacker: .aether, defender: .cipher)
            * TypeChart.multiplier(attacker: .aether, defender: .flux)
        XCTAssertEqual(combined, product, accuracy: 1e-9)
        // And concretely: super-effective x resisted.
        XCTAssertEqual(combined, TypeChart.superEffective * TypeChart.resisted, accuracy: 1e-9)
    }

    // MARK: - computeHit basics

    func testComputeHitDealsAtLeastOneDamage() {
        let attacker = makeDaemon("hit-a", role: "coder", level: 30)
        let defender = makeDaemon("hit-d", role: "general", level: 30)
        var rng = SeededRandom("single-hit")
        let hit = BattleEngine.computeHit(attacker: attacker, defender: defender,
                                          move: MovePool.basicStrike, rng: &rng)
        XCTAssertGreaterThanOrEqual(hit.amount, 1)
    }

    func testHigherLevelAttackerHitsHarderOnAverage() {
        let defender = makeDaemon("lvl-d", role: "general", level: 20)

        func averageDamage(attackerLevel: Int) -> Double {
            let attacker = makeDaemon("lvl-a", role: "coder", level: attackerLevel)
            var total = 0
            for i in 0..<200 {
                var rng = SeededRandom("level-scaling-\(attackerLevel)-\(i)")
                let hit = BattleEngine.computeHit(attacker: attacker, defender: defender,
                                                  move: MovePool.basicStrike, rng: &rng)
                XCTAssertGreaterThanOrEqual(hit.amount, 1)
                total += hit.amount
            }
            return Double(total) / 200.0
        }

        XCTAssertGreaterThan(averageDamage(attackerLevel: 50),
                             averageDamage(attackerLevel: 10))
    }

    // MARK: - STAB

    func testSTABAttackerOutdamagesNonSTABOnAverage() {
        // "researcher" maps to aether; "general" maps to flux.
        let stabAttacker = makeDaemon("stab-a", role: "researcher", level: 30)
        let plainAttacker = makeDaemon("stab-b", role: "general", level: 30)
        // Neutral defender for the aether move ("coder" -> forge).
        let defender = makeDaemon("stab-d", role: "coder", level: 30)
        let move = MovePool.moves(for: .aether).first { $0.power > 0 }!

        XCTAssertTrue(stabAttacker.species.aspects.contains(move.aspect))
        XCTAssertFalse(plainAttacker.species.aspects.contains(move.aspect))

        func averageDamage(_ attacker: Daemon, tag: String) -> Double {
            var total = 0
            for i in 0..<200 {
                var rng = SeededRandom("stab-\(tag)-\(i)")
                total += BattleEngine.computeHit(attacker: attacker, defender: defender,
                                                 move: move, rng: &rng).amount
            }
            return Double(total) / 200.0
        }

        XCTAssertGreaterThan(averageDamage(stabAttacker, tag: "yes"),
                             averageDamage(plainAttacker, tag: "no"))
    }

    // MARK: - Stat stages

    func testStatStagesMultipliersAndClamping() {
        var stages = StatStages()
        stages[.atk] = 2
        XCTAssertEqual(stages.multiplier(.atk), 2.0)
        stages[.atk] = -2
        XCTAssertEqual(stages.multiplier(.atk), 0.5)

        // apply() returns nil once the +6 cap is hit.
        stages[.atk] = 6
        let overCap = stages.apply(1, to: .atk)
        XCTAssertNil(overCap)
        XCTAssertEqual(stages[.atk], 6)

        // Same at the -6 floor.
        stages[.atk] = -6
        let underCap = stages.apply(-1, to: .atk)
        XCTAssertNil(underCap)
        XCTAssertEqual(stages[.atk], -6)

        XCTAssertEqual(StatStages.accuracyMultiplier(netStage: 0), 1.0)
    }

    // MARK: - battleStat

    func testBattleStatAppliesStagesAndStatus() {
        var d = makeDaemon("bstat", role: "coder", level: 20)
        let baseAtk = d.stat(.atk)
        let baseSpe = d.stat(.spe)

        // +2 atk stage doubles effective attack (allow 1 for int truncation).
        d.stages[.atk] = 2
        XCTAssertLessThanOrEqual(abs(d.battleStat(.atk) - baseAtk * 2), 1)
        d.stages.reset()

        // RATE-LIMITED halves speed.
        d.status = .ratelimited
        XCTAssertLessThanOrEqual(abs(d.battleStat(.spe) - baseSpe / 2), 1)

        // OVERHEATED cuts attack to 2/3.
        d.status = .overheated
        XCTAssertLessThanOrEqual(abs(d.battleStat(.atk) - (baseAtk * 2) / 3), 1)
    }

    // MARK: - Failsafe

    func testFailsafeSurvivesOneFatalHitThenFaints() {
        var d = makeDaemon("failsafe", role: "review", level: 20, ability: .failsafe)
        XCTAssertTrue(d.failsafeAvailable)
        XCTAssertEqual(d.currentHP, d.maxHP)

        let overkill = d.currentHP + 25
        let first = BattleEngine.applyDamage(overkill, to: &d)
        XCTAssertTrue(first.failsafed)
        XCTAssertEqual(d.currentHP, 1)
        XCTAssertFalse(d.failsafeAvailable)
        XCTAssertFalse(d.isFainted)

        let second = BattleEngine.applyDamage(overkill, to: &d)
        XCTAssertFalse(second.failsafed)
        XCTAssertEqual(d.currentHP, 0)
        XCTAssertTrue(d.isFainted)
    }

    // MARK: - Load Balancer

    func testLoadBalancerCapsSingleHitAtHalfMaxHP() {
        let attacker = makeDaemon("lb-a", tier: .prime, role: "orchestrator", level: 90)
        let defender = makeDaemon("lb-d", role: "general", level: 10, ability: .loadBalancer)
        let move = MovePool.moves(for: attacker.species.primaryAspect)
            .filter { $0.power > 0 }
            .max { $0.power < $1.power }!

        for i in 0..<10 {
            var rng = SeededRandom("load-balancer-\(i)")
            let hit = BattleEngine.computeHit(attacker: attacker, defender: defender,
                                              move: move, rng: &rng)
            XCTAssertGreaterThanOrEqual(hit.amount, 1)
            XCTAssertLessThanOrEqual(hit.amount, defender.maxHP / 2)
        }
    }

    // MARK: - Hardened

    func testHardenedReducesSuperEffectiveDamage() {
        // Aether attacker with an aether move; cipher defender is super-effective prey.
        let attacker = makeDaemon("hard-a", role: "researcher", level: 30)
        let move = MovePool.moves(for: .aether).first { $0.power > 0 }!

        let profile = AgentProfile(id: "hard-d", displayName: "hard-d",
                                   tier: .specialist, role: "log parsing", project: "t")
        var plainSpecies = DaemonGenerator.generate(from: profile)
        plainSpecies.secondaryAspect = nil
        plainSpecies.ability = .cleanCode
        var hardenedSpecies = plainSpecies
        hardenedSpecies.ability = .hardened

        let plainDefender = Daemon(species: plainSpecies, level: 30)
        let hardenedDefender = Daemon(species: hardenedSpecies, level: 30)
        XCTAssertGreaterThan(
            TypeChart.multiplier(attacker: move.aspect, defenders: plainDefender.species.aspects),
            1.0)

        var plainTotal = 0
        var hardenedTotal = 0
        for i in 0..<100 {
            // Same seed for both so the crit/damage rolls are identical.
            var rngPlain = SeededRandom("hardened-\(i)")
            var rngHard = SeededRandom("hardened-\(i)")
            plainTotal += BattleEngine.computeHit(attacker: attacker, defender: plainDefender,
                                                  move: move, rng: &rngPlain).amount
            hardenedTotal += BattleEngine.computeHit(attacker: attacker, defender: hardenedDefender,
                                                     move: move, rng: &rngHard).amount
        }
        XCTAssertLessThan(hardenedTotal, plainTotal)
    }

    // MARK: - Accuracy

    func testPerfectAccuracyMoveAlwaysHitsWithNeutralStages() {
        let attacker = makeDaemon("acc-a", role: "coder", level: 20)
        let defender = makeDaemon("acc-d", role: "general", level: 20)
        XCTAssertEqual(MovePool.basicStrike.accuracy, 100)
        for i in 0..<50 {
            var rng = SeededRandom("accuracy-\(i)")
            XCTAssertTrue(BattleEngine.rollAccuracy(attacker: attacker, defender: defender,
                                                    move: MovePool.basicStrike, rng: &rng))
        }
    }

    // MARK: - Turn order

    func testPriorityMoveBeatsSpeed() {
        // Slow, low-level warden vs a fast, high-level cipher.
        let slowPlayer = makeDaemon("prio-p", role: "review", level: 5)
        let fastEnemy = makeDaemon("prio-e", role: "log parsing", level: 50)
        XCTAssertLessThan(slowPlayer.battleStat(.spe), fastEnemy.battleStat(.spe))

        let priorityMove = MovePool.moves(for: .forge).first { $0.priority > 0 }!
        let normalMove = MovePool.basicStrike
        XCTAssertEqual(normalMove.priority, 0)

        for i in 0..<10 {
            // Priority +1 on the slow side wins the turn.
            var rng = SeededRandom("priority-\(i)")
            XCTAssertTrue(BattleEngine.playerActsFirst(
                player: slowPlayer, playerMove: priorityMove,
                enemy: fastEnemy, enemyMove: normalMove, rng: &rng))

            // Priority +1 on the fast side also wins.
            var rngReversed = SeededRandom("priority-rev-\(i)")
            XCTAssertFalse(BattleEngine.playerActsFirst(
                player: slowPlayer, playerMove: normalMove,
                enemy: fastEnemy, enemyMove: priorityMove, rng: &rngReversed))

            // Equal priority falls back to speed: the fast enemy goes first.
            var rngSpeed = SeededRandom("priority-speed-\(i)")
            XCTAssertFalse(BattleEngine.playerActsFirst(
                player: slowPlayer, playerMove: normalMove,
                enemy: fastEnemy, enemyMove: normalMove, rng: &rngSpeed))
        }
    }
}
