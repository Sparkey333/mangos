import XCTest
@testable import AgentDexCore

/// End-to-end `BattleSession` tests: determinism, victory/XP flow, trainer
/// battles, switching, items, status moves and blocked actions. All sessions
/// use fixed string seeds and every loop is bounded.
final class SessionTests: XCTestCase {

    // MARK: - Helpers

    /// Deterministic daemon with a controlled ability and no secondary aspect.
    /// `.cleanCode` is inert for damage math.
    private func makeDaemon(_ id: String, tier: Tier = .specialist, role: String,
                            level: Int, ability: Ability = .cleanCode) -> Daemon {
        let profile = AgentProfile(id: id, displayName: id, tier: tier, role: role, project: "t")
        var species = DaemonGenerator.generate(from: profile)
        species.ability = ability
        species.secondaryAspect = nil
        return Daemon(species: species, level: level)
    }

    /// The active daemon's first damaging move, falling back to the universal strike.
    private func damagingMove(for session: BattleSession) -> Move {
        session.activeDaemon.moves.first { $0.power > 0 } ?? MovePool.basicStrike
    }

    // MARK: - Determinism

    func testSameSeedProducesIdenticalEventStreams() {
        let player = makeDaemon("det-p", role: "researcher", level: 30)
        let wild = makeDaemon("det-w", tier: .sub, role: "general", level: 5)

        func run() -> [BattleEvent] {
            // `player`/`wild` are value types, so each run gets pristine copies.
            let session = BattleSession(kind: .wild(wild), party: [player], seed: "determinism-seed")
            var events = session.start()
            for _ in 0..<40 where !session.isOver {
                events += session.submit(.move(damagingMove(for: session)))
            }
            return events
        }

        XCTAssertEqual(run(), run())
    }

    // MARK: - Wild victory

    func testWildVictoryEmitsXPPayoutAndEnd() {
        let player = makeDaemon("wv-p", role: "researcher", level: 40)
        let wild = makeDaemon("wv-w", tier: .sub, role: "general", level: 3)
        let session = BattleSession(kind: .wild(wild), party: [player], seed: "wild-victory")

        var events = session.start()
        for _ in 0..<50 where !session.isOver {
            events += session.submit(.move(damagingMove(for: session)))
        }

        XCTAssertTrue(session.isOver)
        XCTAssertEqual(session.outcome, .victory)
        XCTAssertTrue(events.contains { if case .xpGained = $0 { return true }; return false })
        XCTAssertTrue(events.contains { if case .payout = $0 { return true }; return false })
        XCTAssertTrue(events.contains(.battleEnded(outcome: .victory)))
    }

    // MARK: - XP / level-up path

    func testXPAndLevelUpPathAgainstStrongerWild() {
        let baseline = Experience.totalXP(forLevel: 5)
        let player = makeDaemon("xp-p", role: "coder", level: 5)
        XCTAssertEqual(player.xp, baseline)

        let wild = makeDaemon("xp-w", tier: .task, role: "general", level: 25)
        let session = BattleSession(kind: .wild(wild), party: [player], seed: "xp-path")

        var events = session.start()
        for _ in 0..<80 where !session.isOver {
            events += session.submit(.move(damagingMove(for: session)))
        }

        // A lone level-5 daemon vs a level-25 wild must resolve either way.
        XCTAssertTrue(session.isOver)
        XCTAssertNotNil(session.outcome)
        XCTAssertTrue(events.contains { if case .battleEnded = $0 { return true }; return false })

        if session.outcome == .victory {
            XCTAssertGreaterThan(session.party[0].xp, baseline)
            let leveledUp = events.contains { if case .leveledUp = $0 { return true }; return false }
            if leveledUp {
                XCTAssertGreaterThan(session.party[0].level, 5)
            }
        }
    }

    // MARK: - Trainer battle (rival)

    func testRivalTrainerBattleBlocksFleeAndSendsReserves() {
        let bestiary = Bestiary(profiles: SampleData.agents)
        let trainer = Rival.trainer(stage: 2, bestiary: bestiary, playerMaxLevel: 12)
        XCTAssertEqual(trainer.party.count, 2)

        let player = makeDaemon("tr-p", role: "coder", level: 35, ability: .failsafe)
        let session = BattleSession(kind: .trainer(trainer), party: [player], seed: "rival-duel")
        var events = session.start()

        // Fleeing a Conductor duel is refused with a message, never a fleeAttempt.
        let fleeEvents = session.submit(.flee)
        XCTAssertTrue(fleeEvents.contains { if case .message = $0 { return true }; return false })
        XCTAssertFalse(fleeEvents.contains { if case .fleeAttempt = $0 { return true }; return false })
        XCTAssertNil(session.outcome)
        events += fleeEvents

        for _ in 0..<120 where !session.isOver {
            events += session.submit(.move(damagingMove(for: session)))
        }
        XCTAssertTrue(session.isOver)

        // Enemy-side daemonSent only happens when the trainer sends a reserve
        // after a faint (start() announces only the player's daemon), so a
        // victory over a 2-daemon party implies at least one such event.
        let enemySends = events.filter {
            if case .daemonSent(let side, _, _) = $0, side == .enemy { return true }
            return false
        }.count
        XCTAssertTrue(enemySends >= 1 || session.outcome == .defeat)
        if session.outcome == .victory {
            XCTAssertGreaterThanOrEqual(enemySends, 1)
            XCTAssertTrue(events.contains(.battleEnded(outcome: .victory)))
        }
    }

    // MARK: - Switching

    func testSwitchChangesActiveDaemonAndAnnouncesIt() {
        let first = makeDaemon("sw-a", role: "coder", level: 20)
        let second = makeDaemon("sw-b", role: "researcher", level: 20)
        let wild = makeDaemon("sw-w", tier: .sub, role: "general", level: 3)
        let session = BattleSession(kind: .wild(wild), party: [first, second], seed: "switcheroo")
        _ = session.start()
        XCTAssertEqual(session.activeIndex, 0)

        let events = session.submit(.switchTo(1))
        XCTAssertEqual(session.activeIndex, 1)
        XCTAssertTrue(events.contains {
            if case .daemonSent(let side, _, _) = $0, side == .player { return true }
            return false
        })
    }

    // MARK: - Items

    func testHotfixHealsActiveDaemonMidBattle() {
        // Pre-damaged tanky player vs a feeble wild, so the heal dwarfs any
        // counterattack and the enemy cannot be one-shot before the item turn.
        var player = makeDaemon("item-p", role: "review", level: 40)
        XCTAssertGreaterThan(player.maxHP, 80)
        player.currentHP = player.maxHP - 70

        let wild = makeDaemon("item-w", tier: .sub, role: "general", level: 3)
        let session = BattleSession(kind: .wild(wild), party: [player], seed: "hotfix-time")
        _ = session.start()

        // One round first (harmless self-buff) so the enemy gets a turn in.
        let bulwark = MovePool.moves(for: .warden).first { $0.effect == .raiseDef }!
        _ = session.submit(.move(bulwark))
        XCTAssertFalse(session.isOver)

        let hpBefore = session.activeDaemon.currentHP
        let events = session.submit(.useItem(Item.hotfix))
        XCTAssertTrue(events.contains { if case .itemUsed = $0 { return true }; return false })
        XCTAssertGreaterThanOrEqual(session.activeDaemon.currentHP, hpBefore)
    }

    // MARK: - Player-side status move

    func testPlayerStatusMoveStallsEnemyOrMisses() {
        var player = makeDaemon("stall-p", role: "review", level: 30)
        let lockdown = MovePool.moves(for: .warden).first { $0.effect == .stall }!
        player.moves = [lockdown]

        let wild = makeDaemon("stall-w", tier: .sub, role: "general", level: 5)
        let session = BattleSession(kind: .wild(wild), party: [player], seed: "lockdown")
        _ = session.start()

        let events = session.submit(.move(lockdown))
        let stalled = events.contains {
            if case .statusApplied(let side, let status) = $0,
               side == .enemy, status == .stalled { return true }
            return false
        }
        let missed = events.contains {
            if case .missed(let side, _) = $0, side == .player { return true }
            return false
        }
        XCTAssertTrue(stalled || missed, "lockdown must either stall the enemy or miss")
    }

    // MARK: - Sphere throws vs trainers

    func testThrowingSphereAtTrainerIsBlocked() {
        let bestiary = Bestiary(profiles: SampleData.agents)
        let trainer = Rival.trainer(stage: 1, bestiary: bestiary, playerMaxLevel: 5)
        let player = makeDaemon("throw-p", role: "coder", level: 40)
        let session = BattleSession(kind: .trainer(trainer), party: [player], seed: "no-throws")
        _ = session.start()

        let events = session.submit(.throwSphere(.orb, quality: 1.0))
        XCTAssertTrue(events.contains { if case .message = $0 { return true }; return false })
        XCTAssertFalse(events.contains { if case .sphereThrown = $0 { return true }; return false })
        XCTAssertNil(session.outcome)
    }
}
